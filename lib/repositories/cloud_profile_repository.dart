import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';

class CloudProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> pushProfile(ProfileModel profile, String uid) async {
    try {
      // Ensure ownerId is set
      final profileToSync = profile.copyWith(ownerId: uid, isSynced: true);
      await _firestore.collection('profiles').doc(uid).set(
            profileToSync.toJson(),
            SetOptions(merge: true),
          );
      debugPrint('CloudProfileRepository: Profile pushed successfully for $uid');
    } catch (e) {
      debugPrint('CloudProfileRepository Error: Failed to push profile - $e');
      rethrow;
    }
  }
}
