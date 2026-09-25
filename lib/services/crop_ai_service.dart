// lib/services/guest_crop_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_crop_model.dart';

class GuestCropService {
  static const String _guestCropsKey = 'guest_tracked_crops';
  
  final ValueNotifier<List<UserCrop>> cropsNotifier = ValueNotifier([]);

  GuestCropService() {
    loadCrops();
  }

  Future<void> loadCrops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? existingList = prefs.getStringList(_guestCropsKey);
      
      if (existingList == null) {
        cropsNotifier.value = [];
        return;
      }

      final loadedCrops = existingList.map((item) {
        final Map<String, dynamic> map = jsonDecode(item) as Map<String, dynamic>;
        return UserCrop.fromMap(map['id'] ?? '', map);
      }).toList();

      // Ensure a brand new list reference is assigned
      cropsNotifier.value = List.from(loadedCrops);
    } catch (_) {
      cropsNotifier.value = [];
    }
  }

  Future<void> addCrop(UserCrop crop) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> existingList = prefs.getStringList(_guestCropsKey) ?? [];
      
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final localCrop = UserCrop(
        id: newId,
        userId: 'guest',
        name: crop.name,
        medium: crop.medium,
        plantedDate: crop.plantedDate,
        harvestDurationDays: crop.harvestDurationDays,
        wateringIntervalHours: crop.wateringIntervalHours,
        lastWatered: crop.lastWatered,
        gridIndex: crop.gridIndex, // Preserves the exact slot index selected on the grid
      );

      existingList.add(jsonEncode(localCrop.toMap()));
      await prefs.setStringList(_guestCropsKey, existingList);
      
      // Instantly update the current list in memory and notify UI
      final currentList = List<UserCrop>.from(cropsNotifier.value);
      currentList.add(localCrop);
      cropsNotifier.value = currentList;
    } catch (_) {
      // Fallback safeguard
    }
  }

  Future<void> updateCrop(UserCrop crop) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> existingList = prefs.getStringList(_guestCropsKey) ?? [];

      final updatedList = existingList.map((item) {
        final Map<String, dynamic> map = jsonDecode(item) as Map<String, dynamic>;
        if (map['id'] == crop.id) {
          return jsonEncode(crop.toMap());
        }
        return item;
      }).toList();

      await prefs.setStringList(_guestCropsKey, updatedList);

      // Instantly map and assign a brand-new list to force ValueListenableBuilder to rebuild
      final currentList = cropsNotifier.value.map((c) {
        return c.id == crop.id ? crop : c;
      }).toList();
      
      cropsNotifier.value = List.from(currentList);
    } catch (_) {}
  }

  Future<void> deleteCrop(String cropId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> existingList = prefs.getStringList(_guestCropsKey) ?? [];

      existingList.removeWhere((item) {
        final Map<String, dynamic> map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == cropId;
      });

      await prefs.setStringList(_guestCropsKey, existingList);

      // Instantly remove from local memory and notify listeners
      final currentList = List<UserCrop>.from(cropsNotifier.value);
      currentList.removeWhere((c) => c.id == cropId);
      cropsNotifier.value = currentList;
    } catch (_) {}
  }
}