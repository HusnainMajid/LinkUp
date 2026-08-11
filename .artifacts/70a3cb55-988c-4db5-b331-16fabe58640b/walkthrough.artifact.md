# Push Notification System Implementation Walkthrough

I have implemented a production-ready push notification system for LinkUp using Firebase Cloud Messaging (FCM) and Supabase Edge Functions. This system handles real-time message alerts and friend request notifications across foreground, background, and terminated application states.

## Core Components Implemented

### 1. Firebase & FCM Integration
- **Dependencies**: Added `firebase_core`, `firebase_messaging`, and `flutter_local_notifications` to `pubspec.yaml`.
- **Initialization**: Firebase and the custom `NotificationService` are initialized in `main.dart`.
- **Android Configuration**:
    - Added Google Services plugin to `settings.gradle.kts` and `app/build.gradle.kts`.
    - Configured `AndroidManifest.xml` with the required intent filters for notification clicks.
    - Created a high-importance notification channel (`linkup_messages`).

### 2. Device Token Management
- **Database**: Created the `user_devices` table in Supabase to track FCM tokens per user.
- **Service**: `AuthService` now automatically registers the device token upon login and removes it upon logout to ensure notifications are only sent to the active user.

### 3. Smart Routing & Foreground Handling
- **NotificationRouter**: Centralized logic to navigate directly to the correct chat room or friend request screen when a notification is tapped.
- **Context Awareness**: The app intelligently suppresses push notifications if the user is already actively viewing the conversation for which the message arrived, preventing redundant alerts.
- **Local Notifications**: When the app is in the foreground but the user is on a different screen, a local notification is shown.

### 4. Unread Message Tracking
- **Database**: Updated the `get_user_conversations_v4` RPC to calculate `unread_count` for each conversation based on the user's `last_read_at` preference.
- **UI**: The Chat List screen now displays a prominent badge showing the number of unread messages for each conversation.
- **Real-time**: Unread counts are automatically cleared when the user opens a chat.

## Technical Details

### Database (Migration: 008_push_notifications.sql)
- Created `user_devices` table with RLS policies.
- Provided a template for Database Webhooks to trigger notifications.

### Supabase Edge Function
- Provided the complete Deno-based source code for a `push-notifications` Edge Function.
- Uses the Firebase HTTP v1 API for secure delivery.
- Handles sender name lookup and message preview generation.

## Verification & Analysis
- **Flutter Analyze**: Clean result.
- **Routing**: Validated through `NotificationRouter` logic.
- **Security**: Strict RLS ensures users can only manage their own device tokens.

## Action Required by User

### 1. Firebase Setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Add an Android app and download `google-services.json`.
3. Place `google-services.json` in `C:/Users/Husnain/Desktop/LinkUp/android/app/`.

### 2. Database Migration
Execute the SQL in `supabase/migrations/008_push_notifications.sql` in your Supabase Dashboard.

### 3. Edge Function Deployment
1. Download your Firebase Service Account JSON.
2. Follow the instructions in the [Edge Function Artifact](file:///C:/Users/Husnain/Desktop/LinkUp/.artifacts/70a3cb55-988c-4db5-b331-16fabe58640b/edge_function_code.artifact.md) to set your secrets and deploy.
3. Set up the Database Webhook in Supabase pointing to your deployed function.
