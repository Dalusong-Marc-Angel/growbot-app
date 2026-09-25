// lib/screens/my_crops_screen.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../model/user_crop_model.dart';
import '../model/seed_model.dart';
import '../providers/seed_repository.dart';
import '../providers/ui_settings_provider.dart';
import '../services/crop_service.dart';
import '../services/guest_crop_service.dart';
import '../widgets/crop_actions.dart';

class MyCropsScreen extends StatefulWidget {
  const MyCropsScreen({super.key});

  @override
  State<MyCropsScreen> createState() => _MyCropsScreenState();
}

class _MyCropsScreenState extends State<MyCropsScreen> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  final CropService _cropService = CropService();
  final GuestCropService _guestService = GuestCropService();
  final ImagePicker _imagePicker = ImagePicker();

  Timer? _countdownTimer;
  final Set<String> _notifiedCropIds = {}; // Tracks crops that already triggered a notification this cycle

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    
    // Periodic timer to update the countdown UI every minute and check for notifications
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
        _checkAndTriggerNotifications();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _showWateringNotification(String cropName) async {
    const androidDetails = AndroidNotificationDetails(
      'watering_channel_id',
      'Watering Alerts',
      channelDescription: 'Notifications when your crops need watering',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      cropName.hashCode,
      'Time to water your crops! 💧',
      'Your $cropName is ready for watering.',
      notificationDetails,
    );
  }

  void _checkAndTriggerNotifications() {
    // If logged in, we check stream data or fallback to guest list depending on state
    final crops = _isLoggedIn ? [] : _guestService.cropsNotifier.value;
    for (final crop in crops) {
      if (crop.needsWatering) {
        if (!_notifiedCropIds.contains(crop.id)) {
          _showWateringNotification(crop.name);
          _notifiedCropIds.add(crop.id);
        }
      } else {
        // Reset notification tracking if it has been watered
        _notifiedCropIds.remove(crop.id);
      }
    }
  }

  void _openAddCropModal({String? defaultCropName, int? targetGridIndex}) {
    showAddCropModal(
      context: context,
      defaultCropName: defaultCropName,
      targetGridIndex: targetGridIndex,
    );
  }

  Future<void> _deleteCrop(String cropId) async {
    if (_isLoggedIn) {
      await _cropService.deleteCrop(cropId);
    } else {
      await _guestService.deleteCrop(cropId);
    }
  }

  Future<void> _updateCrop(UserCrop crop) async {
    if (_isLoggedIn) {
      await _cropService.updateCrop(crop);
    } else {
      await _guestService.updateCrop(crop);
    }
  }

  Future<void> _markAllWatered(List<UserCrop> crops) async {
    if (crops.isEmpty) return;
    final now = DateTime.now();
    for (final crop in crops) {
      await _updateCrop(crop.copyWith(lastWatered: now));
      _notifiedCropIds.remove(crop.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All crops marked as watered!')),
      );
    }
  }

  Seed? _findMatchingSeed(BuildContext context, String cropName) {
    try {
      final seeds = context.read<SeedRepository>().seeds;
      for (var seed in seeds) {
        if (seed.localName.trim().toLowerCase() == cropName.trim().toLowerCase() ||
            seed.englishName.trim().toLowerCase() == cropName.trim().toLowerCase()) {
          return seed;
        }
      }
    } catch (_) {}
    return null;
  }

  void _showMoveCropDialog(BuildContext context, UserCrop crop, List<UserCrop> allCrops, double scaleFactor) {
    int selectedTargetIndex = crop.gridIndex >= 0 ? crop.gridIndex : 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Move ${crop.name}'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Select a destination slot (1 to 121):', style: TextStyle(fontSize: 13 * scaleFactor)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedTargetIndex,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Target Slot'),
                      items: List.generate(121, (index) {
                        final occupant = allCrops.where((c) => c.gridIndex == index && c.id != crop.id).firstOrNull;
                        final label = occupant != null
                            ? 'Slot ${index + 1} (Occupied: ${occupant.name})'
                            : 'Slot ${index + 1} (Empty)';
                        return DropdownMenuItem(
                          value: index,
                          child: Text(label, style: const TextStyle(fontSize: 12)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedTargetIndex = val);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final occupant = allCrops.where((c) => c.gridIndex == selectedTargetIndex && c.id != crop.id).firstOrNull;
                if (occupant != null) {
                  await _updateCrop(occupant.copyWith(gridIndex: -1));
                }

                await _updateCrop(crop.copyWith(gridIndex: selectedTargetIndex));
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(); // close move dialog
                  Navigator.of(context).pop(); // close detail popup
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Moved ${crop.name} to slot ${selectedTargetIndex + 1}!')),
                  );
                }
              },
              child: const Text('Confirm Move'),
            ),
          ],
        );
      },
    );
  }

  void _showCropDetailPopup(BuildContext context, UserCrop crop, List<UserCrop> allCrops, double scaleFactor) {
    final matchingSeed = _findMatchingSeed(context, crop.name);
    final placeholder = matchingSeed?.imagePlaceholder;
    final bool isAsset = placeholder != null && (placeholder.startsWith('assets/') || placeholder.contains('.'));
    final bool isEmoji = placeholder != null && !isAsset && placeholder.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  // Calculate live remaining duration
                  final remainingDuration = crop.timeUntilNextWatering;
                  final hoursLeft = remainingDuration.inHours;
                  final minutesLeft = remainingDuration.inMinutes.remainder(60);
                  
                  final countdownText = remainingDuration == Duration.zero
                      ? 'Needs Watering Now!'
                      : '${hoursLeft}h ${minutesLeft}m left';

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: isAsset
                                    ? DecorationImage(
                                        image: AssetImage(placeholder),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: !isAsset ? Theme.of(context).colorScheme.primaryContainer : null,
                              ),
                              child: Center(
                                child: isAsset
                                    ? null
                                    : (isEmoji
                                        ? Text(placeholder, style: TextStyle(fontSize: 24 * scaleFactor))
                                        : Icon(
                                            crop.medium == PlantingMedium.flowerPot ? Icons.local_florist : Icons.grass,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 24 * scaleFactor,
                                          )),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                crop.name,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await _deleteCrop(crop.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Chip(
                          avatar: Icon(
                            crop.medium == PlantingMedium.flowerPot ? Icons.local_florist : Icons.grass,
                            size: 16,
                          ),
                          label: Text(crop.medium == PlantingMedium.flowerPot ? 'Flower Pot' : 'Garden Bed'),
                        ),
                        const Divider(height: 24),
                        Text(
                          'Maturity Countdown: ${crop.daysUntilHarvest} Days Left (${crop.harvestDurationDays} total days)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Watering Interval: ${crop.wateringIntervalHours} hrs',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        // Live Countdown Subtext
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text(
                              'Countdown: $countdownText',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: remainingDuration == Duration.zero ? Colors.amber.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.open_with, size: 16),
                              label: const Text('Move Crop'),
                              onPressed: () => _showMoveCropDialog(context, crop, allCrops, scaleFactor),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Water'),
                              onPressed: () async {
                                await _updateCrop(crop.copyWith(lastWatered: DateTime.now()));
                                _notifiedCropIds.remove(crop.id);
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = context.watch<UISettingsProvider>().scaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Garden Grid (11x11)', style: TextStyle(fontSize: 20 * scaleFactor)),
        actions: [
          _isLoggedIn
              ? StreamBuilder<List<UserCrop>>(
                  stream: _cropService.getUserCropsStream(),
                  builder: (context, snapshot) {
                    final crops = snapshot.data ?? [];
                    return IconButton(
                      icon: const Icon(Icons.done_all),
                      tooltip: 'Mark All Watered',
                      onPressed: crops.isEmpty ? null : () => _markAllWatered(crops),
                    );
                  },
                )
              : ValueListenableBuilder<List<UserCrop>>(
                  valueListenable: _guestService.cropsNotifier,
                  builder: (context, crops, child) {
                    return IconButton(
                      icon: const Icon(Icons.done_all),
                      tooltip: 'Mark All Watered',
                      onPressed: crops.isEmpty ? null : () => _markAllWatered(crops),
                    );
                  },
                ),
        ],
      ),
      body: _isLoggedIn
          ? StreamBuilder<List<UserCrop>>(
              stream: _cropService.getUserCropsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildGridContent(context, snapshot.data ?? [], scaleFactor);
              },
            )
          : ValueListenableBuilder<List<UserCrop>>(
              valueListenable: _guestService.cropsNotifier,
              builder: (context, crops, child) {
                return _buildGridContent(context, crops, scaleFactor);
              },
            ),
    );
  }

  Widget _buildGridContent(BuildContext context, List<UserCrop> crops, double scaleFactor) {
    const int totalSlots = 121; // 11x11 grid
    const int crossAxisCount = 11;
    const int rowCount = 11;
    const double spacing = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomBuffer = 32.0;
        final availableWidth = constraints.maxWidth - 16.0;
        final availableHeight = constraints.maxHeight - 16.0 - bottomBuffer;

        final totalCrossSpacing = spacing * (crossAxisCount - 1);
        final totalMainSpacing = spacing * (rowCount - 1);

        final itemWidth = (availableWidth - totalCrossSpacing) / crossAxisCount;
        final itemHeight = (availableHeight - totalMainSpacing) / rowCount;

        final calculatedAspectRatio = (itemWidth > 0 && itemHeight > 0) ? (itemWidth / itemHeight) : 1.0;

        return Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0 + bottomBuffer),
            child: SizedBox(
              width: availableWidth,
              height: availableHeight > 0 ? availableHeight : null,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalSlots,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: calculatedAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final UserCrop? crop = crops.where((c) => c.gridIndex == index).firstOrNull;

                  if (crop == null) {
                    return InkWell(
                      onTap: () => _openAddCropModal(targetGridIndex: index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 16 * scaleFactor,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  }

                  final matchingSeed = _findMatchingSeed(context, crop.name);
                  final placeholder = matchingSeed?.imagePlaceholder;
                  final bool isAsset = placeholder != null && (placeholder.startsWith('assets/') || placeholder.contains('.'));
                  final bool isEmoji = placeholder != null && !isAsset && placeholder.trim().isNotEmpty;

                  return InkWell(
                    onTap: () => _showCropDetailPopup(context, crop, crops, scaleFactor),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: isAsset
                            ? DecorationImage(
                                image: AssetImage(placeholder),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                              )
                            : null,
                        color: !isAsset ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6) : null,
                        border: Border.all(
                          color: crop.needsWatering ? Colors.amber : Theme.of(context).colorScheme.primary,
                          width: crop.needsWatering ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: isAsset
                                ? null
                                : (isEmoji
                                    ? Text(placeholder, style: TextStyle(fontSize: 20 * scaleFactor))
                                    : Icon(
                                        crop.medium == PlantingMedium.flowerPot ? Icons.local_florist : Icons.grass,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 18 * scaleFactor,
                                      )),
                          ),
                          if (crop.needsWatering)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                                child: const Icon(Icons.water_drop, size: 10, color: Colors.black),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}