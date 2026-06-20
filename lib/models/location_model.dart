class LocationModel {
  final String id;
  final String name;
  final String distance;
  final String description;
  final double latitude;
  final double longitude;
  final String altitude;
  final List<String> tips;

  LocationModel({
    required this.id,
    required this.name,
    required this.distance,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.tips,
  });

  static List<LocationModel> getMockLocations() {
    return [
      LocationModel(
        id: 'birthi',
        name: 'Birthi Falls',
        distance: '54 km away',
        description: 'An underrated giant waterfall falling from 126m high. ReShot guides you to stand at the viewpoint bridge for a perfect backdrop layout matching.',
        latitude: 30.1254,
        longitude: 80.1425,
        altitude: '2,210m',
        tips: [
          'Recommended lens: Ultra-wide (16-24mm)',
          'Subject positioning: Center lower third',
          'Best light: 3:00 PM - 5:00 PM',
        ],
      ),
      LocationModel(
        id: 'chandak',
        name: 'Chandak Waterfall',
        distance: '12 km away',
        description: 'A hidden paradise surrounded by thick forests. The ideal recreation angle requires shooting from a low height, looking upwards with a 35mm lens.',
        latitude: 29.5985,
        longitude: 80.2033,
        altitude: '1,850m',
        tips: [
          'Recommended lens: Portrait (35-50mm)',
          'Subject positioning: Left rule of thirds line',
          'Best light: Golden hour (5:30 PM - 6:30 PM)',
        ],
      ),
      LocationModel(
        id: 'sasling',
        name: 'Sasling Cascade',
        distance: '28 km away',
        description: "Tucked away from commercial travel routes. ReShot's scene recognition identifies this spot instantly and guides you on composition framing.",
        latitude: 29.6241,
        longitude: 80.1255,
        altitude: '1,420m',
        tips: [
          'Recommended lens: Standard zoom (24-70mm)',
          'Subject positioning: Sitting on lower right rock',
          'Best light: Overcast or midday for forest shade',
        ],
      ),
    ];
  }
}
