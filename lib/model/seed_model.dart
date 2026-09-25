class Seed {
  final String id;
  final String localName; // e.g., Talong, Kabute
  final String englishName; // e.g., Eggplant, Oyster Mushroom
  final String scientificName; // e.g., Solanum melongena
  final String category; // Vegetable, Fruit, Herb, Fungi, etc.
  final String subgroup; // e.g., Nightshades, Saprophytes
  final String imagePlaceholder; // Asset or icon identifier
  final String idealSoil; // e.g., Loamy soil with Carbonized Rice Hull (CRH)
  final String growingSeason; // Tag-init, Tag-ulan, or Year-round
  final String wateringFreq; // e.g., Daily (Tag-init), Moderate
  final String pestControl; // e.g., Neem oil spray against fruit borers
  final String additionalInfo; // Lore / extra notes
  final int harvestDurationDays; // NEW: Harvest duration field

  const Seed({
    required this.id,
    required this.localName,
    required this.englishName,
    required this.scientificName,
    required this.category,
    required this.subgroup,
    required this.imagePlaceholder,
    required this.idealSoil,
    required this.growingSeason,
    required this.wateringFreq,
    required this.pestControl,
    required this.additionalInfo,
    required this.harvestDurationDays, // NEW: Required in constructor
  });

  // Convert Seed object to Map for Firestore database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'localName': localName,
      'englishName': englishName,
      'scientificName': scientificName,
      'category': category,
      'subgroup': subgroup,
      'imagePlaceholder': imagePlaceholder,
      'idealSoil': idealSoil,
      'growingSeason': growingSeason,
      'wateringFreq': wateringFreq,
      'pestControl': pestControl,
      'additionalInfo': additionalInfo,
      'harvestDurationDays': harvestDurationDays, // NEW: Added to Map
    };
  }

  // Construct Seed object from Firestore Map
  factory Seed.fromMap(Map<String, dynamic> map, String docId) {
    return Seed(
      id: docId,
      localName: map['localName'] ?? '',
      englishName: map['englishName'] ?? '',
      scientificName: map['scientificName'] ?? '',
      category: map['category'] ?? 'Vegetable',
      subgroup: map['subgroup'] ?? '',
      imagePlaceholder: map['imagePlaceholder'] ?? 'assets/images/placeholder.png',
      idealSoil: map['idealSoil'] ?? '',
      growingSeason: map['growingSeason'] ?? 'Year-round',
      wateringFreq: map['wateringFreq'] ?? 'Daily',
      pestControl: map['pestControl'] ?? '',
      additionalInfo: map['additionalInfo'] ?? '',
      harvestDurationDays: map['harvestDurationDays'] ?? 60, // NEW: Added with a 60-day fallback
    );
  }
}