import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String overpassUrl = 'https://overpass-api.de/api/interpreter';
  
  double lat = 28.4503;
  double lon = 77.0264;
  int radius = 10000;
  String tagQuery = 'nwr["amenity"="university"]';

  final query = '''
    [out:json][timeout:25];
    (
      $tagQuery(around:$radius,$lat,$lon);
    );
    out center;
  ''';

  print('Querying...');
  try {
    final response = await http.post(
      Uri.parse(overpassUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'FindraApp/1.0 (test@example.com)'
      },
      body: {'data': query},
    );
    print('Status: $');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Elements: $');
    } else {
      print('Error body: $');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
