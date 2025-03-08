// lib/models/background_image.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BackgroundImage {
  final String? id;
  final String imageUrl;
  final DateTime timestamp;
  final String userId;
  final String? userName; // Add userName field
  final String? userEmail; // Add userEmail field
  final String? uploadedVia; // Add uploadedVia field
  final bool isLoading;
  final bool? active;

  BackgroundImage({
    this.id,
    required this.imageUrl,
    required this.timestamp,
    this.userId = '', // Make userId optional with default empty string
    this.userName,
    this.userEmail,
    this.uploadedVia,
    this.isLoading = false,
    this.active = true,
  });

  factory BackgroundImage.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) {
        return DateTime.now();
      } else if (timestamp is DateTime) {
        return timestamp;
      } else if (timestamp is Timestamp) {
        // Convert Firebase Timestamp to DateTime
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return DateTime.now();
    }

    return BackgroundImage(
      id: id,
      imageUrl: json['imageUrl'] ?? '',
      timestamp: parseTimestamp(json['timestamp']),
      userId: json['userId'] ?? '',
      userName: json['userName'],
      userEmail: json['userEmail'],
      uploadedVia: json['uploadedVia'],
      isLoading: json['isLoading'] ?? false,
      active: json['active'],
    );
  }
}
