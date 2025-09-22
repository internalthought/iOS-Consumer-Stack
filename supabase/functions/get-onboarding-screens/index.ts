import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create a Supabase client with the service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get the userProperty from query parameters
    const url = new URL(req.url)
    const userProperty = url.searchParams.get('userProperty')

    if (!userProperty) {
      return new Response(
        JSON.stringify({ error: 'userProperty parameter is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Fetch onboarding screens from the database
    const { data: screens, error } = await supabaseClient
      .from('user_segment')
      .select('id, title, description, image_url, button_text, next_id')
      .eq('user_property', userProperty)
      .order('id', { ascending: true })

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch onboarding screens' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Transform the data to match the expected format
    const transformedScreens = screens.map(screen => ({
      id: screen.id,
      title: screen.title,
      description: screen.description,
      image_url: screen.image_url,
      button_text: screen.button_text,
      next_id: screen.next_id
    }))

    return new Response(
      JSON.stringify(transformedScreens),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})