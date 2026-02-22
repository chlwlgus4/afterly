import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/password_reset_screen.dart';
import 'screens/auth/mfa_setup_screen.dart';
import 'screens/auth/mfa_signin_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/camera/camera_screen.dart';
import 'screens/comparison/comparison_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/settings/faq_screen.dart';
import 'screens/settings/privacy_screen.dart';
import 'screens/settings/terms_screen.dart';
import 'screens/settings/change_password_screen.dart';
import 'screens/groups/group_management_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/group_provider.dart';
import 'utils/constants.dart';
import 'models/app_settings.dart' as models;

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final mfaEnrolled = ref.watch(mfaEnrolledProvider).valueOrNull;
  final pendingMfaResolver = ref.watch(pendingMfaResolverProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final hasMfa = mfaEnrolled ?? false;
      final hasPendingMfaSignIn = pendingMfaResolver != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/password-reset' ||
          state.matchedLocation == '/mfa-signin';
      final isSplashRoute = state.matchedLocation == '/splash';
      final isMfaSetupRoute = state.matchedLocation == '/mfa-setup';
      final isMfaSignInRoute = state.matchedLocation == '/mfa-signin';

      // Allow splash screen to show first
      if (isSplashRoute) return null;

      // 2단계 인증 로그인 세션 없이 접근한 경우 로그인으로 이동
      if (isMfaSignInRoute && !hasPendingMfaSignIn) {
        return '/login';
      }

      // Redirect to login if not logged in and not on auth routes
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // 로그인 후 2단계 인증 미설정 사용자는 설정 화면으로 강제 이동
      if (isLoggedIn && !hasMfa && !isMfaSetupRoute) {
        return '/mfa-setup';
      }

      // 2단계 인증이 필요한 사용자가 설정을 마치면 홈으로 이동
      if (isLoggedIn && hasMfa && isMfaSetupRoute) {
        return '/';
      }

      // 로그인된 사용자는 일반 인증 화면 진입 차단
      if (isLoggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/signup' ||
              state.matchedLocation == '/password-reset' ||
              state.matchedLocation == '/mfa-signin')) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: '/mfa-setup',
        builder:
            (context, state) => MfaSetupScreen(
              initialPhone: state.uri.queryParameters['phone'],
            ),
      ),
      GoRoute(
        path: '/mfa-signin',
        builder: (context, state) => const MfaSignInScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
      GoRoute(
        path: '/settings/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
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
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          tertiary: AppColors.primaryLight,
          error: AppColors.error,
          surface: AppColors.surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.1),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.16),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 1,
            shadowColor: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            side: BorderSide(
              color: AppColors.surfaceLight.withValues(alpha: 0.9),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            backgroundColor: AppColors.surface.withValues(alpha: 0.9),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.surfaceLight.withValues(alpha: 0.8),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.surfaceLight.withValues(alpha: 0.8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.surface;
          }),
          side: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.45),
            width: 1.4,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.surface;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary.withValues(alpha: 0.35);
            }
            return AppColors.surfaceLight.withValues(alpha: 0.7);
          }),
        ),
        dividerColor: AppColors.surfaceLight,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.primaryLight,
          tertiary: AppColors.primary,
          error: AppColors.error,
          surface: AppColors.darkSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.35),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.5),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 1,
            shadowColor: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(
              color: AppColors.darkSurfaceLight.withValues(alpha: 0.9),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            backgroundColor: AppColors.darkSurface,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceLight.withValues(alpha: 0.7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.darkSurfaceLight.withValues(alpha: 0.95),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.darkSurfaceLight.withValues(alpha: 0.95),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkSurfaceLight,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accent;
            }
            return AppColors.darkSurface;
          }),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.4,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accent;
            }
            return AppColors.darkSurface;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accent.withValues(alpha: 0.35);
            }
            return AppColors.darkSurfaceLight.withValues(alpha: 0.8);
          }),
        ),
        dividerColor: AppColors.darkSurfaceLight,
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
