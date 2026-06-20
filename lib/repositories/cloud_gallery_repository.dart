import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/reshot_capture_model.dart';

class CloudGalleryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<ReShotCaptureModel> pushCapture(ReShotCaptureModel capture, String uid) async {
    try {
      String? cloudUrl = capture.cloudImageUrl;
      
      // Upload image if it hasn't been uploaded yet and the local file exists
      if (cloudUrl == null && capture.filePath.isNotEmpty) {
        final File file = File(capture.filePath);
        if (await file.exists()) {
          final ref = _storage.ref().child('users/$uid/captures/${capture.id}.jpg');
          await ref.putFile(file);
          cloudUrl = await ref.getDownloadURL();
        }
      }

      final captureToSync = capture.copyWith(
        ownerId: uid,
        isSynced: true,
        cloudImageUrl: cloudUrl,
      );

      await _firestore.collection('captures').doc(capture.id).set(
        captureToSync.toJson(),
        SetOptions(merge: true),
      );

      debugPrint('CloudGalleryRepository: Capture ${capture.id} pushed successfully');
      return captureToSync;
    } catch (e) {
      debugPrint('CloudGalleryRepository Error: Failed to push capture - $e');
      rethrow;
    }
  }
}
