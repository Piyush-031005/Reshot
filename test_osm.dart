import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String overpassUrl = 'https://overpass-api.de/api/interpreter';
  
  // Bennett University roughly: 28.4503, 77.0264
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
      body: {'data': query},
    );
    print('Status: $');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Elements: $');
      if (data['elements'] != null && data['elements'].isNotEmpty) {
        final firstMatch = data['elements'][0];
        print('First match: $firstMatch');
      } else {
        print('No elements found.');
      }
    } else {
      print('Body: $');
    }
  } catch (e) {
    print('Error: $e');
  }
}
