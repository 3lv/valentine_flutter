// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:valentine_flutter/models/couple.dart';
import 'package:valentine_flutter/models/couple_request.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's couple data
  Stream<Couple?> getCoupleStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      final coupleId = userDoc.data()?['coupleId'];

      if (coupleId != null) {
        final coupleDoc =
            await _firestore.collection('couples').doc(coupleId).get();

        if (coupleDoc.exists) {
          return Couple.fromJson(coupleDoc.data()!, coupleDoc.id);
        }
      }
      return null;
    });
  }

  // Get incoming couple requests
  Stream<List<CoupleRequest>> getIncomingRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('coupleRequests')
        .where('toUserEmail', isEqualTo: user.email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CoupleRequest.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Get outgoing couple requests
  Stream<List<CoupleRequest>> getOutgoingRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('coupleRequests')
        .where('fromUserEmail', isEqualTo: user.email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CoupleRequest.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Send couple invitation
  Future<void> sendInvitation(String partnerEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (partnerEmail.isEmpty || partnerEmail == user.email) {
      throw Exception('Please enter a valid email address');
    }

    await _firestore.collection('coupleRequests').add({
      'fromUserId': user.uid,
      'fromUserEmail': user.email,
      'fromUserDisplayName':
          user.displayName ?? user.email?.split('@')[0] ?? '',
      'toUserEmail': partnerEmail,
      'toUserId': '',
      'toUserDisplayName': partnerEmail.split('@')[0],
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Accept couple request
  Future<void> acceptRequest(CoupleRequest request) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('coupleRequests').doc(request.id).update({
      'toUserId': user.uid,
      'toUserDisplayName': user.displayName ?? user.email?.split('@')[0] ?? '',
      'status': 'accepted',
    });
    // Firebase Cloud Functions will handle creating the couple
  }

  // Reject couple request
  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('coupleRequests').doc(requestId).delete();
  }

  // Update couple details
  Future<void> updateCoupleDetails(String coupleId, String name,
      String description, DateTime anniversary) async {
    await _firestore.collection('couples').doc(coupleId).update({
      'name': name,
      'description': description,
      'anniversary': anniversary.toIso8601String(),
    });
  }

  // Create API key request
  Future<void> requestApiKey(String coupleId, String keyName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('pendingApiKeys')
        .add({
      'name': keyName,
      'requestedBy': user.uid,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Method alias for acceptRequest - matches the name used in couple_screen.dart
  Future<void> acceptCoupleRequest(String requestId) async {
    final requestDoc =
        await _firestore.collection('coupleRequests').doc(requestId).get();
    if (!requestDoc.exists) throw Exception('Request not found');

    final request = CoupleRequest.fromJson(requestDoc.data()!, requestId);
    return acceptRequest(request);
  }

  // Method alias for rejectRequest - matches the name used in couple_screen.dart
  Future<void> rejectCoupleRequest(String requestId) async {
    return rejectRequest(requestId);
  }

  // Method alias for requestApiKey - matches the name used in couple_screen.dart
  Future<void> createApiKey(String coupleId, String keyName) async {
    return requestApiKey(coupleId, keyName);
  }
}
