import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/reshot_capture_model.dart';
import '../models/profile_model.dart';
import '../providers/repository_provider.dart';
import '../theme/cyber_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingStats = true;

  // Derived Stats
  int _totalCaptures = 0;
  int _customGemsCount = 0;
  double _averageAccuracy = 0.0;
  List<ReShotCaptureModel> _captures = [];

  // Achievement definitions
  final List<Map<String, dynamic>> _achievementDefinitions = [
    {
      'id': 'first_capture',
      'title': 'FIRST RECREATION',
      'description': 'Capture your first ReShot',
      'icon': Icons.camera_alt_outlined,
    },
    {
      'id': 'reshots_10',
      'title': 'DECATHLON',
      'description': 'Capture 10 ReShots',
      'icon': Icons.photo_library_outlined,
    },
    {
      'id': 'reshots_50',
      'title': 'HALF CENTURY',
      'description': 'Capture 50 ReShots',
      'icon': Icons.stars_outlined,
    },
    {
      'id': 'first_gem',
      'title': 'GEM SEEKER',
      'description': 'Discover your first Hidden Gem',
      'icon': Icons.map_outlined,
    },
    {
      'id': 'gems_5',
      'title': 'GEM ELITE',
      'description': 'Discover 5 Hidden Gems',
      'icon': Icons.diamond_outlined,
    },
    {
      'id': 'match_90_club',
      'title': '90% CLUB',
      'description': 'Achieve a 90%+ match score',
      'icon': Icons.workspace_premium_outlined,
    },
    {
      'id': 'legendary_shot',
      'title': 'LEGEND SHOT',
      'description': 'Achieve a 95%+ match score',
      'icon': Icons.flash_on_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDerivedStats();
  }

  Future<void> _loadDerivedStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final provider = context.read<AppRepositoryProvider>();
      final captures = await provider.galleryRepository.getCaptures();
      final gems = await provider.hiddenGemRepository.getHiddenGems();

      // Count custom user-added gems (excluding standard default seed coordinates)
      const defaultIds = {
        '7f3e2a1c-4b5d-4e6f-8a9b-0c1d2e3f4a5b',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'f9e8d7c6-b5a4-3210-fedc-ba9876543210',
      };
      final customGems = gems.where((g) => !defaultIds.contains(g.id)).length;

      // Calculate accuracy average from raw scores
      double totalAccuracy = 0.0;
      if (captures.isNotEmpty) {
        totalAccuracy = captures.map((c) => c.score).reduce((a, b) => a + b);
      }
      final average = captures.isEmpty ? 0.0 : totalAccuracy / captures.length;

      setState(() {
        _captures = captures;
        _totalCaptures = captures.length;
        _customGemsCount = customGems;
        _averageAccuracy = average;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Error loading profile stats: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditNameDialog(String currentName, AppRepositoryProvider provider) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.cyberBlack,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'UPDATE_IDENTITY.EXE',
          style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'EXPLORER ALIAS',
            labelStyle: TextStyle(color: CyberTheme.hotPink),
            filled: true,
            fillColor: CyberTheme.cyberDark,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: CyberTheme.limeGreen, width: 2),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.limeGreen,
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: Colors.black, width: 2),
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await provider.updateProfileName(newName);
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'CONFIRM',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer<AppRepositoryProvider>(
      builder: (context, provider, child) {
        final profile = provider.profile;
        final progress = provider.getLevelProgress();
        final rank = provider.getRank();
        final formattedJoinDate = 
            'JOINED ${profile.joinDate.day}/${profile.joinDate.month}/${profile.joinDate.year}';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'EXPLORER_CONSOLE.SYS',
              style: GoogleFonts.pressStart2p(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: CyberTheme.limeGreen,
              ),
            ),
          ),
          body: Column(
            children: [
              // HUD Header Panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: CyberTheme.cyberDark,
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Cyber circular avatar frame
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: CyberTheme.cyberGray,
                            border: Border.all(color: CyberTheme.hotPink, width: 3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 32,
                            color: CyberTheme.hotPink,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      profile.explorerName,
                                      style: textTheme.titleLarge?.copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: CyberTheme.limeGreen, size: 20),
                                    onPressed: () => _showEditNameDialog(profile.explorerName, provider),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    color: CyberTheme.limeGreen,
                                    child: Text(
                                      rank.toUpperCase(),
                                      style: GoogleFonts.pressStart2p(
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedJoinDate,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontSize: 10,
                                      color: Colors.white30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // XP Neon Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'XP: ${progress['totalCurrent']}',
                          style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white70),
                        ),
                        Text(
                          progress['totalCurrent'] >= 2000 
                              ? 'MAX LEVEL' 
                              : 'NEXT: ${progress['totalTarget']} XP',
                          style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: progress['percent'],
                            child: Container(
                              color: CyberTheme.limeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TabBar Navigation
              Container(
                color: CyberTheme.cyberDark,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: CyberTheme.limeGreen,
                  labelColor: CyberTheme.limeGreen,
                  unselectedLabelColor: Colors.white30,
                  labelStyle: GoogleFonts.pressStart2p(fontSize: 8, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'INTEL & ARCHIVES'),
                    Tab(text: 'TIMELINE.LOG'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: _isLoadingStats
                    ? const Center(child: CircularProgressIndicator(color: CyberTheme.limeGreen))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Stats & Achievements
                          _buildStatsAndAchievementsTab(context, textTheme, profile),

                          // Tab 2: Timeline list of recreations
                          _buildTimelineTab(context, textTheme),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsAndAchievementsTab(BuildContext context, TextTheme textTheme, ProfileModel profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard('CAPTURED', _totalCaptures.toString(), CyberTheme.hotPink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('GEM_FOUND', _customGemsCount.toString(), CyberTheme.limeGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'ACCURACY',
                  '${_averageAccuracy.toStringAsFixed(1)}%',
                  Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Achievements Title
          Text(
            'EXPLORATION AWARDS',
            style: textTheme.titleLarge?.copyWith(
              color: CyberTheme.limeGreen,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          // Grid of Achievements
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _achievementDefinitions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (ctx, idx) {
              final ach = _achievementDefinitions[idx];
              final isUnlocked = profile.unlockedAchievementIds.contains(ach['id']);

              return Opacity(
                opacity: isUnlocked ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: isUnlocked 
                      ? CyberTheme.activeCardDecoration 
                      : CyberTheme.cartoonDecoration.copyWith(
                          color: CyberTheme.cyberDark.withAlpha(128),
                        ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        ach['icon'] as IconData,
                        color: isUnlocked ? CyberTheme.limeGreen : Colors.white24,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ach['title'] as String,
                        style: GoogleFonts.pressStart2p(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.white : Colors.white30,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ach['description'] as String,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          color: isUnlocked ? Colors.white70 : Colors.white24,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: CyberTheme.cartoonDecoration,
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.pressStart2p(fontSize: 7, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(BuildContext context, TextTheme textTheme) {
    if (_captures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: CyberTheme.cartoonDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history,
                  color: CyberTheme.hotPink,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'TIMELINE EMPTY',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your captured recreations history logs will register here chronologically.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _captures.length,
      itemBuilder: (ctx, idx) {
        final capture = _captures[idx];
        final formattedDate = 
            '${capture.timestamp.day}/${capture.timestamp.month}/${capture.timestamp.year.toString().substring(2)}';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline connector graphic
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: CyberTheme.limeGreen,
                      border: Border.all(color: Colors.black, width: 2.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: idx == _captures.length - 1
                        ? Container()
                        : Container(
                            width: 3,
                            color: Colors.white12,
                          ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Timeline Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: CyberTheme.cartoonDecoration.copyWith(
                      color: Colors.white, // classic polaroid backplate
                    ),
                    child: Row(
                      children: [
                        // Polaroid Mini image box
                        Container(
                          width: 60,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: kIsWeb || capture.filePath.startsWith('http')
                              ? Image.network(
                                  capture.filePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.broken_image,
                                    color: CyberTheme.hotPink,
                                    size: 16,
                                  ),
                                )
                              : Image.file(
                                  File(capture.filePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.broken_image,
                                    color: CyberTheme.hotPink,
                                    size: 16,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Meta details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                capture.locationName.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${capture.displayScore}% MATCH',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: CyberTheme.hotPink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
