// lib/screens/seed_index_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/seed_model.dart';
import '../providers/seed_repository.dart';
import '../providers/ui_settings_provider.dart';

class SeedIndexScreen extends StatefulWidget {
  const SeedIndexScreen({super.key});

  @override
  State<SeedIndexScreen> createState() => _SeedIndexScreenState();
}

class _SeedIndexScreenState extends State<SeedIndexScreen> {
  String _selectedCategory = 'All';
  Seed? _selectedSeed;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Herbs',
    'Fungi'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Helper widget for the detail view image or emoji
  Widget _buildDetailImage(String placeholder, {required double size}) {
    if (placeholder.startsWith('assets/') || placeholder.contains('.')) {
      return Image.asset(
        placeholder,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Text(
          '🌱',
          style: TextStyle(fontSize: size * 0.7),
        ),
      );
    } else {
      return Text(
        placeholder,
        style: TextStyle(fontSize: size * 0.7),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read scale factor once at the top of the build tree
    final scaleFactor = context.watch<UISettingsProvider>().scaleFactor;
    final layoutScale = 1.0 + (scaleFactor - 1.0) * 0.6;

    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    // Fetch master list from SeedRepository
    final allSeeds = context.watch<SeedRepository>().seeds;

    // Filter seeds according to current category chip selection AND search text
    final filteredSeeds = allSeeds.where((s) {
      final matchesCategory =
          _selectedCategory == 'All' || s.category == _selectedCategory;
      final matchesSearch = s.localName.toLowerCase().contains(_searchQuery) ||
          s.englishName.toLowerCase().contains(_searchQuery) ||
          s.scientificName.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    // Auto-select the first seed if non-null or when list changes
    if (_selectedSeed == null && filteredSeeds.isNotEmpty) {
      _selectedSeed = filteredSeeds.first;
    } else if (filteredSeeds.isNotEmpty &&
        !filteredSeeds.any((s) => s.id == _selectedSeed?.id)) {
      _selectedSeed = filteredSeeds.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Almanac Index',
          style: TextStyle(fontSize: 20 * scaleFactor),
        ),
      ),
      body: Column(
        children: [
          // Search Bar (Top Priority)
          Padding(
            padding: EdgeInsets.fromLTRB(
              16 * layoutScale,
              12 * layoutScale,
              16 * layoutScale,
              4 * layoutScale,
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14 * scaleFactor),
              decoration: InputDecoration(
                hintText: 'Search by local, English, or scientific name...',
                hintStyle: TextStyle(fontSize: 14 * scaleFactor),
                prefixIcon: Icon(Icons.search, size: 22 * scaleFactor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20 * scaleFactor),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12 * layoutScale),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16 * layoutScale,
                  vertical: 12 * layoutScale,
                ),
              ),
            ),
          ),

          // Category Filter Bar (Below Search)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: 16 * layoutScale,
              vertical: 8 * layoutScale,
            ),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: EdgeInsets.only(right: 8 * layoutScale),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(fontSize: 13 * scaleFactor),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Main Content Body (Master-Detail Layout)
          Expanded(
            child: isWideScreen
                ? Row(
                    children: [
                      // Left Panel: Cards Grid/List
                      Expanded(
                        flex: 5,
                        child: _buildSeedGrid(
                          filteredSeeds,
                          scaleFactor: scaleFactor,
                          layoutScale: layoutScale,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      // Right Panel: Detailed Almanac Entry
                      Expanded(
                        flex: 6,
                        child: _selectedSeed == null
                            ? Center(
                                child: Text(
                                  'Select an entry from the almanac',
                                  style: TextStyle(
                                    fontSize: 14 * scaleFactor,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              )
                            : _buildDetailPanel(
                                context,
                                _selectedSeed!,
                                scaleFactor: scaleFactor,
                                layoutScale: layoutScale,
                              ),
                      ),
                    ],
                  )
                : _buildSeedGrid(
                    filteredSeeds,
                    isMobile: true,
                    scaleFactor: scaleFactor,
                    layoutScale: layoutScale,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedGrid(
    List<Seed> seeds, {
    bool isMobile = false,
    required double scaleFactor,
    required double layoutScale,
  }) {
    if (seeds.isEmpty) {
      return Center(
        child: Text(
          'No entries found matching your filters.',
          style: TextStyle(
            fontSize: 14 * scaleFactor,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final baseExtent = isMobile ? 170.0 : 190.0;
    final maxCrossAxisExtent = baseExtent * layoutScale;
    final mainAxisExtent = 210.0 * layoutScale;

    return GridView.builder(
      padding: EdgeInsets.all(12 * layoutScale),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisExtent: mainAxisExtent,
        crossAxisSpacing: 10 * layoutScale,
        mainAxisSpacing: 10 * layoutScale,
      ),
      itemCount: seeds.length,
      itemBuilder: (context, index) {
        final seed = seeds[index];
        final isSelected = _selectedSeed?.id == seed.id;
        final hasAssetImage = seed.imagePlaceholder.startsWith('assets/') ||
            seed.imagePlaceholder.contains('.');

        return InkWell(
          borderRadius: BorderRadius.circular(12 * layoutScale),
          onTap: () {
            setState(() {
              _selectedSeed = seed;
            });
            if (isMobile) {
              _showMobileDetailSheet(
                context,
                seed,
                scaleFactor: scaleFactor,
                layoutScale: layoutScale,
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12 * layoutScale),
              border: Border.all(
                color: isSelected && !isMobile
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Layer (Asset Image or Emoji Fallback)
                if (hasAssetImage)
                  Image.asset(
                    seed.imagePlaceholder,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                  )
                else
                  Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Text(
                        seed.imagePlaceholder,
                        style: TextStyle(
                          fontSize: 48 * layoutScale,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),

                // 2. Dark Scrim Gradient Overlay for Text Readability
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),

                // 3. Card Content Foreground
                Padding(
                  padding: EdgeInsets.all(10 * layoutScale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        seed.localName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * scaleFactor,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        seed.englishName,
                        style: TextStyle(
                          fontSize: 11 * scaleFactor,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6 * layoutScale),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Chip(
                          label: Text(
                            seed.category,
                            style: TextStyle(fontSize: 10 * scaleFactor),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPanel(
    BuildContext context,
    Seed seed, {
    required double scaleFactor,
    required double layoutScale,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.0 * layoutScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80 * scaleFactor,
                height: 80 * scaleFactor,
                child: Center(
                  child: _buildDetailImage(
                    seed.imagePlaceholder,
                    size: 72 * scaleFactor,
                  ),
                ),
              ),
              SizedBox(width: 16 * layoutScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seed.localName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24 * scaleFactor,
                          ),
                    ),
                    Text(
                      '${seed.englishName} • ${seed.scientificName}',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14 * scaleFactor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 32 * layoutScale),
          _detailRow(
            context,
            Icons.category,
            'Subgroup',
            seed.subgroup,
            scaleFactor: scaleFactor,
            layoutScale: layoutScale,
          ),
          _detailRow(
            context,
            Icons.layers,
            'Ideal Soil Type',
            seed.idealSoil,
            scaleFactor: scaleFactor,
            layoutScale: layoutScale,
          ),
          _detailRow(
            context,
            Icons.wb_sunny,
            'Season (PH Climate)',
            seed.growingSeason,
            scaleFactor: scaleFactor,
            layoutScale: layoutScale,
          ),
          _detailRow(
            context,
            Icons.water_drop,
            'Watering Frequency',
            seed.wateringFreq,
            scaleFactor: scaleFactor,
            layoutScale: layoutScale,
          ),
          _detailRow(
            context,
            Icons.bug_report,
            'Pest Control',
            seed.pestControl,
            scaleFactor: scaleFactor,
            layoutScale: layoutScale,
          ),
          SizedBox(height: 16 * layoutScale),
          Text(
            'Almanac Notes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16 * scaleFactor,
            ),
          ),
          SizedBox(height: 6 * layoutScale),
          Text(
            seed.additionalInfo,
            style: TextStyle(
              fontSize: 14 * scaleFactor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    required double scaleFactor,
    required double layoutScale,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.0 * layoutScale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20 * scaleFactor,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 12 * layoutScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12 * scaleFactor,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 14 * scaleFactor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileDetailSheet(
    BuildContext context,
    Seed seed, {
    required double scaleFactor,
    required double layoutScale,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: _buildDetailPanel(
                context,
                seed,
                scaleFactor: scaleFactor,
                layoutScale: layoutScale,
              ),
            );
          },
        );
      },
    );
  }
}