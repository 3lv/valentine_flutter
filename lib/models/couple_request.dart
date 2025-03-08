// lib/models/couple_request.dart
class CoupleRequest {
  final String id;
  final String fromUserId;
  final String fromUserEmail;
  final String fromUserDisplayName;
  final String toUserId;
  final String toUserEmail;
  final String toUserDisplayName;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime timestamp;

  CoupleRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserEmail,
    required this.fromUserDisplayName,
    required this.toUserId,
    required this.toUserEmail,
    required this.toUserDisplayName,
    required this.status,
    required this.timestamp,
  });

  factory CoupleRequest.fromJson(Map<String, dynamic> json, String id) {
    return CoupleRequest(
      id: id,
      fromUserId: json['fromUserId'] ?? '',
      fromUserEmail: json['fromUserEmail'] ?? '',
      fromUserDisplayName: json['fromUserDisplayName'] ?? '',
      toUserId: json['toUserId'] ?? '',
      toUserEmail: json['toUserEmail'] ?? '',
      toUserDisplayName: json['toUserDisplayName'] ?? '',
      status: json['status'] ?? 'pending',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'fromUserId': fromUserId,
        'fromUserEmail': fromUserEmail,
        'fromUserDisplayName': fromUserDisplayName,
        'toUserId': toUserId,
        'toUserEmail': toUserEmail,
        'toUserDisplayName': toUserDisplayName,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };
}
