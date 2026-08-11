# Supabase Edge Function: push-notifications

Create a new Edge Function:
`supabase functions new push-notifications`

Then replace the content of `index.ts` with the following code:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { GoogleAuth } from "https://esm.sh/google-auth-library@8.7.0"

serve(async (req) => {
  const { record, table, type } = await req.json()

  // 1. Initialize Supabase
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  let title = "LinkUp"
  let body = ""
  let targetUserId = ""
  let data = {}

  if (table === 'messages' && type === 'INSERT') {
    const senderId = record.sender_id
    const conversationId = record.conversation_id

    // Get sender name
    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', senderId)
      .single()

    // Get recipient(s)
    const { data: members } = await supabase
      .from('conversation_members')
      .select('user_id')
      .eq('conversation_id', conversationId)
      .neq('user_id', senderId)

    title = profile?.full_name ?? "New Message"
    body = record.message_type === 'text' ? record.content : "📷 Photo"
    targetUserId = members?.[0]?.user_id // Simple 1-to-1 logic
    data = {
      type: 'message',
      conversation_id: conversationId,
      sender_id: senderId
    }
  } else if (table === 'friend_requests' && type === 'INSERT') {
    // Similar logic for friend requests
  }

  if (targetUserId) {
    // 2. Fetch device tokens
    const { data: devices } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', targetUserId)

    if (devices && devices.length > 0) {
      const tokens = devices.map(d => d.fcm_token)

      // 3. Send via Firebase HTTP v1
      // You need to set FCM_SERVICE_ACCOUNT secret in Supabase
      const serviceAccount = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT') ?? '{}')
      const auth = new GoogleAuth({
        credentials: {
          client_email: serviceAccount.client_email,
          private_key: serviceAccount.private_key,
        },
        scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
      })
      const client = await auth.getClient()
      const accessToken = await client.getAccessToken()

      for (const token of tokens) {
        await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken.token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: token,
              notification: { title, body },
              data: data,
              android: {
                priority: "high",
                notification: {
                  channel_id: "linkup_messages",
                  click_action: "FLUTTER_NOTIFICATION_CLICK"
                }
              }
            }
          })
        })
      }
    }
  }

  return new Response(JSON.stringify({ success: true }), { headers: { "Content-Type": "application/json" } })
})
```

## How to Deploy

1. Set your Firebase Service Account as a secret:
`supabase secrets set FCM_SERVICE_ACCOUNT='{"project_id": "...", "private_key": "...", ...}'`

2. Deploy the function:
`supabase functions deploy push-notifications`

3. Create the Database Webhook in Supabase Dashboard (Database -> Webhooks).
```