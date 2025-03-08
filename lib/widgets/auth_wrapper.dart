// lib/widgets/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:valentine_flutter/providers/auth_provider.dart';
import 'package:valentine_flutter/screens/couple_screen.dart';
import 'package:valentine_flutter/screens/welcome_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Provider.of<AuthProvider>(context).authStateChanges,
      builder: (context, snapshot) {
        // If user is authenticated, go directly to the couple screen
        if (snapshot.hasData) {
          return const CoupleScreen();
        }

        // Otherwise show welcome/login flow
        return const WelcomeScreen();
      },
    );
  }
}
