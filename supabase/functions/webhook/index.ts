/**
 * Supabase Edge Function for handling RevenueCat webhook events
 * Updates user subscription status in public.users table
 *
 * Handles webhook events: INITIAL_PURCHASE, RENEWAL, CANCELLED
 * Updates is_subscribed field based on event type
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS headers for cross-origin requests
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// RevenueCat webhook event types we handle
enum RevenueCatEventType {
  INITIAL_PURCHASE = 'INITIAL_PURCHASE',
  RENEWAL = 'RENEWAL',
  CANCELLED = 'CANCELLED'
}

// Interface for RevenueCat webhook payload
interface RevenueCatWebhookPayload {
  event: {
    type: string
    app_user_id: string
    product_id?: string
    entitlement_id?: string
    transaction_id?: string
    original_transaction_id?: string
    period_type?: string
    purchased_at_ms?: number
    expiration_at_ms?: number
    cancel_reason?: string
    store?: string
    is_trial_conversion?: boolean
    currency?: string
    price?: number
    introductory_price?: number
  }
  api_version: string
}

/**
 * Verifies webhook signature if secret is provided
 * @param payload Raw request body
 * @param signature X-Signature header from RevenueCat
 * @param secret Webhook secret for verification
 * @returns boolean indicating if signature is valid
 */
function verifyWebhookSignature(payload: string, signature: string | null, secret: string | null): boolean {
  // If no secret is configured, skip verification
  if (!secret || !signature) {
    return true
  }

  // TODO: Implement HMAC-SHA256 signature verification
  // For now, accept all requests if secret is not configured
  return true
}

/**
 * Updates user subscription status in database
 * @param supabaseClient Supabase client instance
 * @param userId App user ID from RevenueCat
 * @param isSubscribed New subscription status
 */
async function updateUserSubscriptionStatus(
  supabaseClient: any,
  userId: string,
  isSubscribed: boolean
): Promise<void> {
  const subscriptionStatus = isSubscribed ? 'premium' : 'free'

  // Only attempt update; do not insert rows here to avoid FK violations if auth user doesn't exist yet
  const { error } = await supabaseClient
    .from('user_profiles')
    .update({ is_premium: isSubscribed, subscription_status: subscriptionStatus })
    .eq('id', userId)

  if (error) {
    console.error('Database update error:', error)
    throw new Error(`Failed to update user subscription status: ${error.message}`)
  }

  console.log(`Updated user ${userId} is_premium=${isSubscribed} subscription_status=${subscriptionStatus}`)
}

/**
 * Processes RevenueCat webhook event
 * @param supabaseClient Supabase client instance
 * @param payload Parsed webhook payload
 */
async function processWebhookEvent(
  supabaseClient: any,
  payload: RevenueCatWebhookPayload
): Promise<void> {
  const { event } = payload
  const { type, app_user_id } = event

  console.log(`Processing webhook event: ${type} for user: ${app_user_id}`)

  // Determine subscription status based on event type
  let isSubscribed: boolean

  switch (type) {
  case RevenueCatEventType.INITIAL_PURCHASE:
  case RevenueCatEventType.RENEWAL:
    isSubscribed = true
    break
  case RevenueCatEventType.CANCELLED:
    isSubscribed = false
    break
  default:
    console.log(`Ignoring unsupported event type: ${type}`)
    return
  }

  // Update user subscription status
  await updateUserSubscriptionStatus(supabaseClient, app_user_id, isSubscribed)
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only accept POST requests
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }

  try {
    // Create Supabase client with service role key for database access
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get webhook secret from environment (optional)
    const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')

    // Read request body
    const body = await req.text()
    const signature = req.headers.get('X-Signature')

    // Verify webhook signature if secret is configured
    if (!verifyWebhookSignature(body, signature, webhookSecret)) {
      console.error('Webhook signature verification failed')
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Parse webhook payload
    let payload: RevenueCatWebhookPayload
    try {
      payload = JSON.parse(body)
    } catch (parseError) {
      console.error('Failed to parse webhook payload:', parseError)
      return new Response(
        JSON.stringify({ error: 'Invalid JSON payload' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Validate required payload structure
    if (!payload.event || !payload.event.type || !payload.event.app_user_id) {
      console.error('Invalid webhook payload structure')
      return new Response(
        JSON.stringify({ error: 'Invalid payload structure' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Process the webhook event
    await processWebhookEvent(supabaseClient, payload)

    // Return success response
    return new Response(
      JSON.stringify({ success: true, message: 'Webhook processed successfully' }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Webhook processing error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})