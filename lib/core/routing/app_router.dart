import 'package:go_router/go_router.dart';
import '../../features/dev/foundation_screen.dart';
import '../../features/splash/splash_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String foundation = '/foundation';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: foundation,
        builder: (context, state) => const FoundationScreen(),
      ),
    ],
  );
}
