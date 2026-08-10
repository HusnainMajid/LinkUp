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
import '../../features/home/screens/home_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String checkEmail = '/check-email';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
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
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: foundation,
        builder: (context, state) => const FoundationScreen(),
      ),
    ],
  );
}
