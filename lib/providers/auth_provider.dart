// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:valentine_flutter/models/couple.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      // Exit if canceled
      if (gUser == null) return null;

      // Get auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }

  // Get a user's coupleId from Firestore
  Future<String?> getUserCoupleId(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['coupleId'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user couple ID: $e');
      return null;
    }
  }

  // Add this method to your AuthProvider class
  Future<Couple?> getCoupleData(String coupleId) async {
    try {
      final coupleDoc =
          await _firestore.collection('couples').doc(coupleId).get();

      if (coupleDoc.exists) {
        return Couple.fromJson(coupleDoc.data()!, coupleDoc.id);
      }
      return null;
    } catch (e) {
      print('Error getting couple data: $e');
      return null;
    }
  }
}
