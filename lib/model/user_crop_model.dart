// lib/model/user_crop_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PlantingMedium { flowerPot, gardenBed }

class UserCrop {
  final String id;
  final String userId; // Ties the crop to a specific user account
  final String name;
  final PlantingMedium medium;
  final DateTime plantedDate;
  final int harvestDurationDays;
  int wateringIntervalHours;
  DateTime lastWatered;
  final int gridIndex; // Added for 11x11 grid slot positioning

  UserCrop({
    required this.id,
    required this.userId,
    required this.name,
    required this.medium,
    required this.plantedDate,
    required this.harvestDurationDays,
    required this.wateringIntervalHours,
    required this.lastWatered,
    this.gridIndex = -1,
  });

  // Calculate days remaining until harvest
  int get daysUntilHarvest {
    final maturityDate = plantedDate.add(Duration(days: harvestDurationDays));
    final difference = maturityDate.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  // Calculate time left until next watering
  Duration get timeUntilNextWatering {
    final nextWateringTime = lastWatered.add(Duration(hours: wateringIntervalHours));
    final remaining = nextWateringTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get needsWatering => timeUntilNextWatering == Duration.zero;

  // copyWith method for immutable state updates
  UserCrop copyWith({
    String? id,
    String? userId,
    String? name,
    PlantingMedium? medium,
    DateTime? plantedDate,
    int? harvestDurationDays,
    int? wateringIntervalHours,
    DateTime? lastWatered,
    int? gridIndex,
  }) {
    return UserCrop(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      medium: medium ?? this.medium,
      plantedDate: plantedDate ?? this.plantedDate,
      harvestDurationDays: harvestDurationDays ?? this.harvestDurationDays,
      wateringIntervalHours: wateringIntervalHours ?? this.wateringIntervalHours,
      lastWatered: lastWatered ?? this.lastWatered,
      gridIndex: gridIndex ?? this.gridIndex,
    );
  }

  // Convert Firestore Document to UserCrop object
  factory UserCrop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserCrop(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      medium: data['medium'] == 'gardenBed' 
          ? PlantingMedium.gardenBed 
          : PlantingMedium.flowerPot,
      plantedDate: (data['plantedDate'] as Timestamp).toDate(),
      harvestDurationDays: data['harvestDurationDays'] ?? 60,
      wateringIntervalHours: data['wateringIntervalHours'] ?? 24,
      lastWatered: (data['lastWatered'] as Timestamp).toDate(),
      gridIndex: data['gridIndex'] ?? -1,
    );
  }

  // Convert UserCrop object to JSON for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'medium': medium == PlantingMedium.gardenBed ? 'gardenBed' : 'flowerPot',
      'plantedDate': Timestamp.fromDate(plantedDate),
      'harvestDurationDays': harvestDurationDays,
      'wateringIntervalHours': wateringIntervalHours,
      'lastWatered': Timestamp.fromDate(lastWatered),
      'gridIndex': gridIndex,
    };
  }

  // Generic Map support for Local Storage (SharedPreferences / JSON cache)
  factory UserCrop.fromMap(String id, Map<String, dynamic> map) {
    return UserCrop(
      id: id,
      userId: map['userId'] ?? 'guest',
      name: map['name'] ?? '',
      medium: map['medium'] == 'gardenBed' 
          ? PlantingMedium.gardenBed 
          : PlantingMedium.flowerPot,
      plantedDate: map['plantedDate'] != null 
          ? DateTime.parse(map['plantedDate']) 
          : DateTime.now(),
      harvestDurationDays: map['harvestDurationDays'] ?? 60,
      wateringIntervalHours: map['wateringIntervalHours'] ?? 24,
      lastWatered: map['lastWatered'] != null 
          ? DateTime.parse(map['lastWatered']) 
          : DateTime.now(),
      gridIndex: map['gridIndex'] ?? -1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'medium': medium == PlantingMedium.gardenBed ? 'gardenBed' : 'flowerPot',
      'plantedDate': plantedDate.toIso8601String(),
      'harvestDurationDays': harvestDurationDays,
      'wateringIntervalHours': wateringIntervalHours,
      'lastWatered': lastWatered.toIso8601String(),
      'gridIndex': gridIndex,
    };
  }
}