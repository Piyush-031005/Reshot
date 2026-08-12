import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';
import 'home_shell.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animations ──────────────────────────────────────────────────────────────

  // Phase 1: Logo bounces in
  late AnimationController _logoController;
  late Animation<double> _logoBounce;
  late Animation<double> _logoFade;

  // Phase 2: Tagline slides up
  late AnimationController _taglineController;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineFade;

  // Phase 3: Feature pills stagger in
  late AnimationController _pillController;
  late List<Animation<double>> _pillFades;
  late List<Animation<Offset>> _pillSlides;

  // Phase 4: Camera emoji spin-pulse
  late AnimationController _pulseController;
  late Animation<double> _pulse;
  late Animation<double> _rotate;

  // Phase 5: Progress bar fills
  late AnimationController _barController;
  late Animation<double> _barWidth;

  // Floating dots background
  late AnimationController _floatController;

  bool _navigating = false;

  // Feature pills data
  final List<_PillData> _pills = const [
    _PillData('📸', 'Auto Capture', CyberTheme.limeGreen),
    _PillData('💎', 'Hidden Gems', CyberTheme.hotPink),
    _PillData('⭐', 'XP & Ranks', CyberTheme.electricBlue),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    // Logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoBounce = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    // Tagline
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeOutCubic,
    ));
    _taglineFade = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );

    // Pills (3 staggered)
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pillFades = List.generate(3, (i) {
      return CurvedAnimation(
        parent: _pillController,
        curve: Interval(i * 0.25, i * 0.25 + 0.55, curve: Curves.easeOut),
      );
    });
    _pillSlides = List.generate(3, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _pillController,
        curve: Interval(i * 0.25, i * 0.25 + 0.55, curve: Curves.easeOutBack),
      ));
    });

    // Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotate = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bar
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _barWidth = CurvedAnimation(
      parent: _barController,
      curve: Curves.easeInOutCubic,
    );

    // Floating dots
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  Future<void> _startSequence() async {
    // Phase 1: Logo
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // Phase 2: Tagline
    await Future.delayed(const Duration(milliseconds: 650));
    _taglineController.forward();

    // Phase 3: Pills
    await Future.delayed(const Duration(milliseconds: 400));
    _pillController.forward();

    // Phase 4: Progress bar
    await Future.delayed(const Duration(milliseconds: 200));
    _barController.forward();

    // Navigate after bar fills + small pause
    await Future.delayed(const Duration(milliseconds: 2800));
    if (mounted && !_navigating) {
      _navigating = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeShell(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    _pillController.dispose();
    _pulseController.dispose();
    _barController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: CyberTheme.cream,
      body: Stack(
        children: [
          // ── Floating dot background ──────────────────────────────────────
          ..._buildFloatingDots(size),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // ── Logo block ────────────────────────────────────────────
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoBounce,
                      child: Column(
                        children: [
                          // Camera emoji badge
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) => Transform.scale(
                              scale: _pulse.value,
                              child: Transform.rotate(
                                angle: _rotate.value,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: CyberTheme.limeGreen,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: CyberTheme.outlineBlack,
                                      width: 4,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: CyberTheme.outlineBlack,
                                        offset: Offset(7, 7),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '📷',
                                      style: TextStyle(fontSize: 48),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ReSHOT wordmark
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Re',
                                  style: GoogleFonts.boogaloo(
                                    fontSize: 54,
                                    color: CyberTheme.inkBlack,
                                    height: 1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'SHOT',
                                  style: GoogleFonts.boogaloo(
                                    fontSize: 54,
                                    color: CyberTheme.hotPink,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Version sub-badge
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: CyberTheme.inkBlack,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'EXPLORER EDITION',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: CyberTheme.limeGreen,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Tagline ───────────────────────────────────────────────
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Frame the background. Hand it to a stranger.\nReShot auto-captures when perfectly aligned.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF666666),
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Feature Pills ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pills.length, (i) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 8,
                          right: i == _pills.length - 1 ? 0 : 0,
                        ),
                        child: SlideTransition(
                          position: _pillSlides[i],
                          child: FadeTransition(
                            opacity: _pillFades[i],
                            child: _FeaturePill(data: _pills[i]),
                          ),
                        ),
                      );
                    }),
                  ),

                  const Spacer(flex: 2),

                  // ── Loading bar ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Loading gems...',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFAAAAAA),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _barController,
                              builder: (_, __) => Text(
                                '${(_barWidth.value * 100).toInt()}%',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: CyberTheme.limeGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFCCCCCC),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: AnimatedBuilder(
                              animation: _barController,
                              builder: (_, __) => FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _barWidth.value,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        CyberTheme.limeGreen,
                                        Color(0xFF9EED00),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Footer ────────────────────────────────────────────────
                  Text(
                    '🏔️ Made for Uttarakhand Explorers',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFCCCCCC),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating dot background ──────────────────────────────────────────────────
  List<Widget> _buildFloatingDots(Size size) {
    final dots = <_DotData>[
      _DotData(0.08, 0.12, 16, CyberTheme.limeGreen.withOpacity(0.4), 0),
      _DotData(0.88, 0.08, 24, CyberTheme.hotPink.withOpacity(0.3), 0.3),
      _DotData(0.92, 0.35, 12, CyberTheme.electricBlue.withOpacity(0.35), 0.6),
      _DotData(0.05, 0.55, 20, CyberTheme.sunOrange.withOpacity(0.3), 0.1),
      _DotData(0.75, 0.75, 14, CyberTheme.limeGreen.withOpacity(0.35), 0.7),
      _DotData(0.2, 0.88, 18, CyberTheme.hotPink.withOpacity(0.25), 0.4),
      _DotData(0.5, 0.05, 10, CyberTheme.electricBlue.withOpacity(0.4), 0.8),
      _DotData(0.65, 0.15, 8, CyberTheme.goldenYellow.withOpacity(0.5), 0.5),
    ];

    return dots.map((d) {
      return AnimatedBuilder(
        animation: _floatController,
        builder: (_, __) {
          final t = (_floatController.value + d.phase) % 1.0;
          final offset = math.sin(t * math.pi * 2) * 12;
          return Positioned(
            left: size.width * d.x,
            top: size.height * d.y + offset,
            child: Container(
              width: d.size,
              height: d.size,
              decoration: BoxDecoration(
                color: d.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CyberTheme.outlineBlack.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

// ─── Feature Pill ─────────────────────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final _PillData data;

  const _FeaturePill({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.3),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: CyberTheme.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────
class _PillData {
  final String emoji;
  final String label;
  final Color color;

  const _PillData(this.emoji, this.label, this.color);
}

class _DotData {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double phase;

  const _DotData(this.x, this.y, this.size, this.color, this.phase);
}
