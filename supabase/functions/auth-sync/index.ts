import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST' && req.method !== 'GET') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

    if (!supabaseUrl || !supabaseAnonKey) {
      console.error('auth-sync: missing Supabase env')
      return new Response(JSON.stringify({ error: 'Supabase env not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.error('auth-sync: missing Authorization header')
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    const {
      data: { user },
      error: userError
    } = await supabase.auth.getUser()

    if (userError || !user) {
      console.error('auth-sync: getUser error', userError)
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const userId = user.id
    const userEmail = user.email ?? null
    console.log('auth-sync: user', { id: userId, email: userEmail })

    const { error: upsertError } = await supabase
      .from('user_profiles')
      .upsert({ id: userId, email: userEmail }, { onConflict: 'id' })

    if (upsertError) {
      console.error('auth-sync: user_profiles upsert error', upsertError)
      return new Response(JSON.stringify({ error: 'Failed to upsert user profile' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    let is_premium: boolean | undefined
    let subscription_status: string | undefined

    if (req.method === 'POST') {
      try {
        const body = await req.json()
        is_premium = typeof body?.is_premium === 'boolean' ? body.is_premium : undefined
        subscription_status = typeof body?.subscription_status === 'string' ? body.subscription_status : undefined
        console.log('auth-sync: received payload', { is_premium, subscription_status })
      } catch (_e) {
        console.warn('auth-sync: invalid json body')
      }
    }

    if (typeof is_premium !== 'undefined' || typeof subscription_status !== 'undefined') {
      const updatePayload: Record<string, unknown> = {}
      if (typeof is_premium !== 'undefined') updatePayload.is_premium = is_premium
      if (typeof subscription_status !== 'undefined') updatePayload.subscription_status = subscription_status

      const { error: updateError } = await supabase
        .from('user_profiles')
        .update(updatePayload)
        .eq('id', userId)

      if (updateError) {
        console.error('auth-sync: user_profiles update error', updateError)
        return new Response(JSON.stringify({ error: 'Failed to update premium status' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      } else {
        console.log('auth-sync: updated profile', { id: userId, ...updatePayload })
      }
    } else {
      console.log('auth-sync: no premium/status provided; returning current profile')
    }

    const { data: profiles, error: selectError } = await supabase
      .from('user_profiles')
      .select('id, email, is_premium, subscription_status')
      .eq('id', userId)
      .limit(1)

    if (selectError) {
      console.error('auth-sync: user_profiles select error', selectError)
      return new Response(JSON.stringify({ error: 'Failed to fetch profile' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    console.log('auth-sync: returning profile', profiles?.[0])
    return new Response(JSON.stringify({ user: profiles?.[0] ?? null }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (e) {
    console.error('auth-sync unexpected error', e)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})