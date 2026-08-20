import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class OSMService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  Future<List<Map<String, dynamic>>> findSimilarNearby(List<String> labels, double lat, double lon) async {
    if (labels.isEmpty) return [];

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
        tagQuery = 'nwr["amenity"="university"]'; 
        radius = 10000;
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
      tagQuery = 'nwr["name"]';
      radius = 2000;
    }
    
    final query = '''
      [out:json][timeout:25];
      (
        $tagQuery(around:$radius,$lat,$lon);
      );
      out center 10;
    ''';

    List<Map<String, dynamic>> results = [];

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'FindraApp/1.0 (piyush@example.com)'
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['elements'] != null && data['elements'].isNotEmpty) {
          for (var element in data['elements']) {
            String name = element['tags']?['name'] ?? 'Unknown Location';
            double? elementLat = element['lat'] ?? element['center']?['lat'];
            double? elementLon = element['lon'] ?? element['center']?['lon'];
            
            if (elementLat != null && elementLon != null && name != 'Unknown Location') {
              double distance = Geolocator.distanceBetween(lat, lon, elementLat, elementLon);
              results.add({
                'name': name,
                'lat': elementLat,
                'lon': elementLon,
                'distance': distance,
              });
            }
          }
          
          // Sort ascending by distance
          results.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
        }
      } else {
        debugPrint('OSM Overpass API error: $');
      }
    } catch (e) {
      debugPrint('OSMService error: $e');
    }
    
    return results;
  }
}
