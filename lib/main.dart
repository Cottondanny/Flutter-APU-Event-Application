import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:studenthub/theme/app_theme.dart';
import 'firebase_options_local.dart';
import 'screens/auth/auth_gate.dart';

/*
Test profile info
dannywinter@mail.apu.edu.my
Danny123
*/

// Global notifier — any screen can read or change this
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  // These two lines MUST come before Firebase.initializeApp()
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const StudentHubApp());
}

class StudentHubApp extends StatelessWidget {
  const StudentHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder rebuilds the MaterialApp
    // every time themeNotifier changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'StudentHub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: currentMode,
          home: const AuthGate(),
        );
      },
    );
  }
}
