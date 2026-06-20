import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../models/reshot_capture_model.dart';
import '../models/hidden_gem_model.dart';
import '../repositories/gallery_repository.dart';
import '../repositories/hidden_gem_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/sync_service.dart';

/// Single ChangeNotifier that carries repositories, cameras, and profile state
/// into the widget tree via Provider.
class AppRepositoryProvider extends ChangeNotifier {
  final GalleryRepository galleryRepository;
  final HiddenGemRepository hiddenGemRepository;
  final ProfileRepository profileRepository;
  final SyncService syncService;
  final List<CameraDescription> cameras;

  ProfileModel? _profile;
  ProfileModel get profile => _profile ?? ProfileModel.defaultProfile();

  AppRepositoryProvider({
    required this.galleryRepository,
    required this.hiddenGemRepository,
    required this.profileRepository,
    required this.syncService,
    required this.cameras,
  }) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _profile = await profileRepository.getProfile();
    notifyListeners();
  }

  Future<void> updateProfileName(String name) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(explorerName: name, isSynced: false, updatedAt: DateTime.now());
    await profileRepository.saveProfile(_profile!);
    notifyListeners();
    syncService.syncAll();
  }

  /// Saves a capture, awards XP (+10 base, +25 bonus for >=90%),
  /// updates achievements, and notifies listeners.
  Future<void> saveCapture(ReShotCaptureModel capture) async {
    final captureToSave = capture.copyWith(isSynced: false, updatedAt: DateTime.now());
    await galleryRepository.saveCapture(captureToSave);

    int xpGained = 10;
    if (capture.score >= 90.0) {
      xpGained += 25;
    }

    final allCaptures = await galleryRepository.getCaptures();
    final capturesCount = allCaptures.length;

    final achievementsToUnlock = <String>{};
    if (capturesCount >= 1) achievementsToUnlock.add('first_capture');
    if (capturesCount >= 10) achievementsToUnlock.add('reshots_10');
    if (capturesCount >= 50) achievementsToUnlock.add('reshots_50');
    if (capture.score >= 90.0) achievementsToUnlock.add('match_90_club');
    if (capture.score >= 95.0) achievementsToUnlock.add('legendary_shot');

    if (_profile != null) {
      final updatedAchievements = Set<String>.from(_profile!.unlockedAchievementIds)
        ..addAll(achievementsToUnlock);

      _profile = _profile!.copyWith(
        xp: _profile!.xp + xpGained,
        unlockedAchievementIds: updatedAchievements.toList(),
        isSynced: false,
        updatedAt: DateTime.now(),
      );
      await profileRepository.saveProfile(_profile!);
    }

    notifyListeners();
    syncService.syncAll();
  }

  /// Saves a custom gem, awards XP (+50), checks achievements,
  /// and notifies listeners.
  Future<void> saveHiddenGem(HiddenGemModel gem) async {
    final gemToSave = gem.copyWith(isSynced: false, updatedAt: DateTime.now());
    await hiddenGemRepository.saveHiddenGem(gemToSave);

    final allGems = await hiddenGemRepository.getHiddenGems();
    
    // Count user-created custom gems (excluding default seeds)
    const defaultIds = {
      '7f3e2a1c-4b5d-4e6f-8a9b-0c1d2e3f4a5b',
      'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      'f9e8d7c6-b5a4-3210-fedc-ba9876543210',
    };
    final customGemsCount = allGems.where((g) => !defaultIds.contains(g.id)).length;

    final achievementsToUnlock = <String>{};
    if (customGemsCount >= 1) achievementsToUnlock.add('first_gem');
    if (customGemsCount >= 5) achievementsToUnlock.add('gems_5');

    if (_profile != null) {
      final updatedAchievements = Set<String>.from(_profile!.unlockedAchievementIds)
        ..addAll(achievementsToUnlock);

      _profile = _profile!.copyWith(
        xp: _profile!.xp + 50,
        unlockedAchievementIds: updatedAchievements.toList(),
        isSynced: false,
        updatedAt: DateTime.now(),
      );
      await profileRepository.saveProfile(_profile!);
    }

    notifyListeners();
    syncService.syncAll();
  }

  /// Calculates rank dynamically based on current XP
  String getRank() {
    final currentXp = profile.xp;
    if (currentXp >= 2000) return 'Legend Explorer';
    if (currentXp >= 1000) return 'Elite Explorer';
    if (currentXp >= 600) return 'Path Finder';
    if (currentXp >= 300) return 'Hidden Gem Scout';
    if (currentXp >= 100) return 'Trail Hunter';
    return 'Rookie Explorer';
  }

  /// Calculates progress toward next level (XP within current tier, target XP for next tier)
  /// Returns a map with 'current', 'target', and 'percentage' values.
  Map<String, dynamic> getLevelProgress() {
    final currentXp = profile.xp;
    int base = 0;
    int target = 100;

    if (currentXp >= 2000) {
      base = 2000;
      target = 2000; // maxed
    } else if (currentXp >= 1000) {
      base = 1000;
      target = 2000;
    } else if (currentXp >= 600) {
      base = 600;
      target = 1000;
    } else if (currentXp >= 300) {
      base = 300;
      target = 600;
    } else if (currentXp >= 100) {
      base = 100;
      target = 300;
    } else {
      base = 0;
      target = 100;
    }

    final range = target - base;
    final progress = currentXp - base;
    final double percent = range == 0 ? 1.0 : (progress / range).clamp(0.0, 1.0);

    return {
      'currentInLevel': progress,
      'targetInLevel': range,
      'totalCurrent': currentXp,
      'totalTarget': target,
      'percent': percent,
    };
  }
}

