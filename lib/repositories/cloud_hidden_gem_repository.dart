import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/hidden_gem_model.dart';

class CloudHiddenGemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<HiddenGemModel> pushHiddenGem(HiddenGemModel gem, String uid) async {
    try {
      String? cloudUrl = gem.cloudImageUrl;
      
      // Don't upload placeholder seed images
      if (cloudUrl == null && !gem.photoPath.startsWith('placeholder_')) {
        final File file = File(gem.photoPath);
        if (await file.exists()) {
          final ref = _storage.ref().child('users/$uid/gems/${gem.id}.jpg');
          await ref.putFile(file);
          cloudUrl = await ref.getDownloadURL();
        }
      }

      final gemToSync = gem.copyWith(
        ownerId: uid,
        isSynced: true,
        cloudImageUrl: cloudUrl,
      );

      await _firestore.collection('hidden_gems').doc(gem.id).set(
        gemToSync.toJson(),
        SetOptions(merge: true),
      );

      debugPrint('CloudHiddenGemRepository: Gem ${gem.id} pushed successfully');
      return gemToSync;
    } catch (e) {
      debugPrint('CloudHiddenGemRepository Error: Failed to push gem - $e');
      rethrow;
    }
  }
}
