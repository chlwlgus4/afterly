import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/shooting_session.dart';
import '../models/customer_group.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _customersCollection =>
      _firestore.collection('customers');
  CollectionReference get _sessionsCollection =>
      _firestore.collection('shooting_sessions');
  CollectionReference get _groupsCollection =>
      _firestore.collection('customer_groups');

  // --- Customer CRUD ---

  Future<String> addCustomer(Customer customer) async {
    try {
      final docRef = await _customersCollection.add(customer.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  Stream<List<Customer>> getCustomersStream(String userId) {
    return _customersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('lastShootingAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Customer.fromMap(
                doc.data() as Map<String, dynamic>,
                documentId: doc.id,
              ))
          .toList();
    });
  }

  Future<List<Customer>> getCustomers(String userId) async {
    try {
      debugPrint('🔍 getCustomers 호출 - userId: $userId');

      final querySnapshot = await _customersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('lastShootingAt', descending: true)
          .get();

      debugPrint('✅ getCustomers 성공 - ${querySnapshot.docs.length}명');

      return querySnapshot.docs
          .map((doc) => Customer.fromMap(
                doc.data() as Map<String, dynamic>,
                documentId: doc.id,
              ))
          .toList();
    } catch (e) {
      debugPrint('❌ getCustomers 실패 - userId: $userId, 에러: $e');
      throw Exception('Failed to get customers: $e');
    }
  }

  Future<Customer?> getCustomer(String customerId) async {
    try {
      final docSnapshot = await _customersCollection.doc(customerId).get();
      if (!docSnapshot.exists) return null;

      return Customer.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        documentId: docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Failed to get customer: $e');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null) {
      throw Exception('Customer ID is required for update');
    }

    try {
      await _customersCollection.doc(customer.id).update(customer.toMap());
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<void> deleteCustomer(String customerId, String userId) async {
    try {
      // Delete all sessions for this customer
      final sessions = await getSessionsForCustomer(userId, customerId);
      for (var session in sessions) {
        if (session.id != null) {
          await deleteSession(session.id!);
        }
      }

      // Delete customer
      await _customersCollection.doc(customerId).delete();
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  // --- ShootingSession CRUD ---

  Future<String> addSession(ShootingSession session) async {
    try {
      final docRef = await _sessionsCollection.add(session.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add session: $e');
    }
  }

  Stream<List<ShootingSession>> getSessionsStream(String userId, String customerId) {
    return _sessionsCollection
        .where('userId', isEqualTo: userId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShootingSession.fromMap(
                doc.data() as Map<String, dynamic>,
                documentId: doc.id,
              ))
          .toList();
    });
  }

  Future<List<ShootingSession>> getSessionsForCustomer(
      String userId, String customerId) async {
    try {
      final querySnapshot = await _sessionsCollection
          .where('userId', isEqualTo: userId)
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ShootingSession.fromMap(
                doc.data() as Map<String, dynamic>,
                documentId: doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get sessions: $e');
    }
  }

  Future<ShootingSession?> getSession(String sessionId) async {
    try {
      final docSnapshot = await _sessionsCollection.doc(sessionId).get();
      if (!docSnapshot.exists) return null;

      return ShootingSession.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        documentId: docSnapshot.id,
      );
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  Future<void> updateSession(ShootingSession session) async {
    if (session.id == null) {
      throw Exception('Session ID is required for update');
    }

    try {
      await _sessionsCollection.doc(session.id).update(session.toMap());
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _sessionsCollection.doc(sessionId).delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // --- Group CRUD ---

  Future<String> addGroup(CustomerGroup group) async {
    try {
      final docRef = await _groupsCollection.add(group.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add group: $e');
    }
  }

  Future<List<CustomerGroup>> getGroups(String userId) async {
    try {
      final querySnapshot = await _groupsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final groups = querySnapshot.docs
          .map((doc) => CustomerGroup.fromMap(
                doc.data() as Map<String, dynamic>,
                documentId: doc.id,
              ))
          .toList();

      // 클라이언트에서 정렬
      groups.sort((a, b) => a.order.compareTo(b.order));

      return groups;
    } catch (e) {
      throw Exception('Failed to get groups: $e');
    }
  }

  Future<void> updateGroup(CustomerGroup group) async {
    if (group.id == null) {
      throw Exception('Group ID is required for update');
    }

    try {
      await _groupsCollection.doc(group.id).update(group.toMap());
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  Future<void> deleteGroup(String groupId, String userId) async {
    try {
      // 그룹 삭제
      await _groupsCollection.doc(groupId).delete();

      // 해당 그룹을 사용하는 고객들의 그룹 필드를 null로 변경
      final customers = await _customersCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in customers.docs) {
        final customer = Customer.fromMap(
          doc.data() as Map<String, dynamic>,
          documentId: doc.id,
        );
        if (customer.group == groupId) {
          batch.update(doc.reference, {'group': null});
        }
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }
}
