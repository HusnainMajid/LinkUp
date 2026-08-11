# Friend Request and Friendship System Implementation Plan

Implement a comprehensive friendship system to control communication between users, ensuring only accepted friends can start or continue conversations.

## User Review Required

> [!IMPORTANT]
> - **Database Migration**: The migration will be named `006_friend_requests.sql` to avoid conflict with existing `004` and `005` migrations, despite the prompt's initial suggestion.
> - **Real-time**: Friend requests will use Supabase Realtime for instant updates on the Friend Requests screen.
> - **Retroactive Enforcement**: Existing conversations between users who are not friends will be blocked both at the route level and via updated database functions.

## Proposed Changes

### Database & Supabase

#### [NEW] [006_friend_requests.sql](file:///C:/Users/Husnain/Desktop/LinkUp/supabase/migrations/006_friend_requests.sql)
- Create `friend_requests` table with `sender_id`, `receiver_id`, `status` (`pending`, `accepted`, `rejected`, `cancelled`).
- Add directional uniqueness constraint and self-request check.
- Enable RLS and define policies for sending, viewing, and updating requests.
- Create `is_friends(user_a, user_b)` RPC.
- Create `get_friend_status(other_user_id)` RPC.
- **Redefine** `get_or_create_direct_conversation` to throw an error if users are not friends.

---

### Models & Data Layer

#### [NEW] [friend_request_model.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/data/models/friend_request_model.dart)
- Define `FriendRequest` model and `FriendStatus` enum.

#### [NEW] [friend_repository.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/data/repositories/friend_repository.dart)
- Implement `sendFriendRequest`, `respondToFriendRequest`, `cancelFriendRequest`, `getFriends`, `getFriendRequests`, `getFriendStatus`.
- Handle Realtime subscriptions for friend requests.

#### [MODIFY] [chat_repository.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/data/repositories/chat_repository.dart)
- Add `checkFriendship(conversationId)` to verify if participants in a conversation are friends.

---

### UI - Screens & Navigation

#### [NEW] [friend_requests_screen.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/presentation/screens/friend_requests_screen.dart)
- List incoming and outgoing requests with Accept/Decline/Cancel actions.
- Premium dark theme consistent with LinkUp.

#### [NEW] [friends_screen.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/presentation/screens/friends_screen.dart)
- List all accepted friends with a "Message" button.

#### [MODIFY] [home_screen.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/home/presentation/screens/home_screen.dart)
- Add friend request count badge to the header or hub section.
- Add "Friends" and "Requests" to Quick Actions.

#### [MODIFY] [user_profile_preview_screen.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/presentation/screens/user_profile_preview_screen.dart)
- Fetch and display friendship status.
- Show contextual buttons: "Add Friend", "Request Sent" (Cancel), "Accept / Decline", "Friends" (Message).
- Disable "Message" button if not friends.

#### [MODIFY] [new_chat_screen.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/presentation/screens/new_chat_screen.dart)
- Update search results to show friendship status.
- Only allow "Message" for friends; show "Add Friend" or "Pending" otherwise.

#### [MODIFY] [chat_screen.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/features/chat/presentation/screens/chat_screen.dart)
- Add a safety check in `initState` to verify friendship.
- Show "You're no longer friends with this user" if friendship is lost.

#### [MODIFY] [app_router.dart](file:///C:/Users/Husnain/Desktop/LinkUp/lib/core/routing/app_router.dart)
- Add routes for `/friends` and `/friend-requests`.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no regression or missing dependencies.

### Manual Verification
1. **User A & B Setup**: Create two accounts.
2. **Search & Request**: A searches B, sends friend request. B receives real-time notification/badge.
3. **Acceptance**: B accepts request. A's UI updates to "Friends".
4. **Communication**: A starts chat with B. Message is sent and received.
5. **Restriction**:
    - A attempts to chat with a non-friend User C (should fail/block).
    - Manually trigger `get_or_create_direct_conversation` via Supabase SQL for non-friends (should error).
    - Unfriend/Block scenario: Verify existing chat becomes inaccessible.
