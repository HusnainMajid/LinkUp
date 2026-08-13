import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_listenable.dart';
import '../../features/dev/foundation_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chats_list_screen.dart';
import '../../features/chat/presentation/screens/new_chat_screen.dart';
import '../../features/chat/presentation/screens/user_profile_preview_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/archived_chats_screen.dart';
import '../../features/chat/presentation/screens/friends_screen.dart';
import '../../features/chat/presentation/screens/friend_requests_screen.dart';
import '../../features/chat/presentation/screens/outgoing_call_screen.dart';
import '../../features/chat/presentation/screens/incoming_call_screen.dart';
import '../../features/chat/presentation/screens/active_call_screen.dart';
import '../../features/chat/presentation/screens/calls_list_screen.dart';
import '../../features/chat/presentation/screens/create_group_screen.dart';
import '../../features/chat/presentation/screens/group_details_screen.dart';
import '../../features/chat/presentation/screens/add_group_members_screen.dart';
import '../../features/auth/models/profile_model.dart';
import '../../features/hub/presentation/screens/hub_screen.dart';
import '../../features/hub/presentation/screens/discovery_screen.dart';
import '../../features/hub/presentation/screens/tasks_screen.dart';
import '../../features/hub/presentation/screens/ai_chat_screen.dart';

import '../../features/hub/presentation/screens/events_screen.dart';
import '../../features/hub/presentation/screens/notes_screen.dart';
import '../../features/moments/presentation/screens/create_text_moment_screen.dart';
import '../../features/moments/presentation/screens/create_image_moment_screen.dart';
import '../../features/moments/presentation/screens/moment_viewer_screen.dart';
import '../../features/moments/data/models/moment_model.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../shared/widgets/main_shell.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String checkEmail = '/check-email';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String chats = '/chats';
  static const String newChat = '/new-chat';
  static const String userProfile = '/user/:userId';
  static const String chatRoom = '/chat/:conversationId';
  static const String archivedChats = '/archived-chats';
  static const String friends = '/friends';
  static const String friendRequests = '/friend-requests';
  static const String groups = '/groups';
  static const String hub = '/hub';
  static const String discovery = '/discovery';
  static const String aiAssistant = '/ai-assistant';
  static const String tasks = '/tasks';

  static const String events = '/events';
  static const String notes = '/notes';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String foundation = '/foundation';
  static const String outgoingCall = '/outgoing-call';
  static const String incomingCall = '/incoming-call';
  static const String activeCall = '/active-call';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    refreshListenable: AuthListenable(),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      
      final bool loggingIn = state.matchedLocation == login || 
                            state.matchedLocation == register || 
                            state.matchedLocation == splash ||
                            state.matchedLocation == onboarding ||
                            state.matchedLocation == forgotPassword;

      if (session == null) {
        return loggingIn ? null : login;
      }

      if (loggingIn) {
        return home;
      }

      return null;
    },
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: resetPassword, builder: (context, state) => const ResetPasswordScreen()),
      
      GoRoute(path: newChat, builder: (context, state) => const NewChatScreen()),
      GoRoute(path: '/create-group', builder: (context, state) => const CreateGroupScreen()),
      GoRoute(
        path: '/group-details/:conversationId',
        builder: (context, state) => GroupDetailsScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      GoRoute(
        path: '/add-group-members/:groupId',
        builder: (context, state) => AddGroupMembersScreen(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: userProfile,
        builder: (context, state) => UserProfilePreviewScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(path: archivedChats, builder: (context, state) => const ArchivedChatsScreen()),
      GoRoute(path: friends, builder: (context, state) => const FriendsScreen()),
      GoRoute(path: friendRequests, builder: (context, state) => const FriendRequestsScreen()),
      GoRoute(
        path: chatRoom,
        builder: (context, state) => ChatScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      GoRoute(path: tasks, builder: (context, state) => const TasksScreen()),
      GoRoute(path: events, builder: (context, state) => const EventsScreen()),
      GoRoute(path: notes, builder: (context, state) => const NotesScreen()),
      GoRoute(path: discovery, builder: (context, state) => const DiscoveryScreen()),
      GoRoute(path: aiAssistant, builder: (context, state) => const AIChatScreen()),

      
      GoRoute(path: '/create-text-moment', builder: (context, state) => const CreateTextMomentScreen()),
      GoRoute(
        path: '/create-image-moment',
        builder: (context, state) => CreateImageMomentScreen(image: state.extra as XFile),
      ),
      GoRoute(
        path: '/moment-viewer',
        builder: (context, state) => MomentViewerScreen(moments: state.extra as List<Moment>),
      ),

      GoRoute(path: outgoingCall, builder: (context, state) => OutgoingCallScreen(receiver: state.extra as Profile)),
      GoRoute(
        path: incomingCall,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return IncomingCallScreen(callerId: extra['caller_id'] as String, callData: extra);
        },
      ),
      GoRoute(path: activeCall, builder: (context, state) => ActiveCallScreen(otherParticipant: state.extra as Profile)),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: home, builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: chats,
              builder: (context, state) => ChatsListScreen(initialFilter: state.uri.queryParameters['filter']),
            )
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/calls', builder: (context, state) => const CallsListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: hub, builder: (context, state) => const HubScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: profile,
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'edit', builder: (context, state) => const EditProfileScreen()),
                GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(path: foundation, builder: (context, state) => const FoundationScreen()),
    ],
  );
}
