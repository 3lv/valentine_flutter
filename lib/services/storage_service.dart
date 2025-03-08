// lib/services/storage_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:valentine_flutter/models/background_image.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload background image
  Future<BackgroundImage> uploadBackgroundImage(
      File imageFile, String coupleId, Function(double) onProgress) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Create a reference to the file location
    final storageRef = _storage.ref().child(
        'couples/$coupleId/backgrounds/${DateTime.now().millisecondsSinceEpoch}-${imageFile.path.split('/').last}');

    // Add a temporary image record
    final tempImage = BackgroundImage(
      imageUrl: '',
      timestamp: DateTime.now(),
      userId: user.uid,
      isLoading: true,
    );

    // Upload the file
    final uploadTask = storageRef.putFile(imageFile);

    // Listen for upload progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress(progress);
    });

    // Wait for the upload to complete
    await uploadTask.whenComplete(() {});

    // Get the download URL
    final downloadUrl = await storageRef.getDownloadURL();

    // Create the background document
    final docRef = await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('backgrounds')
        .add({
      'imageUrl': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'active': true,
    });

    return BackgroundImage(
      id: docRef.id,
      imageUrl: downloadUrl,
      timestamp: DateTime.now(),
      userId: user.uid,
    );
  }

  // Get backgrounds stream
  Stream<List<BackgroundImage>> getBackgroundsStream(String? coupleId) {
    if (coupleId == null) return Stream.value([]);

    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('backgrounds')
        .where('active', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(11)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BackgroundImage.fromJson(doc.data(), doc.id))
          .toList();
    });
  }
}
