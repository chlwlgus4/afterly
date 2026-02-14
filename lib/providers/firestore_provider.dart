import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';

// Firestore Service Provider
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());
