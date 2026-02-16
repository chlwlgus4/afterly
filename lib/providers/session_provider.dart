import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shooting_session.dart';
import 'firestore_provider.dart';
import 'auth_provider.dart' show authTokenReadyProvider, currentUserProvider;

// Stream Provider로 변경하여 실시간 업데이트
final sessionListProvider = StreamProvider.autoDispose.family<List<ShootingSession>, String>((ref, customerId) {
  final userAsync = ref.watch(authTokenReadyProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) {
        return Stream.value([]);
      }

      final firestore = ref.read(firestoreServiceProvider);
      return firestore.getSessionsStream(user.uid, customerId);
    },
    loading: () => Stream.value([]),
    error: (e, stack) => Stream.value([]),
  );
});

// 세션 추가/삭제/수정 작업용 Provider
final sessionActionsProvider = Provider<SessionActions>((ref) {
  return SessionActions(ref);
});

class SessionActions {
  SessionActions(this.ref);
  final Ref ref;

  Future<String> createSession(String customerId) async {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) throw Exception('User not logged in');

    final firestore = ref.read(firestoreServiceProvider);
    final session = ShootingSession(
      userId: userId,
      customerId: customerId,
    );
    final id = await firestore.addSession(session);
    // debugPrint('✅ 세션 추가 완료 - Firestore 스트림이 자동 업데이트');
    return id;
  }

  Future<void> updateSession(ShootingSession session) async {
    final firestore = ref.read(firestoreServiceProvider);
    await firestore.updateSession(session);
    // debugPrint('✅ 세션 업데이트 완료 - Firestore 스트림이 자동 업데이트');
  }

  Future<void> deleteSession(String sessionId) async {
    final firestore = ref.read(firestoreServiceProvider);
    await firestore.deleteSession(sessionId);
    // debugPrint('✅ 세션 삭제 완료 - Firestore 스트림이 자동 업데이트');
  }
}

final currentSessionProvider =
    AsyncNotifierProvider<CurrentSessionNotifier, ShootingSession?>(
  CurrentSessionNotifier.new,
);

class CurrentSessionNotifier extends AsyncNotifier<ShootingSession?> {
  @override
  Future<ShootingSession?> build() async => null;

  Future<void> loadSession(String sessionId) async {
    final firestore = ref.read(firestoreServiceProvider);
    state = AsyncData(await firestore.getSession(sessionId));
  }

  Future<void> updateSession(ShootingSession session) async {
    final firestore = ref.read(firestoreServiceProvider);
    await firestore.updateSession(session);
    state = AsyncData(session);
  }

  void setSession(ShootingSession session) {
    state = AsyncData(session);
  }
}
