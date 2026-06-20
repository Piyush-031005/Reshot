class ProfileModel {
  final String explorerName;
  final int xp;
  final DateTime joinDate;
  final List<String> unlockedAchievementIds;
  final String? ownerId;
  final bool isSynced;
  final DateTime updatedAt;

  ProfileModel({
    required this.explorerName,
    required this.xp,
    required this.joinDate,
    required this.unlockedAchievementIds,
    this.ownerId,
    this.isSynced = false,
    required this.updatedAt,
  });

  factory ProfileModel.defaultProfile() {
    return ProfileModel(
      explorerName: 'EXPLORER_007',
      xp: 0,
      joinDate: DateTime.now(),
      unlockedAchievementIds: const [],
      ownerId: null,
      isSynced: false,
      updatedAt: DateTime.now(),
    );
  }

  ProfileModel copyWith({
    String? explorerName,
    int? xp,
    DateTime? joinDate,
    List<String>? unlockedAchievementIds,
    String? ownerId,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      explorerName: explorerName ?? this.explorerName,
      xp: xp ?? this.xp,
      joinDate: joinDate ?? this.joinDate,
      unlockedAchievementIds: unlockedAchievementIds ?? this.unlockedAchievementIds,
      ownerId: ownerId ?? this.ownerId,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'explorerName': explorerName,
      'xp': xp,
      'joinDate': joinDate.toIso8601String(),
      'unlockedAchievementIds': unlockedAchievementIds,
      'ownerId': ownerId,
      'isSynced': isSynced,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      explorerName: json['explorerName'] as String? ?? 'EXPLORER_007',
      xp: json['xp'] as int? ?? 0,
      joinDate: json['joinDate'] != null 
          ? DateTime.parse(json['joinDate'] as String) 
          : DateTime.now(),
      unlockedAchievementIds: json['unlockedAchievementIds'] != null
          ? List<String>.from(json['unlockedAchievementIds'] as Iterable)
          : const [],
      ownerId: json['ownerId'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : (json['joinDate'] != null ? DateTime.parse(json['joinDate'] as String) : DateTime.now()),
    );
  }
}
