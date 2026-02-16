import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth State Provider (현재 로그인 상태)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

// Auth Token Ready Provider - Auth 토큰이 준비될 때까지 대기
final authTokenReadyProvider = FutureProvider.autoDispose<User?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;

  if (user == null) {
    return null;
  }

  // 토큰 강제 갱신 (대기 시간 최소화)
  try {
    await user.getIdToken(true); // force refresh
    // 짧은 대기로 최소한의 전파 시간만 확보
    await Future.delayed(const Duration(milliseconds: 100));
    return user;
  } catch (e) {
    return null;
  }
});
