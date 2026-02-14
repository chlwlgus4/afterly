import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/shooting_session.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _customersCollection =>
      _firestore.collection('customers');
  CollectionReference get _sessionsCollection =>
      _firestore.collection('shooting_sessions');

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
      final querySnapshot = await _customersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('lastShootingAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Customer.fromMap(
                doc.data() as Map<String, dynamic>,
                documentId: doc.id,
              ))
          .toList();
    } catch (e) {
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
      final sessions = await getSessionsForCustomer(customerId);
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

  Stream<List<ShootingSession>> getSessionsStream(String customerId) {
    return _sessionsCollection
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
      String customerId) async {
    try {
      final querySnapshot = await _sessionsCollection
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
}
