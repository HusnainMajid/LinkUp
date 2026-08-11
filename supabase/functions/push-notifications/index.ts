import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { GoogleAuth } from "https://esm.sh/google-auth-library@8.7.0"

serve(async (req) => {
  const { record, table, type } = await req.json()

  // 1. Initialize Supabase Client with Service Role Key (to bypass RLS)
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  let title = "LinkUp"
  let body = ""
  let targetUserId = ""
  let data = {}

  // Logic for New Messages
  if (table === 'messages' && type === 'INSERT') {
    const senderId = record.sender_id
    const conversationId = record.conversation_id

    // Fetch sender's name
    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', senderId)
      .single()

    // Fetch the recipient (the other member in the 1-to-1 chat)
    const { data: members } = await supabase
      .from('conversation_members')
      .select('user_id')
      .eq('conversation_id', conversationId)
      .neq('user_id', senderId)

    title = profile?.full_name ?? "New Message"
    body = record.message_type === 'text' ? record.content : "📷 Photo"
    targetUserId = members?.[0]?.user_id

    data = {
      type: 'message',
      conversation_id: conversationId,
      sender_id: senderId
    }
  }
  // Logic for Friend Requests
  else if (table === 'friend_requests' && type === 'INSERT') {
    const senderId = record.sender_id
    targetUserId = record.receiver_id

    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', senderId)
      .single()

    title = "New Friend Request"
    body = `${profile?.full_name ?? 'Someone'} sent you a friend request.`
    data = {
      type: 'friend_request',
      sender_id: senderId
    }
  }

  if (targetUserId) {
    // 2. Fetch all registered FCM tokens for the target user
    const { data: devices } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', targetUserId)

    if (devices && devices.length > 0) {
      const tokens = devices.map(d => d.fcm_token)

      // 3. Authenticate with Firebase using Service Account
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

      // 4. Send notification to every device token
      for (const token of tokens) {
        try {
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
                },
                apns: {
                  payload: {
                    aps: {
                      alert: { title, body },
                      sound: "default",
                      badge: 1
                    }
                  }
                }
              }
            })
          })
        } catch (err) {
          console.error(`Failed to send to token ${token}:`, err)
        }
      }
    }
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" }
  })
})
