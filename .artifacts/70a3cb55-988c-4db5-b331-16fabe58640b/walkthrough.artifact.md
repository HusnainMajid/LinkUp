# Friend Request and Friendship System Implementation Walkthrough

I have implemented a complete Friend Request and Friendship validation system for LinkUp. This system ensures that users can only communicate if they have an accepted friendship status, while maintaining the discoverability of all users.

## Changes Made

### Database & Supabase
- **Migration Created**: `006_friend_requests.sql`
    - Created `friend_requests` table with statuses: `pending`, `accepted`, `rejected`, `cancelled`.
    - Implemented RLS policies to protect requests.
    - Added `is_friends(user_a, user_b)` and `get_friend_status(other_user_id)` RPCs.
    - **Enforced Friendship**: Modified `get_or_create_direct_conversation` to throw an exception if users are not friends.
    - **Message Security**: Updated message insertion RLS policy to verify friendship at the database level.

### Models & Repositories
- **Models**: Created `friend_request_model.dart` with `FriendStatus` enum.
- **FriendRepository**: Implemented logic for sending, responding to, and cancelling requests, as well as fetching friends and requests.
- **ChatRepository**: Added `isStillFriends` check for route protection and updated `getOrCreateDirectConversation` to handle friendship errors.

### UI Implementation
- **FriendRequestsScreen**: A new screen to manage incoming and outgoing requests with real-time updates.
- **FriendsScreen**: A dedicated list of all accepted friends with quick message actions.
- **UserProfilePreviewScreen**: Updated to show contextual actions (Add Friend, Request Sent, Accept/Decline, Message) based on friendship status.
- **HomeScreen**: Added Quick Actions for "Friends" and "Requests" with a notification badge for pending requests.
- **NewChatScreen**: Updated search to show friendship status and only allow messaging if friends.
- **ChatScreen**: Added a "locked" state that appears if the two users are no longer friends.

## Verification & Analysis
- **Flutter Analyze**: Clean result (ignoring unrelated deprecated `anonKey` in `main.dart`).
- **Logic Validation**:
    - Unauthorized messaging is blocked by both UI and RLS.
    - Conversation creation is gated by the `is_friends` check.
    - Real-time badges for friend requests are wired up on the Home screen.

## Next Steps for User
1. Open your Supabase Dashboard.
2. Go to the **SQL Editor**.
3. Create a new query and paste the contents of `supabase/migrations/006_friend_requests.sql`.
4. Run the query to update your database schema and functions.
