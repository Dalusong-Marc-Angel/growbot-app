
enum PlantingMedium { flowerPot, gardenBed }

class SeedCatalogItem {
  final String id;
  final String name;
  final int defaultHarvestDays; // Total days to reach harvest

  const SeedCatalogItem({
    required this.id,
    required this.name,
    required this.defaultHarvestDays,
  });
}

// Sample Seed Index / Catalog
const List<SeedCatalogItem> seedCatalog = [
  SeedCatalogItem(id: '1', name: 'Talong (Eggplant)', defaultHarvestDays: 90),
  SeedCatalogItem(id: '2', name: 'Siling Labuyo', defaultHarvestDays: 75),
  SeedCatalogItem(id: '3', name: 'Sitaw (Yardlong Bean)', defaultHarvestDays: 60),
  SeedCatalogItem(id: '4', name: 'Kalabasa (Squash)', defaultHarvestDays: 100),
  SeedCatalogItem(id: '5', name: 'Kangkong', defaultHarvestDays: 30),
];

class UserCrop {
  final String id;
  final String name;
  final PlantingMedium medium;
  final DateTime plantedDate;
  final int harvestDurationDays;
  int wateringIntervalHours;
  DateTime lastWatered;

  UserCrop({
    required this.id,
    required this.name,
    required this.medium,
    required this.plantedDate,
    required this.harvestDurationDays,
    required this.wateringIntervalHours,
    required this.lastWatered,
  });

  // Calculate days remaining until harvest
  int get daysUntilHarvest {
    final harvestDate = plantedDate.add(Duration(days: harvestDurationDays));
    final remaining = harvestDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  // Check if watering is needed
  bool get needsWatering {
    final nextWatering = lastWatered.add(Duration(hours: wateringIntervalHours));
    return DateTime.now().isAfter(nextWatering);
  }

  // Get duration until next watering
  Duration get timeUntilNextWatering {
    final nextWatering = lastWatered.add(Duration(hours: wateringIntervalHours));
    final diff = nextWatering.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}