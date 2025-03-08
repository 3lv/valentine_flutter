// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:valentine_flutter/models/couple.dart';
import 'package:valentine_flutter/providers/auth_provider.dart';
import 'package:valentine_flutter/services/firebase_service.dart';
import 'package:valentine_flutter/services/wallpaper_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:valentine_flutter/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _apiKeyNameController = TextEditingController();
  String? _copiedKey;
  bool _isServiceRunning = false;
  int _updateFrequency = 15; // Default 15 minutes
  int _wallpaperLocation = WallpaperManager.BOTH_SCREEN; // Default both screens
  bool _showApiKeys = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _updateFrequency = prefs.getInt('wallpaper_update_frequency') ?? 15;
      _wallpaperLocation =
          prefs.getInt('wallpaper_location') ?? WallpaperManager.BOTH_SCREEN;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wallpaper_update_frequency', _updateFrequency);
    await prefs.setInt('wallpaper_location', _wallpaperLocation);

    // Restart the service to apply new settings
    if (_isServiceRunning) {
      await WallpaperService.stopService();
      await WallpaperService.startService();
      _checkServiceStatus();
    }
  }

  @override
  void dispose() {
    _apiKeyNameController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _copiedKey = text;
    });
    _showSnackBar('Copied to clipboard');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedKey = null;
        });
      }
    });
  }

  Future<void> _createApiKey(String coupleId) async {
    if (_apiKeyNameController.text.isEmpty) {
      _showSnackBar('Please enter a name for the API key', isError: true);
      return;
    }

    try {
      await _firebaseService.createApiKey(coupleId, _apiKeyNameController.text);
      _apiKeyNameController.clear();
      _showSnackBar('API key creation in progress');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await WallpaperService.isServiceRunning();
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallpaper Service Toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Wallpaper Service",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Enable automatic wallpaper updates",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Wallpaper Service Status'),
                      subtitle: Text(_isServiceRunning ? 'Running' : 'Stopped'),
                      value: _isServiceRunning,
                      onChanged: (bool value) async {
                        if (value) {
                          await WallpaperService.startService();
                        } else {
                          await WallpaperService.stopService();
                        }
                        await _checkServiceStatus();
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Update Frequency",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      "Note: Higher frequencies may impact battery usage.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: _updateFrequency,
                      isExpanded: true,
                      hint: const Text('Select update frequency'),
                      items: [1, 3, 5, 15, 30, 60, 120].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('Every $value minutes'),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _updateFrequency = newValue!;
                        });
                        _saveSettings();
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text("Applied to Screens",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RadioListTile<int>(
                      title: const Text('Both Screens'),
                      value: WallpaperManager.BOTH_SCREEN,
                      groupValue: _wallpaperLocation,
                      onChanged: (value) {
                        setState(() {
                          _wallpaperLocation = value!;
                        });
                        _saveSettings();
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('Home Screen Only'),
                      value: WallpaperManager.HOME_SCREEN,
                      groupValue: _wallpaperLocation,
                      onChanged: (value) {
                        setState(() {
                          _wallpaperLocation = value!;
                        });
                        _saveSettings();
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('Lock Screen Only'),
                      value: WallpaperManager.LOCK_SCREEN,
                      groupValue: _wallpaperLocation,
                      onChanged: (value) {
                        setState(() {
                          _wallpaperLocation = value!;
                        });
                        _saveSettings();
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final result =
                            await WallpaperService.updateWallpaperNow();
                        _showSnackBar(result
                            ? "Wallpaper updated!"
                            : "Wallpaper update failed");
                      },
                      child: const Text("Update Wallpaper Now"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // API Key Management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<Couple?>(
                  stream: _firebaseService.getCoupleStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final couple = snapshot.data;
                    if (couple == null) {
                      return const Text("No couple data available");
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "API Keys",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showApiKeys = !_showApiKeys;
                                });
                              },
                              child: Text(_showApiKeys ? "Hide" : "Show"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Generate API keys for external integrations",
                          style: TextStyle(color: Colors.grey),
                        ),
                        if (_showApiKeys) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _apiKeyNameController,
                                  decoration: const InputDecoration(
                                    labelText: "API Key Name",
                                    hintText: "My API Key",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 56, // Match TextField height
                                child: ElevatedButton(
                                  onPressed: () => _createApiKey(couple.id),
                                  child: const Text("Create"),
                                ),
                              ),
                            ],
                          ),
                          if (couple.apiKeys != null &&
                              couple.apiKeys!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              "Your API Keys",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...couple.apiKeys!.map(
                              (apiKey) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.grey[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            apiKey.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                _copyToClipboard(apiKey.key),
                                            child: Text(_copiedKey == apiKey.key
                                                ? 'Copied!'
                                                : 'Copy'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            "Created: ${DateFormat('MM/dd/yyyy').format(apiKey.createdAt)}",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                          if (apiKey.lastUsed != null) ...[
                                            const SizedBox(width: 16),
                                            Text(
                                              "Last used: ${DateFormat('MM/dd/yyyy').format(apiKey.lastUsed!)}",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),
            // Logout button
            ElevatedButton.icon(
              onPressed: () async {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
