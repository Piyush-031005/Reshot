import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MLKitService {
  final ImageLabeler _imageLabeler;

  MLKitService()
      : _imageLabeler = ImageLabeler(options: ImageLabelerOptions());

  Future<List<String>> analyzeImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);
      
      List<String> detectedLabels = [];
      for (ImageLabel label in labels) {
        if (label.confidence > 0.6) {
          detectedLabels.add(label.label);
          debugPrint('MLKit Detected: ${label.label} (Confidence: ${label.confidence})');
        }
      }
      return detectedLabels;
    } catch (e) {
      debugPrint('Error in MLKitService.analyzeImage: $e');
      return [];
    }
  }

  void dispose() {
    _imageLabeler.close();
  }
}

