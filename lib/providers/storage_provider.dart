import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

// Storage Service Provider
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
