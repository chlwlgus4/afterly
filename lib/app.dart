import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/camera/camera_screen.dart';
import 'screens/comparison/comparison_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'providers/auth_provider.dart';
import 'utils/constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isSplashRoute = state.matchedLocation == '/splash';

      // Allow splash screen to show first
      if (isSplashRoute) return null;

      // Redirect to login if not logged in and not already on login/signup
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // Redirect to home if logged in and on login/signup
      if (isLoggedIn && isLoginRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/camera/:customerId/:sessionId/:type',
        builder: (context, state) {
          final customerId = state.pathParameters['customerId']!;
          final sessionId = state.pathParameters['sessionId']!;
          final type = state.pathParameters['type']!; // 'before' or 'after'
          return CameraScreen(
            key: ValueKey('camera_${type}_$sessionId'),
            customerId: customerId,
            sessionId: sessionId,
            shootingType: type,
          );
        },
      ),
      GoRoute(
        path: '/comparison/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return ComparisonScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/analysis/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return AnalysisScreen(sessionId: sessionId);
        },
      ),
    ],
  );
});

class AfterlyApp extends ConsumerWidget {
  const AfterlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Afterly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          onPrimary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          foregroundColor: AppColors.textPrimary,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        dividerColor: AppColors.surfaceLight,
      ),
      routerConfig: router,
    );
  }
}
