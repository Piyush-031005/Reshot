import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/reshot_capture_model.dart';

abstract class GalleryRepository {
  Future<List<ReShotCaptureModel>> getCaptures();
  Future<void> saveCapture(ReShotCaptureModel capture);
}

class HiveGalleryRepository implements GalleryRepository {
  static const String _boxName = 'reshot_captures_box';

  Future<Box<String>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return await Hive.openBox<String>(_boxName);
  }

  @override
  Future<List<ReShotCaptureModel>> getCaptures() async {
    final box = await _getBox();
    final List<ReShotCaptureModel> list = [];
    
    for (var key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonString) as Map<String, dynamic>;
          list.add(ReShotCaptureModel.fromJson(map));
        } catch (e) {
          // Gracefully skip corrupted records
          continue;
        }
      }
    }
    
    // Sort captures by timestamp descending (newest first)
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<void> saveCapture(ReShotCaptureModel capture) async {
    final box = await _getBox();
    final jsonString = jsonEncode(capture.toJson());
    await box.put(capture.id, jsonString);
  }
}
