import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reshot_capture_model.dart';
import '../services/cloudinary_service.dart';

class CloudGalleryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ReShotCaptureModel> pushCapture(ReShotCaptureModel capture, String uid) async {
    try {
      String? cloudUrl = capture.cloudImageUrl;
      
      // Upload image if it hasn't been uploaded yet and the local file exists
      if (cloudUrl == null && capture.filePath.isNotEmpty) {
        final File file = File(capture.filePath);
        if (await file.exists()) {
          cloudUrl = await CloudinaryService.uploadImage(capture.filePath);
        }
      }

      final captureToSync = capture.copyWith(
        ownerId: uid,
        isSynced: true,
        cloudImageUrl: cloudUrl,
      );

      debugPrint('CLOUDINARY_LOG [Pipeline Step 10: Firestore Write] Collection: captures, Doc ID: ${capture.id}, cloudImageUrl: $cloudUrl');
      await _firestore.collection('captures').doc(capture.id).set(
        captureToSync.toJson(),
        SetOptions(merge: true),
      );

      debugPrint('CLOUDINARY_LOG [Pipeline Step 11: Firestore Write Success] Capture ${capture.id} pushed successfully');
      return captureToSync;
    } catch (e) {
      debugPrint('CLOUDINARY_LOG [Pipeline Step 12: Repository Error] Failed to push capture - $e');
      rethrow;
    }
  }
}
