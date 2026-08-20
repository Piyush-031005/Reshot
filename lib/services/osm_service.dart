import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;

class OSMService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  Future<Map<String, dynamic>?> findSimilarNearby(List<String> labels, double lat, double lon) async {
    if (labels.isEmpty) return {'name': 'Unknown Location (API Failed)', 'lat': lat, 'lon': lon};

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
      out center 1;
    ''';

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
        } else {
           return await _reverseGeocodeFallback(lat, lon);
        }
      } else {
        debugPrint('OSM Overpass API error: ${response.statusCode}');
        return await _reverseGeocodeFallback(lat, lon);
      }
    } catch (e) {
      debugPrint('OSMService error: $e');
      return await _reverseGeocodeFallback(lat, lon);
    }
    
    return {'name': 'Unknown Location (API Failed)', 'lat': lat, 'lon': lon};
  }

  // Backup system: Uses Native Geocoding if Overpass fails
  Future<Map<String, dynamic>?> _reverseGeocodeFallback(double lat, double lon) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks.first;
        String finalName = place.name ?? place.street ?? place.subLocality ?? place.locality ?? 'Unknown Location';
        return {
          'name': finalName,
          'lat': lat,
          'lon': lon,
        };
      }
    } catch (e) {
      debugPrint('Native geocoding error: $e');
    }
    return {'name': 'Unknown Location (Offline)', 'lat': lat, 'lon': lon};
  }
}







