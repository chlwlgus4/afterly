import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import 'firestore_provider.dart';
import 'auth_provider.dart' show authTokenReadyProvider, currentUserProvider;

// Stream Provider로 변경하여 실시간 업데이트
final customerListProvider = StreamProvider.autoDispose<List<Customer>>((ref) {
  final userAsync = ref.watch(authTokenReadyProvider);

  // AsyncValue 상태에 따라 다른 스트림 반환
  return userAsync.when(
    data: (user) {
      if (user == null) {
        return Stream.value([]);
      }

      // debugPrint('📡 고객 목록 스트림 시작 - userId: ${user.uid}');
      final firestore = ref.read(firestoreServiceProvider);
      return firestore.getCustomersStream(user.uid);
    },
    loading: () => Stream.value([]), // 빈 리스트 emit (UI에서 처리)
    error: (e, stack) {
      // debugPrint('❌ Auth 에러: $e');
      return Stream.value([]);
    },
  );
});

// 고객 추가/삭제/수정 작업용 Provider
final customerActionsProvider = Provider<CustomerActions>((ref) {
  return CustomerActions(ref);
});

class CustomerActions {
  CustomerActions(this.ref);
  final Ref ref;

  Future<String> addCustomer(String name, {String? group, String? memo}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    final firestore = ref.read(firestoreServiceProvider);
    final customer = Customer(
      userId: userId,
      name: name,
      group: group,
      memo: memo,
    );
    final id = await firestore.addCustomer(customer);
    // Stream이 자동으로 업데이트하므로 invalidate 불필요
    // debugPrint('✅ 고객 추가 완료 - Firestore 스트림이 자동 업데이트');
    return id;
  }

  Future<void> updateCustomerName(String id, String newName) async {
    final firestore = ref.read(firestoreServiceProvider);
    final customer = await firestore.getCustomer(id);

    if (customer == null) {
      throw Exception('고객을 찾을 수 없습니다');
    }

    await firestore.updateCustomer(
      customer.copyWith(name: newName),
    );
    // debugPrint('✅ 고객 이름 수정 완료 - Firestore 스트림이 자동 업데이트');
  }

  Future<void> deleteCustomer(String id) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    final firestore = ref.read(firestoreServiceProvider);
    await firestore.deleteCustomer(id, userId);
    // Stream이 자동으로 업데이트하므로 invalidate 불필요
    // debugPrint('✅ 고객 삭제 완료 - Firestore 스트림이 자동 업데이트');
  }

  Future<void> updateLastShooting(String customerId) async {
    final firestore = ref.read(firestoreServiceProvider);
    final customer = await firestore.getCustomer(customerId);
    if (customer != null) {
      await firestore.updateCustomer(
        customer.copyWith(lastShootingAt: DateTime.now()),
      );
      // Stream이 자동으로 업데이트하므로 invalidate 불필요
    }
  }
}
