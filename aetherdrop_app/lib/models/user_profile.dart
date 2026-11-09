/// User profile model for AetherDrop nodes.
///
/// Matches the schema of Supabase's `public.profiles` table.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarId = 'starter_cyber_01',
    this.frameId = 'frame_slate_01',
    this.xp = 0,
    this.level = 1,
    this.totalBytesSent = 0,
    this.totalFilesSent = 0,
    this.unlockedAvatars = const <String>[
      'starter_cyber_01',
      'starter_cyber_02',
      'starter_cyber_03',
      'starter_cyber_04',
    ],
    this.unlockedBadges = const <String>['badge_first_node'],
    this.isOnline = true,
    required this.lastSeen,
    this.createdAt,
  });

  /// Unique UUID of the authenticated user (matches `auth.users.id`).
  final String id;

  /// User's registered email address.
  final String email;

  /// User's display name or handle shown to peers.
  final String displayName;

  /// Currently active Cyber Avatar identifier.
  final String avatarId;

  /// Active glowing cosmetic frame ring identifier.
  final String frameId;

  /// Total Warp XP accumulated across transfers.
  final int xp;

  /// Current progression level (`floor(sqrt(xp / 25))`).
  final int level;

  /// Total cumulative bytes beamed directly to peers.
  final int totalBytesSent;

  /// Total count of individual files transferred.
  final int totalFilesSent;

  /// List of avatar identifiers unlocked by progression.
  final List<String> unlockedAvatars;

  /// List of badge identifiers earned.
  final List<String> unlockedBadges;

  /// Whether the node is currently connected and active.
  final bool isOnline;

  /// Timestamp of the last peer transfer or heartbeat.
  final DateTime lastSeen;

  /// Optional profile creation timestamp.
  final DateTime? createdAt;

  /// Deserializes a [UserProfile] from a Supabase `public.profiles` row.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Warp Explorer',
      avatarId: json['avatar_id'] as String? ?? 'starter_cyber_01',
      frameId: json['frame_id'] as String? ?? 'frame_slate_01',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      totalBytesSent: (json['total_bytes_sent'] as num?)?.toInt() ?? 0,
      totalFilesSent: (json['total_files_sent'] as num?)?.toInt() ?? 0,
      unlockedAvatars: (json['unlocked_avatars'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[
            'starter_cyber_01',
            'starter_cyber_02',
            'starter_cyber_03',
            'starter_cyber_04',
          ],
      unlockedBadges: (json['unlocked_badges'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>['badge_first_node'],
      isOnline: json['is_online'] as bool? ?? true,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Serializes this profile into a JSON map matching `public.profiles`.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_id': avatarId,
      'frame_id': frameId,
      'xp': xp,
      'level': level,
      'total_bytes_sent': totalBytesSent,
      'total_files_sent': totalFilesSent,
      'unlocked_avatars': unlockedAvatars,
      'unlocked_badges': unlockedBadges,
      'is_online': isOnline,
      'last_seen': lastSeen.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Returns a copy of this [UserProfile] with the given fields replaced.
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarId,
    String? frameId,
    int? xp,
    int? level,
    int? totalBytesSent,
    int? totalFilesSent,
    List<String>? unlockedAvatars,
    List<String>? unlockedBadges,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarId: avatarId ?? this.avatarId,
      frameId: frameId ?? this.frameId,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      totalBytesSent: totalBytesSent ?? this.totalBytesSent,
      totalFilesSent: totalFilesSent ?? this.totalFilesSent,
      unlockedAvatars: unlockedAvatars ?? this.unlockedAvatars,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Human-readable formatted string of total bytes beamed.
  String get formattedBytesSent {
    if (totalBytesSent < 1024) return '$totalBytesSent B';
    if (totalBytesSent < 1024 * 1024) {
      return '${(totalBytesSent / 1024).toStringAsFixed(1)} KB';
    }
    if (totalBytesSent < 1024 * 1024 * 1024) {
      return '${(totalBytesSent / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalBytesSent / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Whether the user has unlocked the avatar with [avatarId].
  bool hasAvatar(String targetAvatarId) {
    return unlockedAvatars.contains(targetAvatarId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.avatarId == avatarId &&
        other.frameId == frameId &&
        other.xp == xp &&
        other.level == level &&
        other.totalBytesSent == totalBytesSent &&
        other.totalFilesSent == totalFilesSent &&
        other.isOnline == isOnline;
  }

  @override
  int get hashCode => Object.hash(
        id,
        email,
        displayName,
        avatarId,
        frameId,
        xp,
        level,
        totalBytesSent,
        totalFilesSent,
        isOnline,
      );

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, displayName: $displayName, '
        'avatarId: $avatarId, level: $level, xp: $xp, isOnline: $isOnline)';
  }
}

