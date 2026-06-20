import 'package:flutter_test/flutter_test.dart';
import 'package:reshot/models/profile_model.dart';
import 'package:reshot/models/reshot_capture_model.dart';
import 'package:reshot/models/hidden_gem_model.dart';
import 'package:reshot/repositories/gallery_repository.dart';
import 'package:reshot/repositories/hidden_gem_repository.dart';
import 'package:reshot/repositories/profile_repository.dart';
import 'package:reshot/providers/repository_provider.dart';

// In-memory repositories for testing
class MockGalleryRepository implements GalleryRepository {
  final List<ReShotCaptureModel> captures = [];
  @override
  Future<List<ReShotCaptureModel>> getCaptures() async => captures;
  @override
  Future<void> saveCapture(ReShotCaptureModel capture) async {
    captures.add(capture);
  }
}

class MockHiddenGemRepository implements HiddenGemRepository {
  final List<HiddenGemModel> gems = [];
  @override
  Future<List<HiddenGemModel>> getHiddenGems() async => gems;
  @override
  Future<void> saveHiddenGem(HiddenGemModel gem) async {
    gems.add(gem);
  }
}

class MockProfileRepository implements ProfileRepository {
  ProfileModel profile = ProfileModel(
    explorerName: 'EXPLORER_007',
    xp: 0,
    joinDate: DateTime.utc(2026, 1, 1),
    unlockedAchievementIds: const [],
  );

  @override
  Future<ProfileModel> getProfile() async => profile;

  @override
  Future<void> saveProfile(ProfileModel p) async {
    profile = p;
  }
}

