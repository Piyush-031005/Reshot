import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/hidden_gem_model.dart';
import '../models/location_model.dart';
import '../providers/repository_provider.dart';
import '../theme/cyber_theme.dart';
import '../theme/design_system.dart';
import '../theme/motion_system.dart';
import 'director_camera_screen.dart';
import 'create_gem_screen.dart';
import 'image_upload_screen.dart';
import 'gallery_screen.dart';
import 'gem_detail_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  List<HiddenGemModel> _allGems = [];
  List<HiddenGemModel> _filteredGems = [];
  late HiddenGemModel _selectedGem;
  bool _isLoading = true;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  late final AnimationController _bannerController;
  late final Animation<double> _bannerBounce;

  late final AnimationController _bannerPulseController;
  late final Animation<double> _bannerPulse;

  // Search and Filter State
  final _searchController = TextEditingController();
  final List<String> _filterTags = [
    'Waterfall',
    'Viewpoint',
    'Temple',
    'Cafe',
    'Sunrise Spot',
    'Hidden Gem',
  ];
  final List<String> _selectedFilters = [];

  @override
  void initState() {
    super.initState();
    _loadGems();
    _startLocationTracking();
    _searchController.addListener(_applyFilters);

    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _bannerBounce = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.elasticOut,
    );

    _bannerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bannerPulse = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _bannerPulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _bannerController.dispose();
    _bannerPulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _applyFilters();
        });
      }
    });
  }

  Future<void> _loadGems() async {
    setState(() => _isLoading = true);
    try {
      final list = await context
          .read<AppRepositoryProvider>()
          .hiddenGemRepository
          .getHiddenGems();
      setState(() {
        _allGems = list;
        _isLoading = false;
        if (list.isNotEmpty) _selectedGem = list[0];
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Error loading gems: $e');
      setState(() => _isLoading = false);
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

      if (_currentPosition != null) {
        _filteredGems.sort((a, b) {
          final distA = Geolocator.distanceBetween(
              _currentPosition!.latitude, _currentPosition!.longitude, a.latitude, a.longitude);
          final distB = Geolocator.distanceBetween(
              _currentPosition!.latitude, _currentPosition!.longitude, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
      }
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
    return Scaffold(
      backgroundColor: ReShotDesignSystem.creamBg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Banner (Street Pop)
                  MotionSystem.elasticBounce(
                    scaleDown: 0.95,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const ImageUploadScreen()),
                      );
                    },
                    child: _buildHeroBanner(),
                  ),
                  const SizedBox(height: 28),

                  // Camera Modes Section
                  _buildSectionLabel('📸 COMPOSITION CAMERA'),
                  const SizedBox(height: 12),
                  _buildCameraModeTiles(),
                  const SizedBox(height: 28),

                  // Explore Gems Section
                  _buildSectionLabel('💎 EXPLORE GEMS'),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                  _buildGemsList(),
                  const SizedBox(height: 20),

                  // Radar Panel
                  if (_allGems.isNotEmpty && _filteredGems.isNotEmpty)
                    _buildRadarPanel(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: ReShotDesignSystem.creamBg,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ReShotDesignSystem.neonLime,
              borderRadius: BorderRadius.circular(12),
              border: ReShotDesignSystem.brutalistBorder,
              boxShadow: ReShotDesignSystem.brutalistShadow,
            ),
            child: const Center(
              child: Text('📷', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'ReSHOT',
            style: ReShotDesignSystem.textTheme.displayMedium!.copyWith(
              color: ReShotDesignSystem.inkBlack,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      actions: [
        _buildAppBarIcon(Icons.account_circle_rounded, ReShotDesignSystem.cyberCyan, () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const ProfileScreen()),
          );
          _loadGems();
        }),
        _buildAppBarIcon(Icons.photo_library_rounded, ReShotDesignSystem.hotPink, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const GalleryScreen()),
          );
        }),
        _buildAppBarIcon(Icons.add_location_alt_rounded, ReShotDesignSystem.sunOrange, () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const CreateGemScreen()),
          );
          if (result == true) _loadGems();
        }),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6, top: 8, bottom: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: CyberTheme.cartoonCard,
            child: Column(
              children: [
                const Text('🌊', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'Loading Gems...',
                  style: GoogleFonts.boogaloo(fontSize: 18, color: CyberTheme.inkBlack),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  color: CyberTheme.limeGreen,
                  backgroundColor: CyberTheme.cream,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: ReShotDesignSystem.streetPopColoredCard(ReShotDesignSystem.hotPink),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📸 AI RECREATION',
                  style: ReShotDesignSystem.textTheme.displaySmall!.copyWith(
                    color: ReShotDesignSystem.cardWhite,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ReShotDesignSystem.inkBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: ReShotDesignSystem.brutalistBorder,
                  ),
                  child: Text(
                    'TAP TO UPLOAD IMAGE',
                    style: ReShotDesignSystem.textTheme.titleMedium!.copyWith(
                      color: ReShotDesignSystem.neonLime,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Let AI analyze any photo and find the real-world location for you to recreate!',
                  style: ReShotDesignSystem.textTheme.bodyMedium!.copyWith(
                    color: ReShotDesignSystem.cardWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ReShotDesignSystem.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: ReShotDesignSystem.brutalistBorder,
            ),
            child: const Text('✨', style: TextStyle(fontSize: 32)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ReShotDesignSystem.inkBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: ReShotDesignSystem.textTheme.titleMedium!.copyWith(
          color: ReShotDesignSystem.cardWhite,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCameraModeTiles() {
    return Row(
      children: [
        Expanded(
          child: _CameraModeCard(
            emoji: '🎬',
            title: 'DIRECTOR\nMODE',
            subtitle: 'Handover Shutter Guide',
            accentColor: CyberTheme.limeGreen,
            onTap: () {
              if (_allGems.isNotEmpty) _launchCamera(context, 'director');
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _CameraModeCard(
            emoji: '🏔️',
            title: 'LANDMARK\nECHO',
            subtitle: 'Landscape Edges Guide',
            accentColor: CyberTheme.electricBlue,
            onTap: () {
              if (_allGems.isNotEmpty) _launchCamera(context, 'echo');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.nunito(
        color: CyberTheme.inkBlack,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Search spots...',
        hintStyle: GoogleFonts.nunito(color: const Color(0xFFAAAAAA), fontWeight: FontWeight.w500),
        prefixIcon: const Icon(Icons.search_rounded, color: CyberTheme.limeGreen),
        filled: true,
        fillColor: CyberTheme.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CyberTheme.outlineBlack, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CyberTheme.limeGreen, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filterTags.map((tag) {
          final isSelected = _selectedFilters.contains(tag);
          final color = CyberTheme.gemTypeColor(tag);
          final emoji = CyberTheme.gemTypeEmoji(tag);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _toggleFilter(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : CyberTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? CyberTheme.outlineBlack : const Color(0xFFCCCCCC),
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: CyberTheme.outlineBlack,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '$emoji ${tag.toUpperCase()}',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? CyberTheme.inkBlack : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGemsList() {
    if (_filteredGems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: CyberTheme.cartoonCard,
        child: Column(
          children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No spots found',
              style: GoogleFonts.boogaloo(fontSize: 18, color: CyberTheme.inkBlack),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your filters or add a new gem!',
              style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF888888)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredGems.length,
      itemBuilder: (context, index) {
        final gem = _filteredGems[index];
        final isSelected = _allGems.isNotEmpty && gem.id == _selectedGem.id;
        final primaryTag = gem.tags.isNotEmpty ? gem.tags[0] : 'Hidden Gem';
        final tagColor = CyberTheme.gemTypeColor(primaryTag);
        final emoji = CyberTheme.gemTypeEmoji(primaryTag);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PressableCard(
            onTap: () => setState(() => _selectedGem = gem),
            onDoubleTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => GemDetailScreen(gem: gem)),
            ),
            decoration: isSelected ? CyberTheme.activeCartoonCard : CyberTheme.cartoonCard,
            child: Row(
              children: [
                // Emoji badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tagColor, width: 2.5),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gem.name,
                        style: GoogleFonts.boogaloo(
                          fontSize: 16,
                          color: CyberTheme.inkBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${gem.latitude.toStringAsFixed(4)}, ${gem.longitude.toStringAsFixed(4)}',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: tagColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isSelected ? CyberTheme.limeGreen : const Color(0xFFCCCCCC),
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadarPanel() {
    return Container(
      width: double.infinity,
      decoration: CyberTheme.cartoonCard,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: CyberTheme.inkBlack,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Text('📡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'RADAR',
                  style: GoogleFonts.boogaloo(
                    fontSize: 16,
                    color: CyberTheme.limeGreen,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: CyberTheme.limeGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _currentPosition != null 
                        ? '🧭 ${(Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, _selectedGem.latitude, _selectedGem.longitude)).toStringAsFixed(0)}m'
                        : '🧭 LOCATING...',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: CyberTheme.inkBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedGem.name,
                  style: GoogleFonts.boogaloo(fontSize: 22, color: CyberTheme.inkBlack),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedGem.description,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF555555),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // Tags wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _selectedGem.tags.map((t) {
                    final tc = CyberTheme.gemTypeColor(t);
                    final te = CyberTheme.gemTypeEmoji(t);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tc.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tc, width: 2),
                      ),
                      child: Text(
                        '$te ${t.toUpperCase()}',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: tc,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Launch button
                _PressableButton(
                  onTap: () => _launchCamera(context, 'director'),
                  color: CyberTheme.limeGreen,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎬', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'LAUNCH DIRECTOR CAMERA',
                        style: GoogleFonts.boogaloo(
                          fontSize: 15,
                          color: CyberTheme.inkBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
        'Light: Morning golden hour',
      ],
    );

    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (c) => DirectorCameraScreen(location: location, mode: mode),
      ),
    );
  }
}

// ─── Reusable Pressable Card ──────────────────────────────────────────────────
class _PressableCard extends StatelessWidget {
  final Widget child;
  final BoxDecoration decoration;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const _PressableCard({
    required this.child,
    required this.decoration,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return MotionSystem.elasticBounce(
      onTap: () {
        if (onTap != null) onTap!();
      },
      scaleDown: 0.95,
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

// ─── Reusable Pressable Button ────────────────────────────────────────────────
class _PressableButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  const _PressableButton({
    required this.child,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MotionSystem.elasticBounce(
      onTap: () {
        if (onTap != null) onTap!();
      },
      scaleDown: 0.92,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: ReShotDesignSystem.streetPopColoredCard(color),
        child: child,
      ),
    );
  }
}

// ─── Camera Mode Card (Tarot Card Style) ───────────────────────────────────────
class _CameraModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _CameraModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MotionSystem.elasticBounce(
      onTap: onTap,
      scaleDown: 0.95,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: ReShotDesignSystem.streetPopCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor, width: 2.5),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: ReShotDesignSystem.textTheme.titleMedium!.copyWith(
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: ReShotDesignSystem.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
