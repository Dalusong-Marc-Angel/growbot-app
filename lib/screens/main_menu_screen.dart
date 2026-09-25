// lib/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seed_index_screen.dart';
import 'my_crops_screen.dart';
import 'journal_screen.dart';
import 'garden_beds_screen.dart';
import 'ai_chat_screen.dart';
import 'community_screen.dart';
import '../widgets/app_drawer.dart';

class MenuItemData {
  final String title;
  final String subtitle;
  final String imageAsset;
  final Widget destinationScreen;

  MenuItemData({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.destinationScreen,
  });
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isGuest = currentUser == null;
    final String? userId = currentUser?.uid;

    final List<MenuItemData> menuItems = [
      MenuItemData(
        title: 'Seed Index',
        subtitle: 'Almanac & Plant Database',
        imageAsset: 'assets/images/seedindex.png',
        destinationScreen: const SeedIndexScreen(),
      ),
      MenuItemData(
        title: 'My Crops',
        subtitle: 'Garden Grid & Watering Tracker',
        imageAsset: 'assets/images/mycrops.png',
        destinationScreen: const MyCropsScreen(),
      ),
      MenuItemData(
        title: 'Journal',
        subtitle: 'Personal Notes & Observations',
        imageAsset: 'assets/images/journal.png',
        destinationScreen: JournalScreen(isGuest: isGuest, userId: userId),
      ),
      MenuItemData(
        title: 'Garden Bed & Pots',
        subtitle: 'Soil Mixes & Container Guides',
        imageAsset: 'assets/images/beds.png',
        destinationScreen: const GardenBedsScreen(),
      ),
      MenuItemData(
        title: 'AI Chat',
        subtitle: 'Gardening Assistant & Diagnosis',
        imageAsset: 'assets/images/growbotai.png',
        destinationScreen: const AiChatScreen(),
      ),
      MenuItemData(
        title: 'Community',
        subtitle: 'Connect with Growers',
        imageAsset: 'assets/images/community.png',
        destinationScreen: const CommunityScreen(),
      ),
    ];

    final mediaQuery = MediaQuery.of(context);
    final isWideScreen = mediaQuery.size.width >= 800;
    final crossAxisCount = isWideScreen ? 3 : 2;

    // Dynamically calculate aspect ratio based on available screen height 
    // so the 3 rows expand smoothly to fill the screen without dead bottom space.
    final double appBarHeight = AppBar().preferredSize.height;
    final double topPadding = mediaQuery.padding.top;
    final double availableHeight = mediaQuery.size.height - appBarHeight - topPadding - 32; // 32 for padding
    
    // There are 3 rows on mobile (6 items / 2 columns = 3 rows)
    final int rowCount = (menuItems.length / crossAxisCount).ceil();
    final double totalMainAxisSpacing = 16.0 * (rowCount - 1);
    final double rowHeight = (availableHeight - totalMainAxisSpacing) / rowCount;
    
    // Calculate width per item
    final double totalCrossAxisSpacing = 16.0 * (crossAxisCount - 1);
    final double availableWidth = mediaQuery.size.width - 32.0 - totalCrossAxisSpacing;
    final double columnWidth = availableWidth / crossAxisCount;

    final double calculatedAspectRatio = isWideScreen ? 1.1 : (columnWidth / rowHeight);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GROWBOT - Main Menu'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // Locks scrolling so it fits neatly as a single screen dashboard
          itemCount: menuItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: calculatedAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => item.destinationScreen),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.asset(
                      item.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Center(child: Icon(Icons.eco, size: 48)),
                      ),
                    ),
                    // Dark Gradient Scrim Overlay for Readability
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    // Card Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}