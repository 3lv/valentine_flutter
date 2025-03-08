// lib/screens/background_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:valentine_flutter/models/background_image.dart';
import 'package:valentine_flutter/providers/auth_provider.dart';
import 'package:valentine_flutter/services/storage_service.dart';
import 'package:valentine_flutter/widgets/image_upload_widget.dart';
import 'package:valentine_flutter/services/wallpaper_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BackgroundScreen extends StatefulWidget {
  const BackgroundScreen({super.key});

  @override
  State<BackgroundScreen> createState() => _BackgroundScreenState();
}

class _BackgroundScreenState extends State<BackgroundScreen> {
  final StorageService _storageService = StorageService();
  double _uploadProgress = 0;
  bool _isUploading = false;
  String? _coupleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCoupleId();
    });
  }

  Future<void> _initCoupleId() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      final coupleSnapshot = await authProvider.getUserCoupleId(user.uid);
      if (coupleSnapshot != null) {
        setState(() {
          _coupleId = coupleSnapshot;
        });
      }
    }
  }

  Future<void> _handleFileSelect(File file) async {
    if (_coupleId == null) {
      _showSnackBar("You need to create a couple first", isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      await _storageService.uploadBackgroundImage(
        file,
        _coupleId!,
        (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      _showSnackBar("Background uploaded successfully!");
    } catch (e) {
      _showSnackBar("Error uploading background: ${e.toString()}",
          isError: true);
    } finally {
      setState(() {
        _isUploading = false;
      });
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

  Future<void> _testWallpaperUpdate() async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Testing wallpaper update...")));

    final result = await WallpaperService.updateWallpaperNow();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          result ? "Wallpaper update successful!" : "Wallpaper update failed"),
      backgroundColor: result ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Manager'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upload New Background",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Change your lover's phone and PC background!",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ImageUploadWidget(
                      onFileSelected: _handleFileSelect,
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 8),
                      Text(
                        "Uploading: ${(_uploadProgress * 100).round()}%",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<BackgroundImage>>(
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
                    // Display active background
                    const Text(
                      "Current Background",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      // Center the background horizontally
                      child: SizedBox(
                        width: 200, // Constrain width to make it smaller
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 9 / 16, // Keep phone aspect ratio
                            child: Image.network(
                              activeBackground.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Display all backgrounds
                    const Text(
                      "Recent Backgrounds",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 9.0 / 16,
                      ),
                      // Filter out the active background
                      itemCount: backgrounds
                          .where((bg) => bg.id != activeBackground.id)
                          .length,
                      itemBuilder: (context, index) {
                        // Create a filtered list excluding the active background
                        final filteredBackgrounds = backgrounds
                            .where((bg) => bg.id != activeBackground.id)
                            .toList();
                        final background = filteredBackgrounds[index];
                        return _buildBackgroundItem(background);
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _buildServiceStatusIndicator(),
          ],
        ),
      ),
      /*
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _testWallpaperUpdate,
        label: const Text('Test Wallpaper'),
        icon: const Icon(Icons.wallpaper),
      ),
      */
    );
  }

  Widget _buildBackgroundItem(BackgroundImage background) {
    final isActive = background.active ?? false;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background image
        GestureDetector(
          /*
          onTap: () {
            if (!isActive) {
              _setAsActive(background.id!);
            }
          },
          */
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: Colors.deepPurple, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isActive ? 9 : 12),
              child: CachedNetworkImage(
                imageUrl: background.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        ),

        // Delete button
        /*
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _deleteBackground(background.id!),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        */

        // Active indicator
        if (isActive)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildServiceStatusIndicator() {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<bool>(
          future: WallpaperService.isServiceRunning(),
          builder: (context, snapshot) {
            final isRunning = snapshot.data ?? false;

            return ListTile(
              title: const Text('Wallpaper Service Status'),
              subtitle: Text(isRunning ? 'Running' : 'Stopped'),
              trailing: ElevatedButton(
                onPressed: () async {
                  if (isRunning) {
                    await WallpaperService.stopService();
                  } else {
                    await WallpaperService.startService();
                  }
                  setState(() {}); // Refresh UI
                },
                child: Text(isRunning ? 'Stop Service' : 'Start Service'),
              ),
            );
          },
        );
      },
    );
  }
}
