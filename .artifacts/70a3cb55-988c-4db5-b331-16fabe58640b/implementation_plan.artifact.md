# Push Notification System Implementation Plan

Implement a production-ready push notification system using Firebase Cloud Messaging (FCM) and Supabase Edge Functions for secure delivery.

## User Review Required

> [!IMPORTANT]
> - **Firebase Configuration**: You will need to add your own `google-services.json` to the `android/app/` directory and configure the Firebase project in the Firebase Console.
> - **Edge Functions**: I will provide the code for a Supabase Edge Function (`push-notifications`) which you must deploy using the Supabase CLI.
> - **Service Account**: You must download a Service Account JSON from the Firebase Console and add it as a Secret to your Supabase project (`FCM_SERVICE_ACCOUNT`).

## Proposed Changes

### 1. Dependencies & Configuration

#### [MODIFY] [pubspec.yaml](file:///C:/Users/Husnain/Desktop/LinkUp/pubspec.yaml)
- Add `firebase_core: ^3.1.1`
- Add `firebase_messaging: ^15.0.3`
- Add `flutter_local_notifications: ^17.2.2` (for high-importance foreground notifications on Android)

---

### 2. Database & Supabase

#### [NEW] [008_push_notifications.sql](file:///C:/Users/Husnain/Desktop/LinkUp/supabase/migrations/008_push_notifications.sql)
- Create `user_devices` table to store FCM tokens per user/platform.
- Add RLS policies for token management.
- Create a trigger on `messages` and `friend_requests` to call the Edge Function.

#### [NEW] [Edge Function: push-notifications]
- Deno-based function to listen to database webhooks.
- Authenticate with Firebase HTTP v1 API using service account secrets.
- Send targeted notifications to specific `fcm_token` values found in `user_devices`.

---

### 3. Core Notification Logic

#### [NEW] [notification_service.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/core/notifications/notification_service.dart)
- Initialize Firebase and FCM.
- Handle token refresh and persistence to Supabase.
- Configure Android channels.
- Handle background/foreground message reception.

#### [NEW] [notification_router.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/core/notifications/notification_router.dart)
- Centralized logic to map notification payloads (type, id) to GoRouter navigation.

---

### 4. Integration

#### [MODIFY] [main.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/main.dart)
- Initialize Firebase and NotificationService.

#### [MODIFY] [auth_service.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/auth/services/auth_service.dart)
- Register device token upon successful sign-in.
- Remove device token upon sign-out.

#### [MODIFY] [app_router.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/core/routing/app_router.dart)
- Integrate with NotificationRouter to handle deep-linking from notifications.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax errors or missing imports.

### Manual Verification
1. **Token Management**: Verify `user_devices` table populates with the correct token when a user logs in.
2. **Foreground Message**: Send a message while User B is in the app but on the Home screen. Verify a local notification appears.
3. **Background Message**: Move app to background. Send message. Verify push notification appears with sender name and preview.
4. **Terminated State**: Force stop app. Send message. Verify notification appears and tapping it opens the correct chat.
5. **Friend Request**: Send a friend request. Verify notification "X sent you a friend request."
6. **No Duplicates**: Verify no notification appears when User B is already inside the conversation with User A.
7. **Unread Counts**: Verify the unread badge on the Chat List screen increments/decrements correctly.
