import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studenthub/screens/home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Firebase streams the login state in real time
      // It emits a value every time login state changes
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Still waiting for Firebase to respond
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // snapshot.data is the logged-in User, or null if nobody is logged in
        if (snapshot.hasData) {
          return const Homepage(); // logged in, go home
        } else {
          return const LoginScreen(); // not logged in, show login
        }
      },
    );
  }
}