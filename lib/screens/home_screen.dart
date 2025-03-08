// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:valentine_flutter/models/background_image.dart';
import 'package:valentine_flutter/providers/auth_provider.dart';
import 'package:valentine_flutter/services/storage_service.dart';
import 'package:valentine_flutter/screens/background_screen.dart';
import 'package:valentine_flutter/screens/couple_screen.dart';
import 'package:valentine_flutter/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _coupleId;
  String? _coupleName;
  File? _uploadingImageFile;

  // Add animation controller for smooth transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Setup animation controller for smooth transitions
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCoupleData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initCoupleData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      final coupleSnapshot = await authProvider.getUserCoupleId(user.uid);
      if (coupleSnapshot != null) {
        final coupleData = await authProvider.getCoupleData(coupleSnapshot);
        setState(() {
          _coupleId = coupleSnapshot;
          _coupleName = coupleData?.name ?? 'Our Love Story';
        });
      }
    }
  }

  // Update the file select handler for smoother uploads
  Future<void> _handleFileSelect(File file) async {
    if (_coupleId == null) {
      _showSnackBar("You need to create a couple first", isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadingImageFile = file;
    });

    try {
      await _storageService.uploadBackgroundImage(
        file,
        _coupleId!,
        (progress) {
          // Use a more targeted setState to only update progress
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        _showSnackBar("Background uploaded successfully!");
        // Keep showing the local image briefly
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _isUploading = false;
              _uploadingImageFile = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error uploading background: ${e.toString()}",
            isError: true);
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      _handleFileSelect(File(image.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _handleFileSelect(File(image.path));
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _navigateToCoupleScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CoupleScreen()),
    );
  }

  void _navigateToBackgroundScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BackgroundScreen()),
    );
  }

  void _navigateToSettingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_coupleName ?? 'Loading...'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: _navigateToCoupleScreen,
              tooltip: 'Couple Details',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettingsScreen,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StreamBuilder<List<BackgroundImage>>(
                    stream: _storageService.getBackgroundsStream(_coupleId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error loading backgrounds: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final backgrounds = snapshot.data ?? [];

                      if (backgrounds.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              "No backgrounds yet. Upload your first one!",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      // Get active background if any
                      final activeBackground = backgrounds.firstWhere(
                        (bg) => bg.active == true,
                        orElse: () => backgrounds.first,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Current Background",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width *
                                  0.7, // Make it smaller
                              child: AspectRatio(
                                aspectRatio: 9 / 16, // Use 9:16 aspect ratio
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      // Base image layer - uploaded image or network image
                                      if (_isUploading &&
                                          _uploadingImageFile != null)
                                        Image.file(
                                          _uploadingImageFile!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      else
                                        CachedNetworkImage(
                                          imageUrl: activeBackground.imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ),

                                      // Upload progress overlay
                                      if (_isUploading)
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.7 *
                                              (16 / 9) *
                                              _uploadProgress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.purpleAccent
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),

                                      // Upload percentage text
                                      if (_isUploading)
                                        Positioned(
                                          bottom: 16,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                "${(_uploadProgress * 100).round()}%",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _navigateToBackgroundScreen,
                              icon: const Icon(Icons.photo_library),
                              label: const Text("View Recent Backgrounds"),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.deepPurple,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _pickFromGallery,
            heroTag: 'gallery',
            backgroundColor: Colors.purpleAccent,
            child: const Icon(Icons.photo),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _takePhoto,
            heroTag: 'camera',
            backgroundColor: Colors.pinkAccent,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
