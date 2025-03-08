// lib/services/wallpaper_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valentine_flutter/models/background_image.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

@pragma('vm:entry-point')
class WallpaperService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Configure the background service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true, // Already set correctly
        notificationChannelId: 'wallpaper_updates',
        initialNotificationTitle: 'Wallpaper Updates',
        initialNotificationContent: 'Checking for new wallpapers',
        foregroundServiceNotificationId: 888,
        // Comment out service types
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onIosBackground() async {
    print("iOS background fetch initiated");
    await checkForWallpaperUpdates();
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Initialize Flutter background service
    DartPluginRegistrant.ensureInitialized();

    // Load user settings
    final prefs = await SharedPreferences.getInstance();
    final updateFrequencyMinutes =
        prefs.getInt('wallpaper_update_frequency') ?? 15;

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Wallpaper Service",
        content: "Running in background",
      );

      service.setAsForegroundService();
    }

    // Store timer reference so we can cancel it later
    Timer? periodicTimer;

    // Add handler to stop service when requested
    service.on('stopService').listen((event) {
      // Cancel the timer first
      periodicTimer?.cancel();
      // Then stop the service
      service.stopSelf();
    });

    // Run immediately when started
    await checkForWallpaperUpdates();

    // Schedule periodic checks based on user preference
    periodicTimer = Timer.periodic(Duration(minutes: updateFrequencyMinutes),
        (timer) async {
      await checkForWallpaperUpdates();

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Wallpaper Service",
          content: "Last check: ${DateTime.now().toString().substring(11, 16)}",
        );
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<void> checkForWallpaperUpdates() async {
    try {
      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user's coupleId
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;
      final coupleId = userDoc.data()?['coupleId'];
      if (coupleId == null) return;

      // Get the latest active background
      final backgroundsSnapshot = await FirebaseFirestore.instance
          .collection('couples')
          .doc(coupleId)
          .collection('backgrounds')
          .where('active', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (backgroundsSnapshot.docs.isEmpty) return;

      final backgroundDoc = backgroundsSnapshot.docs.first;
      final backgroundData = backgroundDoc.data();
      final background =
          BackgroundImage.fromJson(backgroundData, backgroundDoc.id);

      // Check if this background is different from the last one we set
      final prefs = await SharedPreferences.getInstance();
      final lastBackgroundId = prefs.getString('last_background_id');

      if (lastBackgroundId != background.id) {
        // Download the image
        final response = await http.get(Uri.parse(background.imageUrl));
        final bytes = response.bodyBytes;

        // Decode and ensure correct orientation
        final image = img.decodeImage(bytes);
        final fixedImage =
            img.copyRotate(image!, angle: 360); // Force no rotation

        // Save image to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/wallpaper.jpg');
        await file.writeAsBytes(img.encodeJpg(fixedImage, quality: 100));

        // Load user's screen preference
        final wallpaperLocation =
            prefs.getInt('wallpaper_location') ?? WallpaperManager.BOTH_SCREEN;

        // Set as wallpaper using flutter_wallpaper_manager
        final result = await WallpaperManager.setWallpaperFromFile(
          file.path,
          wallpaperLocation, // Use the saved preference
        );

        if (result) {
          // Save this as the last background we set
          await prefs.setString('last_background_id', background.id!);
          print("Wallpaper updated successfully");
        }
      }
    } catch (e) {
      print("Error checking for wallpaper updates: $e");
    }
  }

  // Method to manually trigger wallpaper update
  static Future<bool> updateWallpaperNow() async {
    try {
      await checkForWallpaperUpdates();
      return true;
    } catch (e) {
      print("Manual wallpaper update failed: $e");
      return false;
    }
  }

  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }
}
