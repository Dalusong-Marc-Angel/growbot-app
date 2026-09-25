// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart'; 
import 'providers/ui_settings_provider.dart';
import 'providers/seed_repository.dart';
import 'providers/journal_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check removed for now so local testing and auth flow run freely

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UISettingsProvider()),
        ChangeNotifierProvider(create: (_) => SeedRepository()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
      ],
      child: const FarmingAlmanacApp(),
    ),
  );
}

class FarmingAlmanacApp extends StatelessWidget {
  const FarmingAlmanacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UISettingsProvider>(
      builder: (context, uiSettings, child) {
        return MaterialApp(
          title: 'GROWBOT',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF81C784),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: uiSettings.themeMode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return const MainMenuScreen();
              }
              return const AuthScreen();
            },
          ),
        );
      },
    );
  }
}