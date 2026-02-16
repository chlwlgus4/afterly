import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_group.dart';
import 'firestore_provider.dart';
import 'auth_provider.dart' show authTokenReadyProvider, currentUserProvider;

final groupListProvider =
    FutureProvider.autoDispose<List<CustomerGroup>>((ref) async {
  // Auth 토큰이 준비될 때까지 대기
  final userAsync = ref.watch(authTokenReadyProvider);

  // AsyncValue를 Future로 변환
  return userAsync.when(
    data: (user) async {
      if (user == null) return [];

      final firestore = ref.read(firestoreServiceProvider);
      return firestore.getGroups(user.uid);
    },
    loading: () async => [], // 빈 리스트 반환 (UI에서 처리)
    error: (e, stack) async => [],
  );
});

// 그룹 추가/삭제/수정 작업용 Provider
final groupActionsProvider = Provider<GroupActions>((ref) {
  return GroupActions(ref);
});

class GroupActions {
  GroupActions(this.ref);
  final Ref ref;

  Future<String> addGroup(String name, {String? color}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    final firestore = ref.read(firestoreServiceProvider);

    // 현재 그룹 개수를 가져와서 order 설정
    final currentGroups = ref.read(groupListProvider).valueOrNull ?? [];

    final group = CustomerGroup(
      userId: userId,
      name: name,
      color: color,
      order: currentGroups.length,
    );

    final id = await firestore.addGroup(group);
    // 그룹 목록 갱신
    ref.invalidate(groupListProvider);
    return id;
  }

  Future<void> updateGroup(CustomerGroup group) async {
    final firestore = ref.read(firestoreServiceProvider);
    await firestore.updateGroup(group);
    // 그룹 목록 갱신
    ref.invalidate(groupListProvider);
  }

  Future<void> deleteGroup(String id) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    final firestore = ref.read(firestoreServiceProvider);
    await firestore.deleteGroup(id, userId);
    // 그룹 목록 갱신
    ref.invalidate(groupListProvider);
  }

  Future<void> reorderGroups(List<CustomerGroup> reorderedGroups) async {
    final firestore = ref.read(firestoreServiceProvider);

    // 순서 업데이트
    for (var i = 0; i < reorderedGroups.length; i++) {
      final updatedGroup = reorderedGroups[i].copyWith(order: i);
      await firestore.updateGroup(updatedGroup);
    }

    // 그룹 목록 갱신
    ref.invalidate(groupListProvider);
  }
}
