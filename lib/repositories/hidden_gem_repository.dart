import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/hidden_gem_model.dart';

abstract class HiddenGemRepository {
  Future<List<HiddenGemModel>> getHiddenGems();
  Future<void> saveHiddenGem(HiddenGemModel gem);
}

class HiveHiddenGemRepository implements HiddenGemRepository {
  static const String _boxName = 'hidden_gems_box';

  // Fix 7: proper UUIDs (v4-format) — safe for future Firebase document keys.
  static const String _seedIdBirthi = '7f3e2a1c-4b5d-4e6f-8a9b-0c1d2e3f4a5b';
  static const String _seedIdChandak = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  static const String _seedIdSasling = 'f9e8d7c6-b5a4-3210-fedc-ba9876543210';

  Future<Box<String>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  @override
  Future<List<HiddenGemModel>> getHiddenGems() async {
    final box = await _getBox();

    // Fix 6: idempotent seeding — check each seed ID individually.
    // If any seed is missing (including after a crash mid-seed), recreate it.
    await _ensureDefaultGemsSeeded(box);

    final List<HiddenGemModel> list = [];
    for (var key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        try {
          final Map<String, dynamic> map =
              jsonDecode(jsonString) as Map<String, dynamic>;
          list.add(HiddenGemModel.fromJson(map));
        } catch (e) {
          // Log silently dropped records — was previously silent.
          debugPrint('HiveHiddenGemRepository: skipping corrupted record key=$key: $e');
        }
      }
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> saveHiddenGem(HiddenGemModel gem) async {
    final box = await _getBox();
    final jsonString = jsonEncode(gem.toJson());
    await box.put(gem.id, jsonString);
  }

  /// Fix 6: idempotent seeding — each default gem is checked independently.
  /// Missing records are recreated regardless of whether the box is empty or not.
  /// Safe to call multiple times with no side effects.
  Future<void> _ensureDefaultGemsSeeded(Box<String> box) async {
    final defaults = _buildDefaultGems();
    for (final gem in defaults) {
      if (!box.containsKey(gem.id)) {
        await saveHiddenGem(gem);
        debugPrint('HiveHiddenGemRepository: seeded missing default gem id=${gem.id}');
      }
    }
  }

  List<HiddenGemModel> _buildDefaultGems() {
    return [
      HiddenGemModel(
        // Fix 7: UUID-format IDs.
        id: _seedIdBirthi,
        name: 'Birthi Falls',
        description:
            'An underrated giant waterfall falling from 126m high. ReShot guides you to stand at the viewpoint bridge for a perfect backdrop layout matching.',
        latitude: 30.1254,
        longitude: 80.1425,
        altitude: '2,210m',
        tags: ['Waterfall', 'Viewpoint', 'Hidden Gem'],
        photoPath: 'placeholder_waterfall',
        createdAt: DateTime.utc(2026, 1, 1, 0, 0, 0),
        updatedAt: DateTime.utc(2026, 1, 1, 0, 0, 0),
      ),
      HiddenGemModel(
        id: _seedIdChandak,
        name: 'Chandak Waterfall',
        description:
            'A hidden paradise surrounded by thick forests. The ideal recreation angle requires shooting from a low height, looking upwards with a 35mm lens.',
        latitude: 29.5985,
        longitude: 80.2033,
        altitude: '1,850m',
        tags: ['Waterfall', 'Hidden Gem', 'Cafe'],
        photoPath: 'placeholder_chandak',
        createdAt: DateTime.utc(2026, 1, 2, 0, 0, 0),
        updatedAt: DateTime.utc(2026, 1, 2, 0, 0, 0),
      ),
      HiddenGemModel(
        id: _seedIdSasling,
        name: 'Sasling Cascade',
        description:
            "Tucked away from commercial travel routes. ReShot's scene recognition identifies this spot instantly and guides you on composition framing.",
        latitude: 29.6241,
        longitude: 80.1255,
        altitude: '1,420m',
        tags: ['Waterfall', 'Viewpoint', 'Hidden Gem'],
        photoPath: 'placeholder_sasling',
        createdAt: DateTime.utc(2026, 1, 3, 0, 0, 0),
        updatedAt: DateTime.utc(2026, 1, 3, 0, 0, 0),
      ),
    ];
  }
}
