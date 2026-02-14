import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shooting_session.dart';
import 'database_provider.dart';

final sessionListProvider =
    AsyncNotifierProvider.family<SessionListNotifier, List<ShootingSession>, int>(
  SessionListNotifier.new,
);

class SessionListNotifier
    extends FamilyAsyncNotifier<List<ShootingSession>, int> {
  @override
  Future<List<ShootingSession>> build(int arg) async {
    final db = ref.read(databaseServiceProvider);
    return db.getSessionsForCustomer(arg);
  }

  Future<int> createSession() async {
    final db = ref.read(databaseServiceProvider);
    final session = ShootingSession(customerId: arg);
    final id = await db.insertSession(session);
    ref.invalidateSelf();
    return id;
  }

  Future<void> updateSession(ShootingSession session) async {
    final db = ref.read(databaseServiceProvider);
    await db.updateSession(session);
    ref.invalidateSelf();
  }

  Future<void> deleteSession(int sessionId) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteSession(sessionId);
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

  Future<void> loadSession(int sessionId) async {
    final db = ref.read(databaseServiceProvider);
    state = AsyncData(await db.getSession(sessionId));
  }

  Future<void> updateSession(ShootingSession session) async {
    final db = ref.read(databaseServiceProvider);
    await db.updateSession(session);
    state = AsyncData(session);
  }

  void setSession(ShootingSession session) {
    state = AsyncData(session);
  }
}
