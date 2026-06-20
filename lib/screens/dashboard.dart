import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/hidden_gem_model.dart';
import '../models/location_model.dart';
import '../providers/repository_provider.dart';
import '../theme/cyber_theme.dart';
import 'director_camera_screen.dart';
import 'create_gem_screen.dart';
import 'gallery_screen.dart';
import 'gem_detail_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<HiddenGemModel> _allGems = [];
  List<HiddenGemModel> _filteredGems = [];
  late HiddenGemModel _selectedGem;
  bool _isLoading = true;

  // Search and Filter State
  final _searchController = TextEditingController();
  final List<String> _filterTags = [
    'Waterfall',
    'Viewpoint',
    'Temple',
    'Cafe',
    'Sunrise Spot',
    'Hidden Gem'
  ];
  final List<String> _selectedFilters = [];

  @override
  void initState() {
    super.initState();
    _loadGems();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _loadGems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await context.read<AppRepositoryProvider>().hiddenGemRepository.getHiddenGems();
      setState(() {
        _allGems = list;
        _isLoading = false;
        if (list.isNotEmpty) {
          _selectedGem = list[0];
        }
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error loading gems: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredGems = _allGems.where((gem) {
        final matchesQuery = gem.name.toLowerCase().contains(query) ||
            gem.description.toLowerCase().contains(query);
        final matchesTags = _selectedFilters.isEmpty ||
            _selectedFilters.every((tag) => gem.tags.contains(tag));
        return matchesQuery && matchesTags;
      }).toList();
    });
  }

  void _toggleFilter(String tag) {
    setState(() {
      if (_selectedFilters.contains(tag)) {
        _selectedFilters.remove(tag);
      } else {
        _selectedFilters.add(tag);
      }
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RESHOT AI',
          style: GoogleFonts.pressStart2p(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CyberTheme.limeGreen,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            tooltip: 'Explorer Console',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const ProfileScreen()),
              );
              // Reload in case custom profile changes affect stats rendering
              _loadGems();
            },
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            tooltip: 'Open Gallery',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const GalleryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
            tooltip: 'Add Hidden Gem',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const CreateGemScreen()),
              );
              if (result == true) {
                _loadGems(); // Reload list on successful save
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CyberTheme.limeGreen))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: CyberTheme.cartoonDecoration.copyWith(
                        color: CyberTheme.hotPink,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECREATE ANY PHOTO',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Frame the background composition, lock it, hand it to a stranger. ReShot captures automatically when aligned!',
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'COMPOSITION CAMERA',
                      style: textTheme.titleLarge?.copyWith(
                        color: CyberTheme.limeGreen,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Navigation launch tiles
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_allGems.isNotEmpty) {
                                _launchCamera(context, 'director');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: CyberTheme.cartoonDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    color: CyberTheme.hotPink,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'DIRECTOR\nMODE',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Handover Shutter Guide',
                                    style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_allGems.isNotEmpty) {
                                _launchCamera(context, 'echo');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: CyberTheme.cartoonDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.landscape_outlined,
                                    color: CyberTheme.limeGreen,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'LANDMARK\nECHO',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Landscape Edges Guide',
                                    style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Search Bar
                    Text(
                      'EXPLORE GEMS INDEX',
                      style: textTheme.titleLarge?.copyWith(
                        color: CyberTheme.limeGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search spots by name or description...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.search, color: CyberTheme.limeGreen),
                        filled: true,
                        fillColor: CyberTheme.cyberDark,
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black, width: 3),
                          borderRadius: BorderRadius.zero,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black, width: 3),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter chips list
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterTags.map((tag) {
                          final isSelected = _selectedFilters.contains(tag);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                tag.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.black : Colors.white70,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: CyberTheme.limeGreen,
                              backgroundColor: CyberTheme.cyberDark,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: isSelected ? Colors.black : Colors.white24,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.zero,
                              ),
                              onSelected: (_) => _toggleFilter(tag),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hidden Gems Explorer Cards
                    _filteredGems.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: CyberTheme.cartoonDecoration,
                            child: const Center(
                              child: Text(
                                'NO SPOTS FOUND MATCHING FILTERS',
                                style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredGems.length,
                            itemBuilder: (context, index) {
                              final gem = _filteredGems[index];
                              final isSelected = _allGems.isNotEmpty && gem.id == _selectedGem.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedGem = gem;
                                    });
                                  },
                                  onDoubleTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) => GemDetailScreen(gem: gem),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: isSelected
                                        ? CyberTheme.activeCardDecoration
                                        : CyberTheme.cartoonDecoration,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isSelected ? CyberTheme.limeGreen : CyberTheme.cyberGray,
                                            border: Border.all(color: Colors.black, width: 2),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.landscape,
                                              color: isSelected ? Colors.black : Colors.white54,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                gem.name,
                                                style: textTheme.titleLarge?.copyWith(fontSize: 16),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${gem.latitude.toStringAsFixed(4)}, ${gem.longitude.toStringAsFixed(4)}',
                                                style: GoogleFonts.pressStart2p(
                                                  fontSize: 8,
                                                  color: CyberTheme.hotPink,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),

                    // Quick Intel Box
                    if (_allGems.isNotEmpty && _filteredGems.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: CyberTheme.cartoonDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'RADAR DESCRIPTION',
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 8,
                                    color: CyberTheme.hotPink,
                                  ),
                                ),
                                Text(
                                  'ALT: ${_selectedGem.altitude}',
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 8,
                                    color: CyberTheme.limeGreen,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 16),
                            Text(
                              _selectedGem.description,
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              children: _selectedGem.tags.map((t) => Chip(
                                    label: Text(t.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white)),
                                    backgroundColor: Colors.black,
                                    padding: EdgeInsets.zero,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  )).toList(),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CyberTheme.limeGreen,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.black, width: 3),
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              onPressed: () => _launchCamera(context, 'director'),
                              child: Text(
                                'LAUNCH DIRECTOR CAMERA',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _launchCamera(BuildContext ctx, String mode) {
    final activeGem = _filteredGems.isNotEmpty ? _selectedGem : _allGems[0];
    final location = LocationModel(
      id: activeGem.id,
      name: activeGem.name,
      distance: 'Radar locked',
      description: activeGem.description,
      latitude: activeGem.latitude,
      longitude: activeGem.longitude,
      altitude: activeGem.altitude,
      tips: [
        'Recommended lens: Wide Angle',
        'Subject: Center lower-third',
        'Light: Morning golden hour'
      ],
    );

    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (c) => DirectorCameraScreen(
          location: location,
          mode: mode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
