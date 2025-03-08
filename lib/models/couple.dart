// lib/models/couple.dart
class Couple {
  final String id;
  final String name;
  final String description;
  final DateTime anniversary;
  final List<CoupleUser> members;
  final List<ApiKey>? apiKeys;

  Couple({
    required this.id,
    required this.name,
    required this.description,
    required this.anniversary,
    required this.members,
    this.apiKeys,
  });

  factory Couple.fromJson(Map<String, dynamic> json, String id) {
    List<CoupleUser> membersList = [];
    if (json['members'] != null) {
      membersList = (json['members'] as List)
          .map((member) => CoupleUser.fromJson(member))
          .toList();
    }

    List<ApiKey>? apiKeysList;
    if (json['apiKeys'] != null) {
      apiKeysList =
          (json['apiKeys'] as List).map((key) => ApiKey.fromJson(key)).toList();
    }

    return Couple(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      anniversary: json['anniversary'] != null
          ? DateTime.parse(json['anniversary'])
          : DateTime.now(),
      members: membersList,
      apiKeys: apiKeysList,
    );
  }
}

class CoupleUser {
  final String id;
  final String email;
  final String displayName;

  CoupleUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  factory CoupleUser.fromJson(Map<String, dynamic> json) {
    return CoupleUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
    );
  }
}

class ApiKey {
  final String id;
  final String name;
  final String key;
  final DateTime createdAt;
  final DateTime? lastUsed;

  ApiKey({
    required this.id,
    required this.name,
    required this.key,
    required this.createdAt,
    this.lastUsed,
  });

  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      key: json['key'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastUsed:
          json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
    );
  }
}
