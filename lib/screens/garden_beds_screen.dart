import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ui_settings_provider.dart';
import '../model/soil_bed_model.dart';

enum ActiveGardenMenu { none, soil, bedAndPots }

class GardenBedsScreen extends StatefulWidget {
  const GardenBedsScreen({super.key});

  @override
  State<GardenBedsScreen> createState() => _GardenBedsScreenState();
}

class _GardenBedsScreenState extends State<GardenBedsScreen> {
  ActiveGardenMenu _selectedMenu = ActiveGardenMenu.none;

  // Selected items for Master-Detail
  SoilComposition? _selectedSoil;
  ContainerStyle? _selectedContainer;

  // --- MOCK DATABASE: SOIL COMPOSITIONS (PH Context, Common -> Specialized) ---
  final List<SoilComposition> _soilList = const [
    SoilComposition(
      id: 's1',
      name: 'Loamy Soil Mix (Taniman Mix)',
      icon: '🪴',
      rarity: 'Most Common',
      composition: '40% Topsoil, 30% Vermicompost, 30% Carbonized Rice Husk (CRH)',
      bestFor: 'Nightshades (Talong, Kamatis), Legumes (Sitaw), Leafy Greens',
      avoidFor: 'Cacti, Succulents, Root crops needing loose pure sand',
      moistureRetention: 'High & Balanced (Drains well while holding moisture)',
      additionalInfo: 'The standard Philippine backyard mix. CRH prevents soil compaction while vermicompost provides sustained organic nitrogen.',
    ),
    SoilComposition(
      id: 's2',
      name: 'Sandy Loam (Buhanginhong Lupa)',
      icon: '🏖️',
      rarity: 'Common',
      composition: '50% Fine River Sand, 30% Garden Soil, 20% Organic Compost',
      bestFor: 'Root Vegetables (Lasona/Onions, Radish, Carrot), Sweet Potato',
      avoidFor: 'Heavy water-loving crops in peak summer without mulch',
      moistureRetention: 'Low-Medium (Drains rapidly, prevents root rot)',
      additionalInfo: 'Ideal for coastal or lowland tropical areas with heavy Tag-ulan rains to prevent waterlogging.',
    ),
    SoilComposition(
      id: 's3',
      name: 'Coco Peat & Perlite Mix (Soilless)',
      icon: '🥥',
      rarity: 'Uncommon / Specialized',
      composition: '70% Washed Coco Coir Dust, 20% Perlite / Pumice, 10% Worm Castings',
      bestFor: 'Seedling propagation, Potted Herbs, Urban Container Gardening',
      avoidFor: 'Heavy fruit trees requiring deep anchor roots',
      moistureRetention: 'Very High (Retains up to 8x its weight in water)',
      additionalInfo: 'Lightweight and sterile mix. Requires regular liquid fertigation as coco peat carries minimal natural nutrients.',
    ),
    SoilComposition(
      id: 's4',
      name: 'Pasteurized Mushroom Substrate',
      icon: '🍄',
      rarity: 'Specialized (Fungi)',
      composition: '78% Sawdust (Katalan), 20% Rice Bran (Darak), 1% Agricultural Lime, 1% Gypsum',
      bestFor: 'Oyster Mushrooms (Kabute), Volvariella, Saprophytic Fungi',
      avoidFor: 'Direct planting of standard vascular vegetables',
      moistureRetention: 'High (Kept in humid bags or dark grow chambers)',
      additionalInfo: 'Requires heat pasteurization or sterilization before inoculating with grain spawn to prevent mold contamination.',
    ),
  ];