void main() {
  group('ProfileModel Serialization', () {
    test('toJson/fromJson round-trip', () {
      final model = ProfileModel(
        explorerName: 'CYBER_TRAVELLER',
        xp: 350,
        joinDate: DateTime.utc(2026, 6, 19),
        unlockedAchievementIds: const ['first_capture', 'match_90_club'],
      );

      final json = model.toJson();
      final restored = ProfileModel.fromJson(json);

      expect(restored.explorerName, equals('CYBER_TRAVELLER'));
      expect(restored.xp, equals(350));
      expect(restored.joinDate, equals(DateTime.utc(2026, 6, 19)));
      expect(restored.unlockedAchievementIds, equals(['first_capture', 'match_90_club']));
    });

    test('fromJson default fallback values on null keys', () {
      final json = <String, dynamic>{};
      final restored = ProfileModel.fromJson(json);

      expect(restored.explorerName, equals('EXPLORER_007'));
      expect(restored.xp, equals(0));
      expect(restored.unlockedAchievementIds, isEmpty);
    });
  });

  group('XP Progression & Rank Logic', () {
    late AppRepositoryProvider provider;
    late MockProfileRepository mockProfileRepo;

    setUp(() async {
      mockProfileRepo = MockProfileRepository();
      provider = AppRepositoryProvider(
        galleryRepository: MockGalleryRepository(),
        hiddenGemRepository: MockHiddenGemRepository(),
        profileRepository: mockProfileRepo,
        cameras: const [],
      );
      await provider.loadProfile();
    });

    test('updateProfileName saves and notifies', () async {
      await provider.updateProfileName('ALIAS_99');
      expect(provider.profile.explorerName, equals('ALIAS_99'));
      expect(mockProfileRepo.profile.explorerName, equals('ALIAS_99'));
    });

    test('Rank calculation map matching XP thresholds', () async {
      // 0 XP -> Rookie Explorer
      expect(provider.getRank(), equals('Rookie Explorer'));

      // 100 XP -> Trail Hunter
      await mockProfileRepo.saveProfile(provider.profile.copyWith(xp: 100));
      await provider.loadProfile();
      expect(provider.getRank(), equals('Trail Hunter'));

      // 300 XP -> Hidden Gem Scout
      await mockProfileRepo.saveProfile(provider.profile.copyWith(xp: 300));
      await provider.loadProfile();
      expect(provider.getRank(), equals('Hidden Gem Scout'));

      // 600 XP -> Path Finder
      await mockProfileRepo.saveProfile(provider.profile.copyWith(xp: 600));
      await provider.loadProfile();
      expect(provider.getRank(), equals('Path Finder'));

      // 1000 XP -> Elite Explorer
      await mockProfileRepo.saveProfile(provider.profile.copyWith(xp: 1000));
      await provider.loadProfile();
      expect(provider.getRank(), equals('Elite Explorer'));

      // 2000 XP -> Legend Explorer
      await mockProfileRepo.saveProfile(provider.profile.copyWith(xp: 2000));
      await provider.loadProfile();
      expect(provider.getRank(), equals('Legend Explorer'));

      // 5000 XP -> Legend Explorer (maxed)
      await mockProfileRepo.saveProfile(provider.profile.copyWith(xp: 5000));
      await provider.loadProfile();
      expect(provider.getRank(), equals('Legend Explorer'));
    });

    test('Level progress calculations for various thresholds', () async {
      // Setup current profile with 50 XP
      await mockProfileRepo.saveProfile(provider.profile.copyWith(xp: 50));
      await provider.loadProfile();

      // 50 XP -> Rookie Explorer (0 - 100 range)
      var progress = provider.getLevelProgress();
      expect(progress['currentInLevel'], equals(50));
      expect(progress['targetInLevel'], equals(100));
      expect(progress['percent'], equals(0.5));

      // 150 XP -> Trail Hunter (100 - 300 range)
      provider = AppRepositoryProvider(
        galleryRepository: MockGalleryRepository(),
        hiddenGemRepository: MockHiddenGemRepository(),
        profileRepository: MockProfileRepository()..profile = ProfileModel(
          explorerName: 'E', xp: 150, joinDate: DateTime.now(), unlockedAchievementIds: [],
        ),
        cameras: const [],
      );
      await provider.loadProfile();
      progress = provider.getLevelProgress();
      expect(progress['currentInLevel'], equals(50)); // 150 - 100
      expect(progress['targetInLevel'], equals(200)); // 300 - 100
      expect(progress['percent'], equals(0.25));

      // 2500 XP -> Legend Explorer (2000 - 2000 max range)
      provider = AppRepositoryProvider(
        galleryRepository: MockGalleryRepository(),
        hiddenGemRepository: MockHiddenGemRepository(),
        profileRepository: MockProfileRepository()..profile = ProfileModel(
          explorerName: 'E', xp: 2500, joinDate: DateTime.now(), unlockedAchievementIds: [],
        ),
        cameras: const [],
      );
      await provider.loadProfile();
      progress = provider.getLevelProgress();
      expect(progress['percent'], equals(1.0));
    });
  });

  group('Provider Gamification Event Handling', () {
    late AppRepositoryProvider provider;
    late MockGalleryRepository mockGalleryRepo;
    late MockHiddenGemRepository mockHiddenGemRepo;
    late MockProfileRepository mockProfileRepo;

    setUp(() async {
      mockGalleryRepo = MockGalleryRepository();
      mockHiddenGemRepo = MockHiddenGemRepository();
      mockProfileRepo = MockProfileRepository();
      provider = AppRepositoryProvider(
        galleryRepository: mockGalleryRepo,
        hiddenGemRepository: mockHiddenGemRepo,
        profileRepository: mockProfileRepo,
        cameras: const [],
      );
      await provider.loadProfile();
    });

    test('saveCapture awards +10 XP and unlocks first_capture achievement', () async {
      final capture = ReShotCaptureModel(
        id: 'c1',
        filePath: 'path',
        score: 85.0,
        displayScore: 85.0,
        badge: 'EPIC',
        timestamp: DateTime.now(),
        locationName: 'Birthi Falls',
      );

      await provider.saveCapture(capture);

      expect(provider.profile.xp, equals(10));
      expect(provider.profile.unlockedAchievementIds, contains('first_capture'));
      expect(provider.profile.unlockedAchievementIds, isNot(contains('match_90_club')));
    });

    test('saveCapture 90%+ awards +35 XP and unlocks 90% Match Club', () async {
      final capture = ReShotCaptureModel(
        id: 'c2',
        filePath: 'path',
        score: 92.5,
        displayScore: 92.5,
        badge: 'EPIC',
        timestamp: DateTime.now(),
        locationName: 'Birthi Falls',
      );

      await provider.saveCapture(capture);

      expect(provider.profile.xp, equals(35)); // +10 base +25 bonus
      expect(provider.profile.unlockedAchievementIds, contains('first_capture'));
      expect(provider.profile.unlockedAchievementIds, contains('match_90_club'));
      expect(provider.profile.unlockedAchievementIds, isNot(contains('legendary_shot')));
    });

    test('saveCapture 95%+ awards +35 XP and unlocks Legendary Shot', () async {
      final capture = ReShotCaptureModel(
        id: 'c3',
        filePath: 'path',
        score: 95.5,
        displayScore: 95.5,
        badge: 'LEGENDARY',
        timestamp: DateTime.now(),
        locationName: 'Birthi Falls',
      );

      await provider.saveCapture(capture);

      expect(provider.profile.xp, equals(35));
      expect(provider.profile.unlockedAchievementIds, contains('first_capture'));
      expect(provider.profile.unlockedAchievementIds, contains('match_90_club'));
      expect(provider.profile.unlockedAchievementIds, contains('legendary_shot'));
    });

    test('saveHiddenGem awards +50 XP and unlocks first_gem achievement', () async {
      final gem = HiddenGemModel(
        id: 'custom-gem-uuid-001',
        name: 'Spot',
        description: 'Desc',
        latitude: 29.0,
        longitude: 80.0,
        altitude: '1200m',
        tags: [],
        photoPath: 'photo',
        createdAt: DateTime.now(),
      );

      await provider.saveHiddenGem(gem);

      expect(provider.profile.xp, equals(50));
      expect(provider.profile.unlockedAchievementIds, contains('first_gem'));
    });
  });
}
