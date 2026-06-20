class HiddenGemModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String altitude;
  final List<String> tags;
  final String photoPath;
  final DateTime createdAt;
  final String? ownerId;
  final bool isSynced;
  final String? cloudImageUrl;
  final DateTime updatedAt;

  HiddenGemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.tags,
    required this.photoPath,
    required this.createdAt,
    this.ownerId,
    this.isSynced = false,
    this.cloudImageUrl,
    required this.updatedAt,
  });

  HiddenGemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? altitude,
    List<String>? tags,
    String? photoPath,
    DateTime? createdAt,
    String? ownerId,
    bool? isSynced,
    String? cloudImageUrl,
    DateTime? updatedAt,
  }) {
    return HiddenGemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      tags: tags ?? this.tags,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
      isSynced: isSynced ?? this.isSynced,
      cloudImageUrl: cloudImageUrl ?? this.cloudImageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'tags': tags,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
      'ownerId': ownerId,
      'isSynced': isSynced,
      'cloudImageUrl': cloudImageUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HiddenGemModel.fromJson(Map<String, dynamic> json) {
    return HiddenGemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude'] as String,
      tags: List<String>.from(json['tags'] as Iterable),
      photoPath: json['photoPath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      ownerId: json['ownerId'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      cloudImageUrl: json['cloudImageUrl'] as String?,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : DateTime.parse(json['createdAt'] as String),
    );
  }
}
