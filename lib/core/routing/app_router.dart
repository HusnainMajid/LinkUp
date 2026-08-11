import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/hub/presentation/screens/hub_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
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
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String foundation = '/foundation';

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

      // If logged in but on an auth screen, go to home
      if (loggingIn) {
        return home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      
      // Standalone authenticated routes
      GoRoute(
        path: newChat,
        builder: (context, state) => const NewChatScreen(),
      ),
      GoRoute(
        path: userProfile,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfilePreviewScreen(userId: userId);
        },
      ),
      GoRoute(
        path: archivedChats,
        builder: (context, state) => const ArchivedChatsScreen(),
      ),
      GoRoute(
        path: friends,
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: friendRequests,
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      GoRoute(
        path: chatRoom,
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),

      // Authenticated Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: chats,
                builder: (context, state) => const ChatsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: groups,
                builder: (context, state) => const GroupsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: hub,
                builder: (context, state) => const HubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: foundation,
        builder: (context, state) => const FoundationScreen(),
      ),
    ],
  );
}
