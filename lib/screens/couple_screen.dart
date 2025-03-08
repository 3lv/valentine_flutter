// lib/screens/couple_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:valentine_flutter/models/couple.dart';
import 'package:valentine_flutter/models/couple_request.dart';
import 'package:valentine_flutter/providers/auth_provider.dart';
import 'package:valentine_flutter/screens/background_screen.dart';
import 'package:valentine_flutter/screens/login_screen.dart';
import 'package:valentine_flutter/services/firebase_service.dart';
import 'package:valentine_flutter/widgets/custom_button.dart';

class CoupleScreen extends StatefulWidget {
  const CoupleScreen({super.key});

  @override
  State<CoupleScreen> createState() => _CoupleScreenState();
}

class _CoupleScreenState extends State<CoupleScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _emailController = TextEditingController();
  final _coupleNameController = TextEditingController();
  final _coupleDescriptionController = TextEditingController();

  DateTime _anniversary = DateTime.now();
  bool _isEditing = false;
  bool _showApiKeys = false;
  String? _copiedKey;

  @override
  void dispose() {
    _emailController.dispose();
    _coupleNameController.dispose();
    _coupleDescriptionController.dispose();
    super.dispose();
  }

  Widget _buildNoCoupleView(String currentEmail) {
    return StreamBuilder<List<CoupleRequest>>(
      stream: _firebaseService.getIncomingRequests(),
      builder: (context, incomingRequestsSnapshot) {
        return StreamBuilder<List<CoupleRequest>>(
          stream: _firebaseService.getOutgoingRequests(),
          builder: (context, outgoingRequestsSnapshot) {
            final incomingRequests = incomingRequestsSnapshot.data ?? [];
            final outgoingRequests = outgoingRequestsSnapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invitation form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Create Your Love Connection",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Connect with your partner to start sharing moments together.",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: "Invite your partner by email",
                              border: OutlineInputBorder(),
                              hintText: "partner@example.com",
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            onPressed: _sendInvitation,
                            text: "Send Invitation",
                            isFullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Incoming requests
                  if (incomingRequests.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "Pending Invitations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Someone wants to connect with you! Review and respond to your invitations.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ...incomingRequests.map((request) => _buildRequestCard(
                          request,
                          isIncoming: true,
                        )),
                  ],

                  // Outgoing requests
                  if (outgoingRequests.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      "Sent Invitations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Pending invitations you've sent to others.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ...outgoingRequests.map((request) => _buildRequestCard(
                          request,
                          isIncoming: false,
                        )),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard(CoupleRequest request, {required bool isIncoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIncoming
                        ? request.fromUserDisplayName
                        : request.toUserDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isIncoming ? request.fromUserEmail : request.toUserEmail,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    "Sent ${DateFormat('MMM d, yyyy').format(request.timestamp)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isIncoming) ...[
              TextButton(
                onPressed: () => _acceptRequest(request),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
                child: const Text("Accept"),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _rejectRequest(request.id),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                child: const Text("Decline"),
              ),
            ] else
              TextButton(
                onPressed: () => _rejectRequest(request.id),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                child: const Text("Cancel"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoupleView(Couple couple, int daysSinceAnniversary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Couple header with edit button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _isEditing
                      ? Expanded(
                          child: TextField(
                            controller: _coupleNameController,
                            decoration: const InputDecoration(
                              labelText: 'Couple Name',
                            ),
                          ),
                        )
                      : Expanded(
                          child: Row(
                            children: [
                              Text(
                                couple.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                onPressed: () => _copyToClipboard(couple.id),
                                tooltip: 'Copy ID',
                              ),
                            ],
                          ),
                        ),
                  if (!_isEditing)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => setState(() => _isEditing = true),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Anniversary
              _isEditing
                  ? InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _anniversary,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _anniversary = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Anniversary Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_anniversary),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Together since ${DateFormat('MMM d, yyyy').format(couple.anniversary)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            _formatAnniversaryDuration(daysSinceAnniversary),
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              // Description
              if (_isEditing) ...[
                TextField(
                  controller: _coupleDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  onPressed: () => _updateCoupleDetails(couple.id),
                  text: "Save Changes",
                  isFullWidth: true,
                ),
              ],

              // Members
              if (!_isEditing) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < couple.members.length; i++) ...[
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              couple.members[i].displayName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(couple.members[i].displayName),
                        ],
                      ),
                      if (i < couple.members.length - 1) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.favorite,
                            color: Colors.pink, size: 32),
                        const SizedBox(width: 16),
                      ],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

  Future<void> _sendInvitation() async {
    try {
      await _firebaseService.sendInvitation(_emailController.text);
      _emailController.clear();
      _showSnackBar('Invitation sent successfully!');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _acceptRequest(CoupleRequest request) async {
    try {
      await _firebaseService.acceptCoupleRequest(request.id);
      _showSnackBar('Invitation accepted! Your couple is being set up.');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _firebaseService.rejectCoupleRequest(requestId);
      _showSnackBar('Request removed');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _updateCoupleDetails(String coupleId) async {
    try {
      await _firebaseService.updateCoupleDetails(
        coupleId,
        _coupleNameController.text,
        _coupleDescriptionController.text,
        _anniversary,
      );
      setState(() {
        _isEditing = false;
      });
      _showSnackBar('Couple details updated successfully!');
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  String _formatAnniversaryDuration(int totalDays) {
    final duration = Duration(days: totalDays);
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = (duration.inDays % 365) % 30;

    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? 'year' : 'years'}');
    if (months > 0) parts.add('$months ${months == 1 ? 'month' : 'months'}');
    if (days > 0 || parts.isEmpty)
      parts.add('$days ${days == 1 ? 'day' : 'days'}');

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Couple')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please sign in to access this feature'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Couple'),
      ),
      body: StreamBuilder<Couple?>(
        stream: _firebaseService.getCoupleStream(),
        builder: (context, coupleSnapshot) {
          if (coupleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final couple = coupleSnapshot.data;

          // If no couple exists, show the invitation form
          if (couple == null) {
            return _buildNoCoupleView(currentUser.email ?? '');
          }

          // Initialize controllers with couple data if not already done
          if (!_isEditing) {
            _coupleNameController.text = couple.name;
            _coupleDescriptionController.text = couple.description;
            _anniversary = couple.anniversary;
          }

          // Calculate days since anniversary
          final daysSinceAnniversary =
              DateTime.now().difference(couple.anniversary).inDays;

          return _buildCoupleView(couple, daysSinceAnniversary);
        },
      ),
    );
  }
}
