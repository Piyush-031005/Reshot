import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ml_kit_service.dart';
import '../services/osm_service.dart';

enum EngineState { idle, analyzing, success, error }

class FindraEngineProvider extends ChangeNotifier {
  final MLKitService _mlKitService = MLKitService();
  final OSMService _osmService = OSMService();

  EngineState _state = EngineState.idle;
  EngineState get state => _state;

  List<String> _detectedLabels = [];
  List<String> get detectedLabels => _detectedLabels;

  String? _resultName;
  String? get resultName => _resultName;

  double? _resultLat;
  double? get resultLat => _resultLat;

  double? _resultLon;
  double? get resultLon => _resultLon;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> processPhoto(String imagePath) async {
    _state = EngineState.analyzing;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. ML Kit Local Analysis
      _detectedLabels = await _mlKitService.analyzeImage(imagePath);
      
      if (_detectedLabels.isEmpty) {
        _state = EngineState.error;
        _errorMessage = "Could not identify any features in the photo.";
        notifyListeners();
        return;
      }

      // 2. Get Current Location (Defaulting to Pithoragarh for testing if permission fails)
      double lat = 29.5829;
      double lon = 80.2182;
      
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition();
          lat = position.latitude;
          lon = position.longitude;
        }
      } catch (e) {
        debugPrint('Geolocator error, using default location: $e');
      }

      // 3. Search OpenStreetMap for similar nearby locations
      final place = await _osmService.findSimilarNearby(_detectedLabels, lat, lon);

      if (place != null) {
        _resultName = place['name'];
        _resultLat = place['lat'];
        _resultLon = place['lon'];
        _state = EngineState.success;
      } else {
        _state = EngineState.error;
        _errorMessage = "Detected ${_detectedLabels.join(', ')} but couldn't find a similar spot nearby.";
      }
    } catch (e) {
      _state = EngineState.error;
      _errorMessage = "An error occurred during analysis.";
      debugPrint('FindraEngineProvider error: $e');
    }

    notifyListeners();
  }

  void reset() {
    _state = EngineState.idle;
    _detectedLabels = [];
    _resultName = null;
    _resultLat = null;
    _resultLon = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _mlKitService.dispose();
    super.dispose();
  }
}
