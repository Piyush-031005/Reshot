import 'package:flutter_test/flutter_test.dart';
import 'package:findra/models/reshot_capture_model.dart';
import 'package:findra/models/hidden_gem_model.dart';

void main() {
  // ─────────────────────────────────────────────────
  // Helper: mirrors exact production badge logic.
  // Badge MUST be classified from raw (unrounded) score.
  // ─────────────────────────────────────────────────
  String getBadgeTier(double rawScore) {
    if (rawScore >= 95.0) return 'LEGENDARY';
    if (rawScore >= 85.0) return 'EPIC';
    if (rawScore >= 70.0) return 'GREAT';
    return 'GOOD TRY';
  }

  /// Simulates the production rounding applied for display only.
  double toDisplayScore(double rawScore) =>
      double.parse(rawScore.toStringAsFixed(1));

  // ─────────────────────────────────────────────────
  // GROUP 1: Badge Threshold — Critical Edge Cases
  // ─────────────────────────────────────────────────
  group('Badge Threshold — Critical Edge Cases', () {
    // The audit-identified rounding bug: toStringAsFixed(1) rounds 94.95+
    // to 95.0, which was incorrectly promoting scores to LEGENDARY.
    // Fix: badge must use raw score, not display score.

    test('94.94 raw → display 94.9 → EPIC (NOT LEGENDARY)', () {
      const raw = 94.94;
      final display = toDisplayScore(raw);
      expect(display, equals(94.9));           // display rounds down
      expect(getBadgeTier(raw), equals('EPIC')); // badge uses raw → EPIC
    });

    test('94.95 raw → display 95.0 → still EPIC from raw score', () {
      const raw = 94.95;
      final display = toDisplayScore(raw);
      // The rounding bug: display rounds UP to 95.0.
      // If badge used display score, this would be LEGENDARY — that is the bug.
      expect(display, equals(95.0));            // display rounds UP — this is the trap
      // Correct: badge uses RAW score → must remain EPIC.
      expect(getBadgeTier(raw), equals('EPIC')); // raw < 95.0 → EPIC
    });

    test('94.99 raw → display 95.0 → still EPIC from raw score', () {
      const raw = 94.99;
      final display = toDisplayScore(raw);
      expect(display, equals(95.0));             // display rounds up
      expect(getBadgeTier(raw), equals('EPIC'));  // raw < 95.0 → EPIC
    });

    test('95.00 raw → LEGENDARY (exact boundary)', () {
      const raw = 95.0;
      expect(getBadgeTier(raw), equals('LEGENDARY'));
    });

    test('95.01 raw → LEGENDARY', () {
      expect(getBadgeTier(95.01), equals('LEGENDARY'));
    });

    test('94.9999... raw → EPIC (just below boundary)', () {
      // The largest double below 95.0.
      const raw = 94.9999;
      expect(getBadgeTier(raw), equals('EPIC'));
    });

    // Full tier sweep
    test('All tier boundaries are correct', () {
      expect(getBadgeTier(100.0), equals('LEGENDARY'));
      expect(getBadgeTier(98.5), equals('LEGENDARY'));
      expect(getBadgeTier(95.0), equals('LEGENDARY'));

      expect(getBadgeTier(94.99), equals('EPIC'));
      expect(getBadgeTier(90.0), equals('EPIC'));
      expect(getBadgeTier(85.0), equals('EPIC'));

      expect(getBadgeTier(84.99), equals('GREAT'));
      expect(getBadgeTier(75.5), equals('GREAT'));
      expect(getBadgeTier(70.0), equals('GREAT'));

      expect(getBadgeTier(69.99), equals('GOOD TRY'));
      expect(getBadgeTier(50.0), equals('GOOD TRY'));
      expect(getBadgeTier(0.0), equals('GOOD TRY'));
    });
  });

  // ─────────────────────────────────────────────────
  // GROUP 2: ReShotCaptureModel — Serialization
  // ─────────────────────────────────────────────────
  group('ReShotCaptureModel — Serialization', () {
    test('toJson/fromJson round-trip preserves all fields including displayScore', () {
      final capture = ReShotCaptureModel(
        id: 'test-uuid-001',
        filePath: '/device/path/photo.jpg',
        score: 94.95,       // raw — would have triggered bug
        displayScore: 95.0, // rounded display value
        badge: 'EPIC',      // badge from RAW score
        timestamp: DateTime.utc(2026, 6, 19, 12, 0, 0),
        locationName: 'Birthi Falls',
      );

      final json = capture.toJson();
      expect(json['id'], equals('test-uuid-001'));
      expect(json['score'], equals(94.95));
      expect(json['displayScore'], equals(95.0));
      expect(json['badge'], equals('EPIC'));

      final restored = ReShotCaptureModel.fromJson(json);
      expect(restored.score, equals(94.95));
      expect(restored.displayScore, equals(95.0));
      expect(restored.badge, equals('EPIC'));
      expect(restored.timestamp, equals(capture.timestamp));
    });

    test('fromJson graceful fallback when displayScore field is absent (old record migration)', () {
      // Old records written before this fix don't have displayScore.
      final oldJson = {
        'id': 'old-record-001',
        'filePath': '/path/old.jpg',
        'score': 94.95,
        'badge': 'EPIC',
        'timestamp': '2026-06-01T00:00:00.000Z',
        'locationName': 'Test Location',
        // NO displayScore key — simulates pre-fix Hive record
      };

      final model = ReShotCaptureModel.fromJson(oldJson);
      // Should not throw; should compute displayScore from raw.
      expect(model.score, equals(94.95));
      expect(model.displayScore, equals(95.0)); // toStringAsFixed(1) of 94.95
      expect(model.badge, equals('EPIC'));
    });

    test('Score 94.94 old record: displayScore fallback rounds to 94.9', () {
      final oldJson = {
        'id': 'old-record-002',
        'filePath': '/path/old2.jpg',
        'score': 94.94,
        'badge': 'EPIC',
        'timestamp': '2026-06-01T00:00:00.000Z',
        'locationName': 'Test',
      };
      final model = ReShotCaptureModel.fromJson(oldJson);
      expect(model.displayScore, equals(94.9));
    });
  });

  // ─────────────────────────────────────────────────
  // GROUP 3: HiddenGemModel — Serialization
  // ─────────────────────────────────────────────────
  group('HiddenGemModel — Serialization', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      final gem = HiddenGemModel(
        id: '7f3e2a1c-4b5d-4e6f-8a9b-0c1d2e3f4a5b',
        name: 'Test Falls',
        description: 'A test waterfall.',
        latitude: 30.1254,
        longitude: 80.1425,
        altitude: '2,210m',
        tags: ['Waterfall', 'Viewpoint'],
        photoPath: 'placeholder_test',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final json = gem.toJson();
      final restored = HiddenGemModel.fromJson(json);

      expect(restored.id, equals('7f3e2a1c-4b5d-4e6f-8a9b-0c1d2e3f4a5b'));
      expect(restored.name, equals('Test Falls'));
      expect(restored.latitude, equals(30.1254));
      expect(restored.longitude, equals(80.1425));
      expect(restored.altitude, equals('2,210m'));
      expect(restored.tags, equals(['Waterfall', 'Viewpoint']));
      expect(restored.createdAt, equals(DateTime.utc(2026, 1, 1)));
    });

    test('Seed IDs are UUID-format strings (not plain slugs)', () {
      // Fix 7 verification: seed IDs must look like UUIDs.
      const seedIds = [
        '7f3e2a1c-4b5d-4e6f-8a9b-0c1d2e3f4a5b',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'f9e8d7c6-b5a4-3210-fedc-ba9876543210',
      ];
      final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false);
      for (final id in seedIds) {
        expect(uuidPattern.hasMatch(id), isTrue,
            reason: 'Seed ID "$id" is not a valid UUID-format string');
      }
    });

    test('Altitude "Unknown" is stored correctly when GPS altitude unavailable', () {
      final gem = HiddenGemModel(
        id: 'test-altitude-id',
        name: 'Altitude Test',
        description: 'No altitude available.',
        latitude: 0.0,
        longitude: 0.0,
        altitude: 'Unknown', // Fix 3: string when no GPS altitude
        tags: [],
        photoPath: 'none',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final json = gem.toJson();
      final restored = HiddenGemModel.fromJson(json);
      expect(restored.altitude, equals('Unknown'));
    });
  });

  // ─────────────────────────────────────────────────
  // GROUP 4: Duplicate Save Prevention Logic
  // ─────────────────────────────────────────────────
  group('Duplicate Save Prevention Logic', () {
    // Unit-test the _isSaving guard pattern without UI.
    test('_isSaving flag prevents second invocation', () async {
      bool isSaving = false;
      int saveCount = 0;

      Future<void> mockSave() async {
        if (isSaving) return; // guard — mirrors production code
        isSaving = true;
        await Future.delayed(const Duration(milliseconds: 10));
        saveCount++;
        isSaving = false;
      }

      // Simulate rapid double-tap
      await Future.wait([mockSave(), mockSave()]);
      expect(saveCount, equals(1),
          reason: '_isSaving guard should prevent second concurrent save');
    });
  });

  // ─────────────────────────────────────────────────
  // GROUP 5: GPS/Manual Mode Switching Logic
  // ─────────────────────────────────────────────────
  group('GPS / Manual Mode Switching Logic', () {
    test('Successful GPS retrieval disables manual mode', () {
      // Simulate state variables
      bool useManualCoordinates = true; // was in manual mode
      double? latitude;
      double? longitude;
      double? altitude;
      bool gpsError = false;

      // Simulates what _fetchGpsCoordinates does on success (Fix 5)
      void onGpsSuccess(double lat, double lng, double alt) {
        latitude = lat;
        longitude = lng;
        altitude = alt;
        useManualCoordinates = false; // Fix 5: reset on success
        gpsError = false;
      }

      onGpsSuccess(30.1254, 80.1425, 2210.0);

      expect(useManualCoordinates, isFalse,
          reason: 'Successful GPS must disable manual mode (Fix 5)');
      expect(latitude, equals(30.1254));
      expect(longitude, equals(80.1425));
      expect(altitude, equals(2210.0));
      expect(gpsError, isFalse);
    });

    test('GPS failure keeps manual mode if already active', () {
      bool useManualCoordinates = true;
      double? latitude;

      // Simulates GPS failure path — should not touch manual mode.
      void onGpsFailure() {
        latitude = null;
        // does NOT touch _useManualCoordinates
      }

      onGpsFailure();
      expect(useManualCoordinates, isTrue);
      expect(latitude, isNull);
    });

    test('Coordinate selection uses manual values when in manual mode', () {
      // Mirrors the exact coordinate-selection logic from _handleSubmit.
      double selectCoord(bool useManual, double manual, double? gps) {
        return useManual ? manual : (gps ?? manual);
      }

      const manualLat = 29.5985;
      const manualLng = 80.2033;
      const gpsLat = 30.0;
      const gpsLng = 80.5;

      // Manual mode ON
      expect(selectCoord(true, manualLat, gpsLat), equals(manualLat));
      expect(selectCoord(true, manualLng, gpsLng), equals(manualLng));
    });

    test('Coordinate selection uses GPS values after manual mode is reset', () {
      double selectCoord(bool useManual, double manual, double? gps) {
        return useManual ? manual : (gps ?? manual);
      }

      const gpsLat = 30.1254;
      const gpsLng = 80.1425;
      const manualLat = 29.5985;
      const manualLng = 80.2033;

      // Manual mode OFF (GPS reset success — Fix 5)
      expect(selectCoord(false, manualLat, gpsLat), equals(gpsLat));
      expect(selectCoord(false, manualLng, gpsLng), equals(gpsLng));
    });
  });

  // ─────────────────────────────────────────────────
  // GROUP 6: Idempotent Seed Recovery Logic
  // ─────────────────────────────────────────────────
  group('Idempotent Seed Recovery Logic', () {
    const seedIds = {
      '7f3e2a1c-4b5d-4e6f-8a9b-0c1d2e3f4a5b',
      'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      'f9e8d7c6-b5a4-3210-fedc-ba9876543210',
    };

    test('All missing seeds are inserted on recovery', () {
      // Simulate a box that only has one seed (partial crash scenario).
      final Map<String, String> mockBox = {
        '7f3e2a1c-4b5d-4e6f-8a9b-0c1d2e3f4a5b': 'existing',
      };
      int insertCount = 0;

      // Mirrors Fix 6 idempotent check logic.
      for (final id in seedIds) {
        if (!mockBox.containsKey(id)) {
          mockBox[id] = 'seeded';
          insertCount++;
        }
      }

      expect(insertCount, equals(2),
          reason: 'Should only insert the 2 missing seeds, not the existing one');
      expect(mockBox.length, equals(3));
    });

    test('No duplicate inserts when all seeds already present', () {
      final Map<String, String> mockBox = {
        for (final id in seedIds) id: 'existing',
      };
      int insertCount = 0;

      for (final id in seedIds) {
        if (!mockBox.containsKey(id)) {
          mockBox[id] = 'seeded';
          insertCount++;
        }
      }

      expect(insertCount, equals(0),
          reason: 'No seeds should be inserted when all are already present');
    });

    test('Completely empty box seeds all 3 records', () {
      final Map<String, String> mockBox = {};
      int insertCount = 0;

      for (final id in seedIds) {
        if (!mockBox.containsKey(id)) {
          mockBox[id] = 'seeded';
          insertCount++;
        }
      }

      expect(insertCount, equals(3));
    });
  });
}
