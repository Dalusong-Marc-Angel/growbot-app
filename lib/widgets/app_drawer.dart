// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/ui_settings_provider.dart';
import '../screens/auth_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final uiSettings = context.watch<UISettingsProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2E7D32)),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),

          // Main Settings List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. User Profile Tab
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(isGuest ? 'Guest User' : (user.displayName ?? 'User Profile')),
                  subtitle: Text(isGuest ? 'Not signed in' : (user.email ?? 'No email linked')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserProfileScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),

                // 2. GUI Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Card GUI Size',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<CardScale>(
                        isExpanded: true,
                        value: uiSettings.cardScale,
                        items: CardScale.values.map((scale) {
                          return DropdownMenuItem<CardScale>(
                            value: scale,
                            child: Text(scale.label),
                          );
                        }).toList(),
                        onChanged: (newScale) {
                          if (newScale != null) {
                            context.read<UISettingsProvider>().setCardScale(newScale);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Theme Mode Preference
                      const Text(
                        'Theme Mode',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<ThemeMode>(
                        isExpanded: true,
                        value: uiSettings.themeMode,
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System Default'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light Mode'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark Mode'),
                          ),
                        ],
                        onChanged: (newMode) {
                          if (newMode != null) {
                            context.read<UISettingsProvider>().setThemeMode(newMode);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Bottom Action: Sign In for Guests OR Log Out for Authenticated Users
          if (isGuest)
            ListTile(
              leading: const Icon(Icons.login, color: Color(0xFF2E7D32)),
              title: const Text(
                'Sign In / Register',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                await FirebaseAuth.instance.signOut();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                await FirebaseAuth.instance.signOut();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// User Profile Screen (Sub-tab)
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Center(
              child: Icon(
                Icons.account_circle,
                size: 96,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Name'),
                subtitle: Text(
                  isGuest ? 'Guest User' : (user.displayName ?? 'No name set'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email Address'),
                subtitle: Text(
                  isGuest ? 'None (Logged in as Guest)' : (user.email ?? 'No email linked'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}