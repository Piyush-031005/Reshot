import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/hidden_gem_model.dart';
import '../services/cloudinary_service.dart';

class CloudHiddenGemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<HiddenGemModel> pushHiddenGem(HiddenGemModel gem, String uid) async {
    try {
      String? cloudUrl = gem.cloudImageUrl;
      
      // Don't upload placeholder seed images
      if (cloudUrl == null && !gem.photoPath.startsWith('placeholder_')) {
        final File file = File(gem.photoPath);
        if (await file.exists()) {
          cloudUrl = await CloudinaryService.uploadImage(gem.photoPath);
        }
      }

      final gemToSync = gem.copyWith(
        ownerId: uid,
        isSynced: true,
        cloudImageUrl: cloudUrl,
      );

      debugPrint('CLOUDINARY_LOG [Pipeline Step 10: Firestore Write] Collection: hidden_gems, Doc ID: ${gem.id}, cloudImageUrl: $cloudUrl');
      await _firestore.collection('hidden_gems').doc(gem.id).set(
        gemToSync.toJson(),
        SetOptions(merge: true),
      );

      debugPrint('CLOUDINARY_LOG [Pipeline Step 11: Firestore Write Success] Gem ${gem.id} pushed successfully');
      return gemToSync;
    } catch (e) {
      debugPrint('CLOUDINARY_LOG [Pipeline Step 12: Repository Error] Failed to push gem - $e');
      rethrow;
    }
  }
}