  // --- MOCK DATABASE: GARDEN BEDS & POTS ---
  final List<ContainerStyle> _containerList = const [
    ContainerStyle(
      id: 'c1',
      name: 'Raised Wooden Garden Bed',
      icon: '🪵',
      type: 'Garden Bed',
      bestFor: 'Deep-root crops, companion planting (Bahay Kubo style plots)',
      drainageNotes: 'Excellent when bottom is open to ground or lined with gravel.',
      diyTips: 'Use untreated hardwood or reclaimed pallets. Seal wood with natural linseed oil. Aim for 12–18 inches depth.',
      additionalInfo: 'Keeps soil loose and uncompacted from foot traffic. Easier on the back during weeding.',
    ),
    ContainerStyle(
      id: 'c2',
      name: 'Recycled Container / Fabric Grow Bags',
      icon: '🛍️',
      type: 'Pot / Container',
      bestFor: 'Patio gardening, Solanaceous crops (Eggplant, Peppers), Potatoes',
      drainageNotes: 'Fabric naturally breathes and air-prunes roots; plastic pots require drilled bottom holes.',
      diyTips: 'Convert 5-gallon paint pails or sack bags (Sako). Drill 6–8 quarter-inch holes around the lower sidewalls, not just the bottom.',
      additionalInfo: 'Air-pruning in fabric bags prevents roots from circling and becoming root-bound.',
    ),
    ContainerStyle(
      id: 'c3',
      name: 'Hollow Block Bed (Concrete Masonry)',
      icon: '🧱',
      type: 'Garden Bed',
      bestFor: 'Permanent garden borders, boundary plots, perennial herbs',
      drainageNotes: 'Depends on subsoil; hollow cores can be filled with soil for small individual herb pockets.',
      diyTips: 'Stack 2–3 layers of concrete blocks without mortar for easy relocation, or line interior with garden fabric to retain soil.',
      additionalInfo: 'Extremely durable in tropical weather; concrete retains ambient heat which benefits root warmth.',
    ),
    ContainerStyle(
      id: 'c4',
      name: 'Sub-Irrigated Planter (Self-Watering Box)',
      icon: '🪣',
      type: 'Pot / Container',
      bestFor: 'Leafy greens (Pechay, Kangkong), Moisture-hungry vegetables',
      drainageNotes: 'Uses an overflow hole above the water reservoir to prevent drown-out during heavy downpours.',
      diyTips: 'Use two nested plastic buckets. Insert a PVC fill-pipe and a wicking column made from a net pot packed with soil mix.',
      additionalInfo: 'Drastically reduces watering frequency during dry season (Tag-init) by wicking water from below.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (_soilList.isNotEmpty) _selectedSoil = _soilList.first;
    if (_containerList.isNotEmpty) _selectedContainer = _containerList.first;
  }

  double _getScaleFactor(CardScale scale) {
    switch (scale) {
      case CardScale.small:
        return 0.85;
      case CardScale.medium:
        return 1.0;
      case CardScale.large:
        return 1.25;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        leading: _selectedMenu != ActiveGardenMenu.none
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedMenu = ActiveGardenMenu.none;
                  });
                },
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildBody(isWideScreen),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedMenu) {
      case ActiveGardenMenu.soil:
        return 'Soil Compositions';
      case ActiveGardenMenu.bedAndPots:
        return 'Beds & Pots Guide';
      case ActiveGardenMenu.none:
      default:
        return 'Soil & Garden Beds';
    }
  }

  Widget _buildBody(bool isWideScreen) {
    switch (_selectedMenu) {
      case ActiveGardenMenu.none:
        return _buildCategorySelectionMenu();
      case ActiveGardenMenu.soil:
        return _buildMasterDetailSoil(isWideScreen);
      case ActiveGardenMenu.bedAndPots:
        return _buildMasterDetailContainers(isWideScreen);
    }
  }

  // --- 1. SELECTION LANDING MENU ---
  Widget _buildCategorySelectionMenu() {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Almanac Category',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what you would like to explore or set up',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _buildMenuCard(
                  title: 'Soil Compositions',
                  subtitle: 'Explore local soil mixes, pH suitability, & moisture profiles',
                  icon: '🪨',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    setState(() {
                      _selectedMenu = ActiveGardenMenu.soil;
                    });
                  },
                ),
                _buildMenuCard(
                  title: 'Garden Beds & Pots',
                  subtitle: 'Styles, container designs, drainage & DIY building tips',
                  icon: '🪴',
                  color: theme.colorScheme.tertiary,
                  onTap: () {
                    setState(() {
                      _selectedMenu = ActiveGardenMenu.bedAndPots;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280,
      height: 220,
      child: Card(
        elevation: 2,
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. MASTER-DETAIL: SOILS ---
  Widget _buildMasterDetailSoil(bool isWideScreen) {
    if (isWideScreen) {
      return Row(
        children: [
          Expanded(flex: 5, child: _buildSoilGrid()),
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
          Expanded(
            flex: 6,
            child: _selectedSoil == null
                ? Center(child: Text('Select a soil mix', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                : _buildSoilDetailPanel(_selectedSoil!),
          ),
        ],
      );
    }
    return _buildSoilGrid(isMobile: true);
  }

  Widget _buildSoilGrid({bool isMobile = false}) {
    final cardScale = context.watch<UISettingsProvider>().cardScale;
    final scaleFactor = _getScaleFactor(cardScale);
    final layoutScale = 1.0 + (scaleFactor - 1.0) * 0.6;
    final theme = Theme.of(context);

    return GridView.builder(
      padding: EdgeInsets.all(12 * layoutScale),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: (isMobile ? 170.0 : 190.0) * layoutScale,
        mainAxisExtent: 210.0 * layoutScale,
        crossAxisSpacing: 10 * layoutScale,
        mainAxisSpacing: 10 * layoutScale,
      ),
      itemCount: _soilList.length,
      itemBuilder: (context, index) {
        final soil = _soilList[index];
        final isSelected = _selectedSoil?.id == soil.id;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedSoil = soil;
            });
            if (isMobile) {
              _showMobileBottomSheet(
                context,
                (scrollController) => _buildSoilDetailPanel(
                  soil,
                  scrollController: scrollController,
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected && !isMobile
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected && !isMobile
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            padding: EdgeInsets.all(10 * layoutScale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(soil.icon, style: TextStyle(fontSize: 38 * layoutScale)),
                SizedBox(height: 4 * layoutScale),
                Text(
                  soil.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13 * layoutScale,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Chip(
                    label: Text(
                      soil.rarity,
                      style: TextStyle(fontSize: 9 * layoutScale),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoilDetailPanel(SoilComposition soil, {ScrollController? scrollController}) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(soil.icon, style: const TextStyle(fontSize: 56)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      soil.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      soil.rarity,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          _detailRow(Icons.science, 'Soil Composition', soil.composition),
          _detailRow(Icons.check_circle_outline, 'Best For Crops', soil.bestFor),
          _detailRow(Icons.cancel_outlined, 'Affects Negatively', soil.avoidFor),
          _detailRow(Icons.water, 'Moisture Retention', soil.moistureRetention),
          const SizedBox(height: 12),
          const Text(
            'Additional Notes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            soil.additionalInfo,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. MASTER-DETAIL: BEDS & POTS ---
  Widget _buildMasterDetailContainers(bool isWideScreen) {
    if (isWideScreen) {
      return Row(
        children: [
          Expanded(flex: 5, child: _buildContainerGrid()),
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
          Expanded(
            flex: 6,
            child: _selectedContainer == null
                ? Center(child: Text('Select a style', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                : _buildContainerDetailPanel(_selectedContainer!),
          ),
        ],
      );
    }
    return _buildContainerGrid(isMobile: true);
  }

  Widget _buildContainerGrid({bool isMobile = false}) {
    final cardScale = context.watch<UISettingsProvider>().cardScale;
    final scaleFactor = _getScaleFactor(cardScale);
    final layoutScale = 1.0 + (scaleFactor - 1.0) * 0.6;
    final theme = Theme.of(context);

    return GridView.builder(
      padding: EdgeInsets.all(12 * layoutScale),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: (isMobile ? 170.0 : 190.0) * layoutScale,
        mainAxisExtent: 210.0 * layoutScale,
        crossAxisSpacing: 10 * layoutScale,
        mainAxisSpacing: 10 * layoutScale,
      ),
      itemCount: _containerList.length,
      itemBuilder: (context, index) {
        final item = _containerList[index];
        final isSelected = _selectedContainer?.id == item.id;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedContainer = item;
            });
            if (isMobile) {
              _showMobileBottomSheet(
                context,
                (scrollController) => _buildContainerDetailPanel(
                  item,
                  scrollController: scrollController,
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected && !isMobile
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected && !isMobile
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            padding: EdgeInsets.all(10 * layoutScale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.icon, style: TextStyle(fontSize: 38 * layoutScale)),
                SizedBox(height: 4 * layoutScale),
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13 * layoutScale,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Chip(
                    label: Text(
                      item.type,
                      style: TextStyle(fontSize: 9 * layoutScale),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContainerDetailPanel(ContainerStyle item, {ScrollController? scrollController}) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 56)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item.type,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          _detailRow(Icons.grass, 'Best Plant Match', item.bestFor),
          _detailRow(Icons.water_drop_outlined, 'Drainage Profile', item.drainageNotes),
          _detailRow(Icons.build_outlined, 'DIY & Building Tips', item.diyTips),
          const SizedBox(height: 12),
          const Text(
            'Usage Notes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            item.additionalInfo,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Detail Rows
  Widget _detailRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileBottomSheet(
    BuildContext context,
    Widget Function(ScrollController) builder,
  ) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return builder(scrollController);
          },
        );
      },
    );
  }
}