# Advanced 1-to-1 Messaging Implementation Plan

Upgrade the existing 1-to-1 messaging system with modern features like presence, typing indicators, read receipts, reactions, replies, and more.

## User Review Required

> [!IMPORTANT]
> - **Database Migration**: `007_advanced_messaging.sql` will be added to the project.
> - **Real-time**: Extensive use of Supabase Realtime for presence, typing, and message updates.
> - **Image Messaging**: Re-uses `image_picker` (Camera/Gallery) but strictly avoids `file_picker`.
> - **Soft Delete**: Deleting messages will use the existing soft-delete logic (`deleted_at` field).

## Proposed Changes

### Database & Supabase

#### [NEW] [007_advanced_messaging.sql](file:///C:/Users/Husnain/Desktop/LinkUp/supabase/migrations/007_advanced_messaging.sql)
- Add `edited_at`, `delivered_at`, `read_at` to `messages`.
- Add `last_seen`, `is_online` to `profiles`.
- Create `message_reactions` table.
- Implement `mark_messages_as_read` RPC.
- Define RLS policies for reactions.

---

### Models & Data Layer

#### [MODIFY] [message_model.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/data/models/message_model.dart)
- Update with advanced fields (`editedAt`, `deliveredAt`, `readAt`, `reactions`, `repliedMessage`).

#### [MODIFY] [profile_model.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/auth/models/profile_model.dart)
- Add `isOnline` and `lastSeen`.

#### [NEW] [message_reaction_model.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/data/models/message_reaction_model.dart)
- Define `MessageReaction` model.

#### [MODIFY] [chat_repository.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/data/repositories/chat_repository.dart)
- Implement presence tracking, typing indicators (Realtime Broadcast), read receipts, reactions, editing, and soft-deletion.

---

### UI - Screens & Widgets

#### [MODIFY] [chat_screen.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/presentation/screens/chat_screen.dart)
- **Header**: Add Online/Last Seen status and Typing indicator.
- **Message List**: Show delivery/read status (ticks).
- **Composer**: Implement Reply preview and Search integration.
- **Interactions**: Long-press menu for reactions, replies, editing, and deleting.
- **Image Picking**: Integrated Camera and Gallery options via `image_picker`.

#### [NEW] [message_bubble.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/presentation/widgets/message_bubble.dart) (Extracted from ChatScreen)
- Refactor bubble logic to handle reactions, replies, and status icons cleanly.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no regression or missing dependencies.

### Manual Verification
1. **Presence**: Open app on two devices. Verify "Online" status appears. Close one app and verify "Last seen" updates.
2. **Typing**: Start typing on Device A. Verify "typing..." appears on Device B.
3. **Receipts**: Send message. Verify single tick (sent). Verify double tick (delivered/read).
4. **Replies**: Long-press message, select Reply. Send and verify the quoted message appears.
5. **Reactions**: Add ❤️ to a message. Verify it appears in real-time.
6. **Editing/Deletion**: Edit own message. Verify "Edited" appears. Delete for everyone. Verify "This message was deleted" appears.
7. **Image Messaging**: Take a photo and send it. Pick from gallery and send it.
8. **Search**: Search for a specific word in the three-dot menu. Verify results are found and navigable.
