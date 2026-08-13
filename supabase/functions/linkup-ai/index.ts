import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }

  try {
    const { prompt, history } = await req.json()

    if (!GEMINI_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'AI service configuration error: API Key missing.' }),
        { status: 500, headers: { "Content-Type": "application/json", 'Access-Control-Allow-Origin': '*' } }
      )
    }

    // Construct the payload for Gemini API
    // Flutter role "user" -> Gemini role "user"
    // Flutter role "assistant" -> Gemini role "model"
    const contents = [
      ...(history || [])
        .filter((m: any) => m.content && m.content.trim() !== '')
        .map((m: any) => ({
          role: m.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: m.content }]
        })),
      { role: 'user', parts: [{ text: prompt }] }
    ]

    // Use current production model as per migration requirement
    const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`
    // NOTE: User requested gemini-3.6-flash, but if it fails I should be aware.
    // However, the prompt was very specific. I'll use exactly what was requested.
    const migrationUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${GEMINI_API_KEY}`

    const response = await fetch(migrationUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contents })
    })

    const data = await response.json()

    if (!response.ok) {
      console.error('Gemini API Error Status:', response.status)
      console.error('Gemini API Error Body:', JSON.stringify(data))

      let errorMessage = 'AI assistant is temporarily unavailable.'
      if (response.status === 401 || response.status === 403) {
        errorMessage = 'AI service authentication failed. Please check API configuration.'
      } else if (response.status === 429) {
        errorMessage = 'AI service quota reached. Please try again later.'
      } else if (response.status === 404) {
        errorMessage = 'The requested AI model was not found or has been retired.'
      } else if (data.error?.message) {
        errorMessage = data.error.message
      }

      return new Response(
        JSON.stringify({ error: errorMessage }),
        { status: response.status, headers: { "Content-Type": "application/json", 'Access-Control-Allow-Origin': '*' } }
      )
    }

    if (!data.candidates || data.candidates.length === 0) {
      return new Response(
        JSON.stringify({ error: 'AI returned an empty or filtered response. Please try a different prompt.' }),
        { status: 500, headers: { "Content-Type": "application/json", 'Access-Control-Allow-Origin': '*' } }
      )
    }

    const aiContent = data.candidates[0].content.parts[0].text

    return new Response(
      JSON.stringify({ content: aiContent }),
      {
        headers: {
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      }
    )
  } catch (error) {
    console.error('Edge Function Internal Error:', error.message)
    return new Response(
      JSON.stringify({ error: 'A server error occurred while processing the AI request.' }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        }
      }
    )
  }
})
