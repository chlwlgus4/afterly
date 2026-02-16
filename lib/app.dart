import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/password_reset_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/camera/camera_screen.dart';
import 'screens/comparison/comparison_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/settings/faq_screen.dart';
import 'screens/settings/privacy_screen.dart';
import 'screens/settings/terms_screen.dart';
import 'screens/groups/group_management_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/group_provider.dart';
import 'utils/constants.dart';
import 'models/app_settings.dart' as models;

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/password-reset';
      final isSplashRoute = state.matchedLocation == '/splash';

      // Allow splash screen to show first
      if (isSplashRoute) return null;

      // Redirect to login if not logged in and not on auth routes
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Redirect to home if logged in and on auth routes
      if (isLoggedIn && isAuthRoute) {
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
        path: '/password-reset',
        builder: (context, state) => const PasswordResetScreen(),
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
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupManagementScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/settings/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/settings/terms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
    ],
  );
});

class AfterlyApp extends ConsumerStatefulWidget {
  const AfterlyApp({super.key});

  @override
  ConsumerState<AfterlyApp> createState() => _AfterlyAppState();
}

class _AfterlyAppState extends ConsumerState<AfterlyApp> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    final currentUser = ref.watch(currentUserProvider);

    // 사용자가 변경되었을 때 모든 데이터 초기화
    final currentUserId = currentUser?.uid;
    if (_lastUserId != currentUserId) {
      // debugPrint('🔄 사용자 변경 감지: $_lastUserId -> $currentUserId');

      // 이전 사용자가 있었고, 새 사용자가 다른 경우에만 초기화
      if (_lastUserId != null && currentUserId != _lastUserId) {
        // debugPrint('🗑️ 이전 사용자 데이터 초기화 중...');

        // 모든 데이터 provider 초기화
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(customerListProvider);
          ref.invalidate(groupListProvider);
          // debugPrint('✅ 데이터 초기화 완료');
        });
      }

      _lastUserId = currentUserId;
    }

    return MaterialApp.router(
      title: 'Afterly',
      debugShowCheckedModeBanner: false,
      themeMode: _convertThemeMode(settings.themeMode),
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
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.05),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.1),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.1),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        dividerColor: AppColors.surfaceLight,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.3),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.5),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2E2E2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        dividerColor: const Color(0xFF2E2E2E),
      ),
      routerConfig: router,
    );
  }

  ThemeMode _convertThemeMode(models.ThemeMode mode) {
    switch (mode) {
      case models.ThemeMode.light:
        return ThemeMode.light;
      case models.ThemeMode.dark:
        return ThemeMode.dark;
      case models.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}
