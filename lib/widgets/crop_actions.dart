// lib/widgets/crop_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_crop_model.dart';
import '../model/seed_model.dart';
import '../providers/seed_repository.dart';
import '../services/crop_service.dart';
import '../services/guest_crop_service.dart';

void showAddCropModal({
  required BuildContext context,
  String? defaultCropName,
  int? targetGridIndex, // Added to support exact slot placement on the 11x11 grid
}) {
  final SeedRepository seedRepo = SeedRepository();
  final List<Seed> availableSeeds = seedRepo.seeds;
  final CropService cropService = CropService();
  final GuestCropService guestCropService = GuestCropService();

  if (availableSeeds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: No seeds found in SeedRepository!')),
    );
    return;
  }

  Seed? selectedSeed;
  if (defaultCropName != null && defaultCropName.isNotEmpty) {
    for (var seed in availableSeeds) {
      if (seed.localName.toLowerCase() == defaultCropName.toLowerCase() ||
          seed.englishName.toLowerCase() == defaultCropName.toLowerCase()) {
        selectedSeed = seed;
        break;
      }
    }
  }
  selectedSeed ??= availableSeeds.first;

  PlantingMedium chosenMedium = PlantingMedium.flowerPot;
  int wateringInterval = 24;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          bool isSaving = false;

          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  targetGridIndex != null
                      ? 'Add Crop to Slot ${targetGridIndex + 1}'
                      : 'Add Crop to Track',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Seed>(
                  value: selectedSeed,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Crop Seed',
                    border: OutlineInputBorder(),
                  ),
                  items: availableSeeds.map((seed) {
                    final displayName = seed.englishName.isNotEmpty
                        ? '${seed.localName} (${seed.englishName})'
                        : seed.localName;

                    final bool isAsset =
                        seed.imagePlaceholder.startsWith('assets/') ||
                            seed.imagePlaceholder.contains('.');

                    return DropdownMenuItem<Seed>(
                      value: seed,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: isAsset
                                ? Image.asset(
                                    seed.imagePlaceholder,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Text('🌱',
                                            style: TextStyle(fontSize: 16)),
                                  )
                                : Center(
                                    child: Text(
                                      seed.imagePlaceholder,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedSeed = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SegmentedButton<PlantingMedium>(
                  segments: const [
                    ButtonSegment(
                      value: PlantingMedium.flowerPot,
                      label: Text('Flower Pot'),
                      icon: Icon(Icons.local_florist),
                    ),
                    ButtonSegment(
                      value: PlantingMedium.gardenBed,
                      label: Text('Garden Bed'),
                      icon: Icon(Icons.grass),
                    ),
                  ],
                  selected: {chosenMedium},
                  onSelectionChanged: (val) {
                    setModalState(() => chosenMedium = val.first);
                  },
                ),
                const SizedBox(height: 16),
                Text('Watering Interval: $wateringInterval Hours'),
                Slider(
                  value: wateringInterval.toDouble(),
                  min: 4,
                  max: 48,
                  divisions: 11,
                  label: '$wateringInterval hrs',
                  onChanged: (val) {
                    setModalState(() => wateringInterval = val.toInt());
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: (selectedSeed == null || isSaving)
                        ? null
                        : () async {
                            final user = FirebaseAuth.instance.currentUser;
                            final userId = user?.uid ?? 'guest';

                            final newCrop = UserCrop(
                              id: '',
                              userId: userId,
                              name: selectedSeed!.localName.isNotEmpty
                                  ? selectedSeed!.localName
                                  : selectedSeed!.englishName,
                              medium: chosenMedium,
                              plantedDate: DateTime.now(),
                              harvestDurationDays:
                                  selectedSeed!.harvestDurationDays,
                              wateringIntervalHours: wateringInterval,
                              lastWatered: DateTime.now(),
                              gridIndex: targetGridIndex ?? -1, // Assigned to target slot index
                            );

                            setModalState(() => isSaving = true);

                            try {
                              if (user != null) {
                                if (kDebugMode) {
                                  debugPrint(
                                    '[AddCrop] Writing to Firestore for uid=${user.uid} '
                                    'path=users/${user.uid}/crops',
                                  );
                                }
                                await cropService.addCrop(newCrop);
                              } else {
                                if (kDebugMode) {
                                  debugPrint(
                                      '[AddCrop] No authenticated user — writing to guest local storage');
                                }
                                await guestCropService.addCrop(newCrop);
                              }

                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      user != null
                                          ? 'Successfully tracked ${newCrop.name}!'
                                          : 'Tracked ${newCrop.name} locally (Guest Mode)',
                                    ),
                                  ),
                                );
                              }
                            } catch (e, st) {
                              debugPrint('[AddCrop] FAILED: $e');
                              debugPrint('[AddCrop] Stack trace: $st');

                              if (ctx.mounted) {
                                setModalState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red.shade700,
                                    duration: const Duration(seconds: 6),
                                    content: Text('Failed to save crop: $e'),
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : const Text('Add to My Crops'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}