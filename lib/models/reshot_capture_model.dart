class ReShotCaptureModel {
  final String id;
  final String filePath;
  /// Raw unrounded score — used for badge classification.
  final double score;
  /// Rounded to 1dp — used for display in the UI only.
  final double displayScore;
  final String badge;
  final DateTime timestamp;
  final String locationName;
  final String? ownerId;
  final bool isSynced;
  final String? cloudImageUrl;
  final DateTime updatedAt;

  ReShotCaptureModel({
    required this.id,
    required this.filePath,
    required this.score,
    required this.displayScore,
    required this.badge,
    required this.timestamp,
    required this.locationName,
    this.ownerId,
    this.isSynced = false,
    this.cloudImageUrl,
    required this.updatedAt,
  });

  ReShotCaptureModel copyWith({
    String? id,
    String? filePath,
    double? score,
    double? displayScore,
    String? badge,
    DateTime? timestamp,
    String? locationName,
    String? ownerId,
    bool? isSynced,
    String? cloudImageUrl,
    DateTime? updatedAt,
  }) {
    return ReShotCaptureModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      score: score ?? this.score,
      displayScore: displayScore ?? this.displayScore,
      badge: badge ?? this.badge,
      timestamp: timestamp ?? this.timestamp,
      locationName: locationName ?? this.locationName,
      ownerId: ownerId ?? this.ownerId,
      isSynced: isSynced ?? this.isSynced,
      cloudImageUrl: cloudImageUrl ?? this.cloudImageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'score': score,
      'displayScore': displayScore,
      'badge': badge,
      'timestamp': timestamp.toIso8601String(),
      'locationName': locationName,
      'ownerId': ownerId,
      'isSynced': isSynced,
      'cloudImageUrl': cloudImageUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReShotCaptureModel.fromJson(Map<String, dynamic> json) {
    final rawScore = (json['score'] as num).toDouble();
    return ReShotCaptureModel(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      score: rawScore,
      // Graceful fallback: if displayScore not present (old records), round from raw.
      displayScore: json['displayScore'] != null
          ? (json['displayScore'] as num).toDouble()
          : double.parse(rawScore.toStringAsFixed(1)),
      badge: json['badge'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      locationName: json['locationName'] as String,
      ownerId: json['ownerId'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      cloudImageUrl: json['cloudImageUrl'] as String?,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : DateTime.parse(json['timestamp'] as String),
    );
  }
}
