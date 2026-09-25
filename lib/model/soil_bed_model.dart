// Model for Soil Compositions
class SoilComposition {
  final String id;
  final String name;
  final String icon;
  final String rarity; // e.g., 'Common', 'Uncommon', 'Specialized'
  final String composition;
  final String bestFor;
  final String avoidFor;
  final String moistureRetention;
  final String additionalInfo;

  const SoilComposition({
    required this.id,
    required this.name,
    required this.icon,
    required this.rarity,
    required this.composition,
    required this.bestFor,
    required this.avoidFor,
    required this.moistureRetention,
    required this.additionalInfo,
  });
}

// Model for Garden Beds & Pots
class ContainerStyle {
  final String id;
  final String name;
  final String icon;
  final String type; // 'Garden Bed' or 'Pot/Container'
  final String bestFor;
  final String drainageNotes;
  final String diyTips;
  final String additionalInfo;

  const ContainerStyle({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.bestFor,
    required this.drainageNotes,
    required this.diyTips,
    required this.additionalInfo,
  });
}