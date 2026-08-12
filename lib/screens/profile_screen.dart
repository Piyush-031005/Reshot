import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/reshot_capture_model.dart';
import '../models/profile_model.dart';
import '../providers/repository_provider.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cartoon_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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
      'title': 'FIRST SHOT',
      'description': 'Capture your first ReShot',
      'emoji': '📸',
    },
    {
      'id': 'reshots_10',
      'title': 'DECATHLON',
      'description': 'Capture 10 ReShots',
      'emoji': '🔟',
    },
    {
      'id': 'reshots_50',
      'title': 'HALF CENTURY',
      'description': 'Capture 50 ReShots',
      'emoji': '🌟',
    },
    {
      'id': 'first_gem',
      'title': 'GEM SEEKER',
      'description': 'Discover your first Hidden Gem',
      'emoji': '💎',
    },
    {
      'id': 'gems_5',
      'title': 'GEM ELITE',
      'description': 'Discover 5 Hidden Gems',
      'emoji': '🏆',
    },
    {
      'id': 'match_90_club',
      'title': '90% CLUB',
      'description': 'Achieve a 90%+ match score',
      'emoji': '🎯',
    },
    {
      'id': 'legendary_shot',
      'title': 'LEGEND SHOT',
      'description': 'Achieve a 95%+ match score',
      'emoji': '⚡',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDerivedStats();
  }

  Future<void> _loadDerivedStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final provider = context.read<AppRepositoryProvider>();
      final captures = await provider.galleryRepository.getCaptures();
      final gems = await provider.hiddenGemRepository.getHiddenGems();

      const defaultIds = {
        '7f3e2a1c-4b5d-4e6f-8a9b-0c1d2e3f4a5b',
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'f9e8d7c6-b5a4-3210-fedc-ba9876543210',
      };
      final customGems = gems.where((g) => !defaultIds.contains(g.id)).length;

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
      setState(() => _isLoadingStats = false);
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: CyberTheme.cardWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CyberTheme.outlineBlack, width: 4),
            boxShadow: const [
              BoxShadow(
                color: CyberTheme.outlineBlack,
                offset: Offset(8, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CyberTheme.electricBlue,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  border: const Border(
                    bottom: BorderSide(color: CyberTheme.outlineBlack, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('✏️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Text(
                      'Edit Name',
                      style: GoogleFonts.boogaloo(
                        fontSize: 22,
                        color: CyberTheme.cardWhite,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w600,
                        color: CyberTheme.inkBlack,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Explorer Name',
                        labelStyle: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: CyberTheme.electricBlue,
                        ),
                        filled: true,
                        fillColor: CyberTheme.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: CyberTheme.outlineBlack, width: 2.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: CyberTheme.electricBlue, width: 3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: CyberTheme.cream,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCCCCCC), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.boogaloo(fontSize: 16, color: const Color(0xFF888888)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final newName = controller.text.trim();
                              if (newName.isNotEmpty) {
                                await provider.updateProfileName(newName);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: CyberTheme.electricBlue,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: CyberTheme.outlineBlack, width: 4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: CyberTheme.outlineBlack,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '✓ Confirm',
                                  style: GoogleFonts.boogaloo(fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showDebugSyncMenu(BuildContext ctx, AppRepositoryProvider provider) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: CyberTheme.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🛠️ FIREBASE VERIFICATION',
              style: GoogleFonts.boogaloo(fontSize: 22, color: CyberTheme.inkBlack),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Anonymous UID: ${provider.syncService.authService.currentUid ?? "Not signed in"}',
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: CyberTheme.cartoonButton(bg: CyberTheme.limeGreen),
              onPressed: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Forcing Sync to Firebase...', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    backgroundColor: CyberTheme.inkBlack,
                  ),
                );
                await provider.syncService.syncAll();
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Sync Complete! Check Firestore.', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                      backgroundColor: CyberTheme.limeGreen,
                    ),
                  );
                }
              },
              child: const Text('FORCE SYNC ALL TO CLOUD'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<AppRepositoryProvider>(
      builder: (context, provider, child) {
        final profile = provider.profile;
        final progress = provider.getLevelProgress();
        final rank = provider.getRank();

        return Scaffold(
          backgroundColor: CyberTheme.cream,
          appBar: AppBar(
            backgroundColor: CyberTheme.cream,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CyberTheme.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CyberTheme.outlineBlack, width: 2),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: CyberTheme.inkBlack, size: 20),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧭', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'EXPLORER',
                  style: GoogleFonts.boogaloo(
                    fontSize: 22,
                    color: CyberTheme.inkBlack,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Profile Header Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: CyberTheme.cartoonCard,
                child: Column(
                  children: [
                    // Profile row
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar circle
                          GestureDetector(
                            onLongPress: () => _showDebugSyncMenu(context, provider),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: CyberTheme.hotPink.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: CyberTheme.hotPink, width: 4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: CyberTheme.outlineBlack,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text('🧑‍🏕️', style: TextStyle(fontSize: 30)),
                              ),
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
                                        style: GoogleFonts.boogaloo(
                                          fontSize: 22,
                                          color: CyberTheme.inkBlack,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showEditNameDialog(
                                          profile.explorerName, provider),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: CyberTheme.electricBlue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: CyberTheme.electricBlue,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit_rounded,
                                          color: CyberTheme.electricBlue,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Rank badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: CyberTheme.limeGreen,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: CyberTheme.outlineBlack, width: 2),
                                  ),
                                  child: Text(
                                    '⭐ ${rank.toUpperCase()}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: CyberTheme.inkBlack,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // XP Bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '⚡ ${progress['totalCurrent']} XP',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: CyberTheme.inkBlack,
                                ),
                              ),
                              Text(
                                progress['totalCurrent'] >= 2000
                                    ? '🏆 MAX LEVEL'
                                    : 'Next: ${progress['totalTarget']} XP',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Candy-stripe XP bar
                          Container(
                            width: double.infinity,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: CyberTheme.outlineBlack, width: 2.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor:
                                    (progress['percent'] as double).clamp(0.0, 1.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [CyberTheme.limeGreen, Color(0xFF8EE000)],
                                    ),
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TabBar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CyberTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CyberTheme.outlineBlack, width: 4),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: CyberTheme.inkBlack,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: CyberTheme.limeGreen,
                  unselectedLabelColor: const Color(0xFF888888),
                  labelStyle: GoogleFonts.boogaloo(fontSize: 16, letterSpacing: 1),
                  unselectedLabelStyle: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w800),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(height: 48, text: '📊 STATS & AWARDS'),
                    Tab(height: 48, text: '📅 TIMELINE'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tab content
              Expanded(
                child: _isLoadingStats
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.all(32),
                          padding: const EdgeInsets.all(24),
                          decoration: CyberTheme.cartoonCard,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⏳', style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 12),
                              Text(
                                'Loading stats...',
                                style: GoogleFonts.boogaloo(
                                    fontSize: 18, color: CyberTheme.inkBlack),
                              ),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildStatsAndAchievementsTab(profile),
                          _buildTimelineTab(),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsAndAchievementsTab(ProfileModel profile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          Row(
            children: [
              Expanded(
                child: CartoonStatBox(
                  value: _totalCaptures.toString(),
                  label: 'CAPTURED',
                  emoji: '📸',
                  color: CyberTheme.hotPink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CartoonStatBox(
                  value: _customGemsCount.toString(),
                  label: 'GEMS FOUND',
                  emoji: '💎',
                  color: CyberTheme.limeGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CartoonStatBox(
                  value: '${_averageAccuracy.toStringAsFixed(1)}%',
                  label: 'AVG MATCH',
                  emoji: '🎯',
                  color: CyberTheme.electricBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section label
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'ACHIEVEMENTS',
                style: GoogleFonts.boogaloo(
                  fontSize: 18,
                  color: CyberTheme.inkBlack,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Achievement grid
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
              final isUnlocked =
                  profile.unlockedAchievementIds.contains(ach['id']);

              return _AchievementCard(
                emoji: ach['emoji'] as String,
                title: ach['title'] as String,
                description: ach['description'] as String,
                isUnlocked: isUnlocked,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_captures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: CyberTheme.cartoonCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📅', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'No history yet!',
                  style: GoogleFonts.boogaloo(fontSize: 20, color: CyberTheme.inkBlack),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your captured recreations will appear here.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: const Color(0xFF888888),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _captures.length,
      itemBuilder: (ctx, idx) {
        final capture = _captures[idx];
        final formattedDate =
            '${capture.timestamp.day}/${capture.timestamp.month}/${capture.timestamp.year.toString().substring(2)}';
        final score = capture.displayScore;
        Color scoreColor;
        if (score >= 95) {
          scoreColor = CyberTheme.limeGreen;
        } else if (score >= 85) {
          scoreColor = CyberTheme.hotPink;
        } else if (score >= 70) {
          scoreColor = CyberTheme.electricBlue;
        } else {
          scoreColor = CyberTheme.sunOrange;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline connector
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: scoreColor,
                      border: Border.all(color: CyberTheme.outlineBlack, width: 2.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: idx == _captures.length - 1
                        ? Container()
                        : Container(
                            width: 3,
                            color: const Color(0xFFCCCCCC),
                          ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: CyberTheme.cartoonCard,
                    child: Row(
                      children: [
                        // Photo thumbnail
                        Container(
                          width: 60,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: CyberTheme.outlineBlack, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb || capture.filePath.startsWith('http')
                                ? Image.network(capture.filePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                          child: Text('🖼️',
                                              style: TextStyle(fontSize: 20)),
                                        ))
                                : Image.file(File(capture.filePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                          child: Text('🖼️',
                                              style: TextStyle(fontSize: 20)),
                                        )),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                capture.locationName,
                                style: GoogleFonts.boogaloo(
                                  fontSize: 15,
                                  color: CyberTheme.inkBlack,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: scoreColor, width: 1.5),
                                ),
                                child: Text(
                                  '${capture.displayScore}% match',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: scoreColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: const Color(0xFF888888),
                                  fontWeight: FontWeight.w600,
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

// ─── Achievement Card ─────────────────────────────────────────────────────────
class _AchievementCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final bool isUnlocked;

  const _AchievementCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isUnlocked ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked ? CyberTheme.cardWhite : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked ? CyberTheme.outlineBlack : const Color(0xFFDDDDDD),
            width: 2.5,
          ),
          boxShadow: isUnlocked
              ? const [
                  BoxShadow(
                    color: CyberTheme.outlineBlack,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isUnlocked ? emoji : '🔒',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.boogaloo(
                fontSize: 13,
                color: isUnlocked ? CyberTheme.inkBlack : const Color(0xFFAAAAAA),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isUnlocked ? const Color(0xFF888888) : const Color(0xFFCCCCCC),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
