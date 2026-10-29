class TripMember {
  final String memberId;
  final String displayName;
  final String avatar;
  final String color;
  double? lat;
  double? lng;
  bool isActive;
  DateTime? lastSeen;

  TripMember({
    required this.memberId,
    required this.displayName,
    required this.avatar,
    required this.color,
    this.lat,
    this.lng,
    this.isActive = true,
    this.lastSeen,
  });

  factory TripMember.fromJson(Map<String, dynamic> json) {
    return TripMember(
      memberId: json['member_id'] as String,
      displayName: json['display_name'] as String,
      avatar: json['avatar'] as String? ?? 'bike',
      color: json['color'] as String? ?? '#FF6B35',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'member_id': memberId,
        'display_name': displayName,
        'avatar': avatar,
        'color': color,
        'lat': lat,
        'lng': lng,
        'is_active': isActive,
      };

  TripMember copyWith({
    double? lat,
    double? lng,
    bool? isActive,
    String? displayName,
    String? avatar,
    String? color,
  }) {
    return TripMember(
      memberId: memberId,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      color: color ?? this.color,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isActive: isActive ?? this.isActive,
    );
  }
}
