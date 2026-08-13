import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { GoogleAuth } from "https://esm.sh/google-auth-library@8.7.0"

serve(async (req) => {
  const { record, table, type } = await req.json()

  // 1. Initialize Supabase Client with Service Role Key
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  let title = "LinkUp"
  let body = ""
  let targetUserId = ""
  let data = {}
  let settingsKey = ""

  // Logic for New Messages
  if (table === 'messages' && type === 'INSERT') {
    const senderId = record.sender_id
    const conversationId = record.conversation_id

    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', senderId)
      .single()

    const { data: members } = await supabase
      .from('conversation_members')
      .select('user_id')
      .eq('conversation_id', conversationId)
      .neq('user_id', senderId)

    title = profile?.full_name ?? "New Message"
    body = record.message_type === 'text' ? record.content : "📷 Photo"
    targetUserId = members?.[0]?.user_id
    settingsKey = 'notify_messages'

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
    settingsKey = 'notify_messages' // Reusing message notify for now or add specific one

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
  // Logic for Voice Calls
  else if (table === 'voice_calls' && type === 'INSERT') {
    const callerId = record.caller_id
    targetUserId = record.receiver_id
    settingsKey = 'notify_calls'

    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', callerId)
      .single()

    title = "Incoming Voice Call"
    body = `${profile?.full_name ?? 'Someone'} is calling you...`
    data = {
      type: 'voice_call',
      caller_id: callerId,
      call_id: record.id
    }
  }

  if (targetUserId) {
    // 2. Check User Settings
    const { data: settings } = await supabase
      .from('user_settings')
      .select(settingsKey)
      .eq('user_id', targetUserId)
      .single()

    if (settings && settings[settingsKey] === false) {
      console.log(`User ${targetUserId} has disabled ${settingsKey}. Skipping notification.`)
      return new Response(JSON.stringify({ success: true, skipped: 'User disabled notifications' }), {
        headers: { "Content-Type": "application/json" }
      })
    }

    // 3. Fetch registered FCM tokens
    const { data: devices } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', targetUserId)

    if (devices && devices.length > 0) {
      const tokens = devices.map(d => d.fcm_token)

      // 4. Authenticate with Firebase using Service Account
      const serviceAccount = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT') ?? '{}')
      if (!serviceAccount.project_id) {
         console.error('FCM_SERVICE_ACCOUNT secret is missing or invalid.')
         return new Response(JSON.stringify({ success: false, error: 'Internal config error' }), {
           status: 500,
           headers: { "Content-Type": "application/json" }
         })
      }

      const auth = new GoogleAuth({
        credentials: {
          client_email: serviceAccount.client_email,
          private_key: serviceAccount.private_key,
        },
        scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
      })

      const authClient = await auth.getClient()
      const accessToken = await authClient.getAccessToken()

      // 5. Send notification to every device token
      for (const token of tokens) {
        try {
          const res = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
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
          if (!res.ok) {
            const errData = await res.json()
            console.error(`FCM error for token ${token}:`, errData)
          }
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
