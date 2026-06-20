import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile();
  Future<void> saveProfile(ProfileModel profile);
}

class HiveProfileRepository implements ProfileRepository {
  static const String _boxName = 'profile_box';
  static const String _profileKey = 'active_profile';

  Future<Box<String>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  @override
  Future<ProfileModel> getProfile() async {
    final box = await _getBox();
    final jsonString = box.get(_profileKey);
    if (jsonString == null) {
      // Create and save a default profile if none exists
      final defaultProfile = ProfileModel.defaultProfile();
      await saveProfile(defaultProfile);
      return defaultProfile;
    }
    try {
      final Map<String, dynamic> map = jsonDecode(jsonString) as Map<String, dynamic>;
      return ProfileModel.fromJson(map);
    } catch (e) {
      // Return a default profile on corruption
      return ProfileModel.defaultProfile();
    }
  }

  @override
  Future<void> saveProfile(ProfileModel profile) async {
    final box = await _getBox();
    final jsonString = jsonEncode(profile.toJson());
    await box.put(_profileKey, jsonString);
  }
}
