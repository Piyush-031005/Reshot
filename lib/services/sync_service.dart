import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../repositories/gallery_repository.dart';
import '../repositories/hidden_gem_repository.dart';
import '../repositories/profile_repository.dart';
import 'auth_service.dart';
import '../repositories/cloud_gallery_repository.dart';
import '../repositories/cloud_hidden_gem_repository.dart';
import '../repositories/cloud_profile_repository.dart';

class SyncService {
  final GalleryRepository localGalleryRepo;
  final HiddenGemRepository localGemRepo;
  final ProfileRepository localProfileRepo;

  final CloudGalleryRepository cloudGalleryRepo;
  final CloudHiddenGemRepository cloudGemRepo;
  final CloudProfileRepository cloudProfileRepo;

  final AuthService authService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required this.localGalleryRepo,
    required this.localGemRepo,
    required this.localProfileRepo,
    required this.cloudGalleryRepo,
    required this.cloudGemRepo,
    required this.cloudProfileRepo,
    required this.authService,
  }) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        debugPrint('SyncService: Network online. Triggering sync.');
        syncAll();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        debugPrint('SyncService: Offline, aborting sync.');
        return;
      }

      final uid = await authService.ensureAnonymousLogin();
      if (uid == null) {
        debugPrint('SyncService: Failed to get UID, aborting sync.');
        return;
      }

      await _syncProfile(uid);
      await _syncHiddenGems(uid);
      await _syncCaptures(uid);

    } catch (e) {
      debugPrint('SyncService Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncProfile(String uid) async {
    final profile = await localProfileRepo.getProfile();
    if (!profile.isSynced) {
      await cloudProfileRepo.pushProfile(profile, uid);
      final updatedProfile = profile.copyWith(ownerId: uid, isSynced: true);
      await localProfileRepo.saveProfile(updatedProfile);
      debugPrint('SyncService: Profile synced.');
    }
  }

  Future<void> _syncHiddenGems(String uid) async {
    final gems = await localGemRepo.getHiddenGems();
    for (final gem in gems) {
      if (!gem.isSynced) {
        try {
          final updatedGem = await cloudGemRepo.pushHiddenGem(gem, uid);
          await localGemRepo.saveHiddenGem(updatedGem);
          debugPrint('SyncService: Gem ${gem.id} synced.');
        } catch (e) {
          debugPrint('SyncService Error: Failed to sync gem ${gem.id} - $e');
        }
      }
    }
  }

  Future<void> _syncCaptures(String uid) async {
    final captures = await localGalleryRepo.getCaptures();
    for (final capture in captures) {
      if (!capture.isSynced) {
        try {
          final updatedCapture = await cloudGalleryRepo.pushCapture(capture, uid);
          await localGalleryRepo.saveCapture(updatedCapture);
          debugPrint('SyncService: Capture ${capture.id} synced.');
        } catch (e) {
          debugPrint('SyncService Error: Failed to sync capture ${capture.id} - $e');
        }
      }
    }
  }
}
