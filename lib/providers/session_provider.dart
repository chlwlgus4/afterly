import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shooting_session.dart';
import 'firestore_provider.dart';
import 'auth_provider.dart';

final sessionListProvider =
    AsyncNotifierProvider.family<SessionListNotifier, List<ShootingSession>, String>(
  SessionListNotifier.new,
);

class SessionListNotifier
    extends FamilyAsyncNotifier<List<ShootingSession>, String> {
  @override
  Future<List<ShootingSession>> build(String arg) async {
    final firestore = ref.read(firestoreServiceProvider);
    return firestore.getSessionsForCustomer(arg);
  }

  Future<String> createSession() async {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) throw Exception('User not logged in');

    final firestore = ref.read(firestoreServiceProvider);
    final session = ShootingSession(
      userId: userId,
      customerId: arg,
    );
    final id = await firestore.addSession(session);
    ref.invalidateSelf();
    return id;
  }

  Future<void> updateSession(ShootingSession session) async {
    final firestore = ref.read(firestoreServiceProvider);
    await firestore.updateSession(session);
    ref.invalidateSelf();
  }

  Future<void> deleteSession(String sessionId) async {
    final firestore = ref.read(firestoreServiceProvider);
    await firestore.deleteSession(sessionId);
    ref.invalidateSelf();
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
