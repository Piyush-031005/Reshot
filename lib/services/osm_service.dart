import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OSMService {
  // Free Overpass API endpoint
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Searches OpenStreetMap for nearby features based on ML Kit labels.
  /// Example label: 'waterfall', 'mountain', 'park'.
  Future<Map<String, dynamic>?> findSimilarNearby(List<String> labels, double lat, double lon) async {
    if (labels.isEmpty) return null;

    // Map general labels to OSM tags
    String tagQuery = '';
    for (String label in labels) {
      String l = label.toLowerCase();
      if (l.contains('waterfall')) {
        tagQuery = 'node["waterway"="waterfall"]';
        break;
      } else if (l.contains('mountain') || l.contains('peak')) {
        tagQuery = 'node["natural"="peak"]';
        break;
      } else if (l.contains('park') || l.contains('nature')) {
        tagQuery = 'node["leisure"="park"]';
        break;
      }
    }

    if (tagQuery.isEmpty) {
      // Default to finding a viewpoint or tourism spot if we don't have a specific tag mapping
      tagQuery = 'node["tourism"="viewpoint"]';
    }

    // Search within 50km radius
    final radius = 50000;
    
    // Overpass QL query
    final query = '''
      [out:json][timeout:25];
      (
        $tagQuery(around:$radius,$lat,$lon);
      );
      out body;
      >;
      out skel qt;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['elements'] != null && data['elements'].isNotEmpty) {
          // Return the first match
          final firstMatch = data['elements'][0];
          String name = firstMatch['tags']?['name'] ?? 'Similar Location found via OpenStreetMap';
          
          return {
            'name': name,
            'lat': firstMatch['lat'],
            'lon': firstMatch['lon'],
          };
        }
      } else {
        debugPrint('OSM Overpass API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OSMService error: $e');
    }
    
    return null;
  }
}
