import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import 'firestore_provider.dart';
import 'auth_provider.dart';

final customerListProvider =
    AsyncNotifierProvider<CustomerListNotifier, List<Customer>>(
  CustomerListNotifier.new,
);

class CustomerListNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final userId = ref.watch(currentUserProvider)?.uid;
    if (userId == null) return [];

    final firestore = ref.read(firestoreServiceProvider);
    return firestore.getCustomers(userId);
  }

  Future<String> addCustomer(String name) async {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) throw Exception('User not logged in');

    final firestore = ref.read(firestoreServiceProvider);
    final customer = Customer(
      userId: userId,
      name: name,
    );
    final id = await firestore.addCustomer(customer);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteCustomer(String id) async {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) throw Exception('User not logged in');

    final firestore = ref.read(firestoreServiceProvider);
    await firestore.deleteCustomer(id, userId);
    ref.invalidateSelf();
  }

  Future<void> updateLastShooting(String customerId) async {
    final firestore = ref.read(firestoreServiceProvider);
    final customer = await firestore.getCustomer(customerId);
    if (customer != null) {
      await firestore.updateCustomer(
        customer.copyWith(lastShootingAt: DateTime.now()),
      );
      ref.invalidateSelf();
    }
  }
}
