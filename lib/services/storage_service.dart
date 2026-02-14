import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image to Firebase Storage
  /// Returns the download URL
  Future<String> uploadImage({
    required File imageFile,
    required String userId,
    required String folder, // 'before', 'after', 'aligned_before', 'aligned_after'
    String? customFileName,
  }) async {
    try {
      final fileName = customFileName ??
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final ref = _storage.ref().child('users/$userId/$folder/$fileName');

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete image from Firebase Storage using URL
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Delete all images for a user
  Future<void> deleteAllUserImages(String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId');
      final listResult = await ref.listAll();

      // Delete all files
      for (var item in listResult.items) {
        await item.delete();
      }

      // Recursively delete all subdirectories
      for (var prefix in listResult.prefixes) {
        await _deleteFolder(prefix);
      }
    } catch (e) {
      throw Exception('Failed to delete user images: $e');
    }
  }

  /// Delete a folder and all its contents recursively
  Future<void> _deleteFolder(Reference folderRef) async {
    final listResult = await folderRef.listAll();

    for (var item in listResult.items) {
      await item.delete();
    }

    for (var prefix in listResult.prefixes) {
      await _deleteFolder(prefix);
    }
  }

  /// Delete images for a specific session
  Future<void> deleteSessionImages({
    String? beforeImageUrl,
    String? afterImageUrl,
    String? alignedBeforeUrl,
    String? alignedAfterUrl,
  }) async {
    final urls = [
      beforeImageUrl,
      afterImageUrl,
      alignedBeforeUrl,
      alignedAfterUrl,
    ].whereType<String>().toList();

    for (var url in urls) {
      try {
        await deleteImageByUrl(url);
      } catch (e) {
        // Continue deleting other images even if one fails
        debugPrint('Failed to delete image $url: $e');
      }
    }
  }
}
