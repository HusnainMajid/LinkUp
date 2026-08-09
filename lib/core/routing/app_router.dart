import 'package:go_router/go_router.dart';
import '../../features/dev/foundation_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/verification_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/auth_placeholder.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verification = '/verification';
  static const String resetPassword = '/reset-password';
  static const String authPlaceholder = '/auth-placeholder';
  static const String foundation = '/foundation';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
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
        path: verification,
        builder: (context, state) {
          final type = state.extra as String?;
          return VerificationScreen(type: type);
        },
      ),
      GoRoute(
        path: resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: authPlaceholder,
        builder: (context, state) => const AuthPlaceholder(),
      ),
      GoRoute(
        path: foundation,
        builder: (context, state) => const FoundationScreen(),
      ),
    ],
  );
}
