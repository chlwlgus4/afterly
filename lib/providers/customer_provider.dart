import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import 'database_provider.dart';

final customerListProvider =
    AsyncNotifierProvider<CustomerListNotifier, List<Customer>>(
  CustomerListNotifier.new,
);

class CustomerListNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final db = ref.read(databaseServiceProvider);
    return db.getCustomers();
  }

  Future<int> addCustomer(String name) async {
    final db = ref.read(databaseServiceProvider);
    final customer = Customer(name: name);
    final id = await db.insertCustomer(customer);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteCustomer(int id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteCustomer(id);
    ref.invalidateSelf();
  }

  Future<void> updateLastShooting(int customerId) async {
    final db = ref.read(databaseServiceProvider);
    final customer = await db.getCustomer(customerId);
    if (customer != null) {
      await db.updateCustomer(
        customer.copyWith(lastShootingAt: DateTime.now()),
      );
      ref.invalidateSelf();
    }
  }
}
