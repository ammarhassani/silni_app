/// Type of freeze action
enum FreezeType {
  earned('earned', 'مكتسب'),
  purchased('purchased', 'مشترى'),
  autoUsed('auto_used', 'استخدم تلقائياً'),
  manualUsed('manual_used', 'استخدم يدوياً');

  final String value;
  final String arabicName;

  const FreezeType(this.value, this.arabicName);

  static FreezeType fromString(String value) {
    return FreezeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FreezeType.earned,
    );
  }
}

/// User's freeze inventory
class FreezeInventory {
  final String id;
  final String userId;
  final int freezeCount;
  final int freezesUsedTotal;
  final DateTime? lastEarnedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FreezeInventory({
    required this.id,
    required this.userId,
    required this.freezeCount,
    required this.freezesUsedTotal,
    this.lastEarnedAt,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if user has any available freezes
  bool get hasFreeze => freezeCount > 0;

  /// Create from Supabase JSON
  factory FreezeInventory.fromJson(Map<String, dynamic> json) {
    return FreezeInventory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      freezeCount: json['freeze_count'] as int? ?? 0,
      freezesUsedTotal: json['freezes_used_total'] as int? ?? 0,
      lastEarnedAt: json['last_earned_at'] != null
          ? DateTime.parse(json['last_earned_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Empty inventory for new users
  factory FreezeInventory.empty(String userId) {
    return FreezeInventory(
      id: '',
      userId: userId,
      freezeCount: 0,
      freezesUsedTotal: 0,
      createdAt: DateTime.now(),
    );
  }

  /// Copy with method
  FreezeInventory copyWith({
    String? id,
    String? userId,
    int? freezeCount,
    int? freezesUsedTotal,
    DateTime? lastEarnedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FreezeInventory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      freezeCount: freezeCount ?? this.freezeCount,
      freezesUsedTotal: freezesUsedTotal ?? this.freezesUsedTotal,
      lastEarnedAt: lastEarnedAt ?? this.lastEarnedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Record of freeze usage
class FreezeUsage {
  final String id;
  final String userId;
  final FreezeType freezeType;
  final int? streakAtTime;
  final String? relativeId;
  final String? source;
  final DateTime createdAt;

  FreezeUsage({
    required this.id,
    required this.userId,
    required this.freezeType,
    this.streakAtTime,
    this.relativeId,
    this.source,
    required this.createdAt,
  });

  /// Create from Supabase JSON
  factory FreezeUsage.fromJson(Map<String, dynamic> json) {
    return FreezeUsage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      freezeType: FreezeType.fromString(json['freeze_type'] as String),
      streakAtTime: json['streak_at_time'] as int?,
      relativeId: json['relative_id'] as String?,
      source: json['source'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Get display message for freeze usage (Arabic)
  String get displayMessage {
    switch (freezeType) {
      case FreezeType.earned:
        return 'حصلت على حماية شعلة من $source';
      case FreezeType.purchased:
        return 'اشتريت حماية شعلة';
      case FreezeType.autoUsed:
        return 'تم استخدام حماية الشعلة تلقائياً';
      case FreezeType.manualUsed:
        return 'استخدمت حماية الشعلة';
    }
  }
}

/// Milestones that award freezes
class FreezeMilestones {
  /// Fallback milestones if config not loaded
  static const List<int> _fallbackMilestones = [7, 30, 100];

  /// Get milestones - uses fallback for now, will be connected to admin config
  /// The actual milestones are configurable via admin_streak_config table
  static List<int> get awardMilestones => _fallbackMilestones;

  /// Check if streak qualifies for a freeze award
  static bool isFreezeAwardMilestone(int streak) {
    return awardMilestones.contains(streak);
  }

  /// Get the source string for a milestone
  static String getSourceForMilestone(int streak) {
    return 'milestone_$streak';
  }
}
