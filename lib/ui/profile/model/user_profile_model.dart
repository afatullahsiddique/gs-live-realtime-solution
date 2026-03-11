class UserProfileResponse {
  final bool status;
  final int statusCode;
  final String message;
  final UserData data;

  UserProfileResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      status: json['status'],
      statusCode: json['statusCode'],
      message: json['message'],
      data: UserData.fromJson(json['data']),
    );
  }
}

class UserData {
  final User user;

  UserData({required this.user});

  factory UserData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('user')) {
      return UserData(user: User.fromJson(json['user']));
    }
    return UserData(user: User.fromJson(json));
  }
}

class User {
  final String id;
  final String? name;
  final String? email;
  final List<String>? photoUrls;
  final String? phone;
  final String? gender;
  final String? role;
  final DateTime? createdAt;
  final Host? host;
  final LevelInfo? levelInfo;
  final String? token;

  User({
    required this.id,
    this.name,
    this.email,
    this.photoUrls,
    this.phone,
    this.gender,
    this.role,
    this.createdAt,
    this.host,
    this.levelInfo,
    this.token,
  });

  String? get photoUrl => (photoUrls != null && photoUrls!.isNotEmpty) ? photoUrls![0] : null;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'],
      email: json['email'],
      photoUrls: json['photoUrl'] is List
          ? List<String>.from(json['photoUrl'])
          : json['photoUrl'] is String
              ? [json['photoUrl']]
              : [],
      phone: json['phone'],
      gender: json['gender'],
      role: json['role'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      host: (json['Host'] != null) ? Host.fromJson(json['Host']) : (json['host'] != null ? Host.fromJson(json['host']) : null),
      levelInfo: json['levelInfo'] != null
          ? LevelInfo.fromJson(json['levelInfo'])
          : null,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrls,
      'phone': phone,
      'gender': gender,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'host': host?.toJson(),
      'levelInfo': levelInfo?.toJson(),
      'token': token, // ✅ add this
    };
  }
}

class Host {
  final String? displayId;
  final String? displayName;
  final String? bio;
  final String? hostStatus;
  final String country;
  final String agencyCode;
  final String countryFlagEmoji;
  final int followerCount;
  final int followingCount;
  final int balance;
  final int diamonds;
  final int visitorCount;
  final int totalEarned;

  final List<Tag>? myTags;

  Host({
    this.displayId,
    this.displayName,
    this.bio,
    this.hostStatus,
    required this.country,
    required this.agencyCode,
    required this.countryFlagEmoji,
    required this.followerCount,
    required this.followingCount,
    required this.balance,
    required this.diamonds,
    required this.visitorCount,
    required this.totalEarned,
    this.myTags,
  });

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      displayId: json['displayId'],
      displayName: json['displayName'],
      bio: json['bio'],
      hostStatus: json['hostStatus'],
      country: json['country'] ?? '',
      agencyCode: json['agencyCode'] ?? '',
      countryFlagEmoji: json['countryFlagEmoji'] ?? '',
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      balance: json['balance'] ?? 0,
      diamonds: json['diamonds'] ?? 0,
      visitorCount: json['visitorCount'] ?? 0,
      totalEarned: json['totalEarned'] ?? 0,
      myTags: json['myTags'] != null
          ? (json['myTags'] as List).map((i) => Tag.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayId': displayId,
      'displayName': displayName,
      'bio': bio,
      'hostStatus': hostStatus,
      'country': country,
      'agencyCode': agencyCode,
      'countryFlagEmoji': countryFlagEmoji,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'balance': balance,
      'diamonds': diamonds,
      'visitorCount': visitorCount,
      'totalEarned': totalEarned,
    };
  }
}

class LevelInfo {
  final int progress;
  final int coinsToNextLevel;
  final bool isLevelActive;
  final int? currentLevel;
  final int? highestLevel;
  final int? nextLevel;
  final String? warning;

  LevelInfo({
    required this.progress,
    required this.coinsToNextLevel,
    required this.isLevelActive,
    this.currentLevel,
    this.highestLevel,
    this.nextLevel,
    this.warning,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> json) {
    return LevelInfo(
      progress: json['progress'] ?? 0,
      coinsToNextLevel: json['coinsToNextLevel'] ?? 0,
      isLevelActive: json['isLevelActive'] ?? false,
      currentLevel: json['currentLevel'],
      highestLevel: json['highestLevel'],
      nextLevel: json['nextLevel'],
      warning: json['warning'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progress': progress,
      'coinsToNextLevel': coinsToNextLevel,
      'isLevelActive': isLevelActive,
      'currentLevel': currentLevel,
      'highestLevel': highestLevel,
      'nextLevel': nextLevel,
      'warning': warning,
    };
  }
}

class Tag {
  final String id;
  final String name;
  final String? category;

  Tag({required this.id, required this.name, this.category});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (category != null) 'category': category,
    };
  }
}

