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
    int radius = 50000;
    
    for (String label in labels) {
      String l = label.toLowerCase();
      if (l.contains('waterfall')) {
        tagQuery = 'nwr["waterway"="waterfall"]';
        break;
      } else if (l.contains('mountain') || l.contains('peak') || l.contains('hill')) {
        tagQuery = 'nwr["natural"="peak"]';
        break;
      } else if (l.contains('park') || l.contains('nature') || l.contains('tree') || l.contains('plant')) {
        tagQuery = 'nwr["leisure"="park"]';
        break;
      } else if (l.contains('temple') || l.contains('shrine') || l.contains('church') || l.contains('religion')) {
        tagQuery = 'nwr["amenity"="place_of_worship"]';
        radius = 20000;
        break;
      } else if (l.contains('cafe') || l.contains('coffee') || l.contains('restaurant') || l.contains('food')) {
        tagQuery = 'nwr["amenity"~"cafe|restaurant"]';
        radius = 10000;
        break;
      } else if (l.contains('building') || l.contains('skyscraper') || l.contains('skyline') || l.contains('university') || l.contains('office')) {
        tagQuery = 'nwr["amenity"="university"]'; // specifically looking for university/college nearby if building is detected
        radius = 10000; // 10km radius
        break;
      } else if (l.contains('water') || l.contains('river') || l.contains('lake')) {
        tagQuery = 'nwr["water"]';
        radius = 15000;
        break;
      } else if (l.contains('bridge')) {
        tagQuery = 'nwr["bridge"="yes"]';
        radius = 10000;
        break;
      }
    }

    if (tagQuery.isEmpty) {
      // Ultimate fallback: Just find ANY named feature (amenity, building, or place) within 2km
      tagQuery = 'nwr["name"]';
      radius = 2000;
    }
    
    // Overpass QL query
    final query = '''
      [out:json][timeout:25];
      (
        $tagQuery(around:$radius,$lat,$lon);
      );
      out center 1; // Limit to 1 result for speed and safety
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'FindraApp/1.0 (piyush@example.com)'
        },
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['elements'] != null && data['elements'].isNotEmpty) {
          // Return the first match
          final firstMatch = data['elements'][0];
          String name = firstMatch['tags']?['name'] ?? 'Similar Location found via OpenStreetMap';
          
          double? elementLat = firstMatch['lat'] ?? firstMatch['center']?['lat'];
          double? elementLon = firstMatch['lon'] ?? firstMatch['center']?['lon'];
          
          if (elementLat != null && elementLon != null) {
            return {
              'name': name,
              'lat': elementLat,
              'lon': elementLon,
            };
          }
        }
      } else {
        debugPrint('OSM Overpass API error: $response.statusCode');
      }
    } catch (e) {
      debugPrint('OSMService error: $e');
    }
    
    return null;
  }
}
