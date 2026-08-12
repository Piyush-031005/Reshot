import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';
import 'dashboard.dart';
import 'gallery_screen.dart';
import 'profile_screen.dart';

/// HomeShell wraps the 3 main tab screens behind a cartoon bottom nav bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  late int _currentIndex;
  late final AnimationController _popController;

  // Keep screens alive when switching tabs
  late final List<Widget> _screens;

  final List<_NavItem> _navItems = const [
    _NavItem(emoji: '🗺️', label: 'Explore', color: CyberTheme.limeGreen),
    _NavItem(emoji: '🖼️', label: 'Gallery', color: CyberTheme.hotPink),
    _NavItem(emoji: '🧭', label: 'Profile', color: CyberTheme.electricBlue),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _screens = [
      const DashboardScreen(),
      const GalleryScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    // Pop-bounce animation on tap
    _popController.forward(from: 0).then((_) => _popController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.cream,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _CartoonNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ─── Cartoon Nav Bar ──────────────────────────────────────────────────────────
class _CartoonNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _CartoonNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CyberTheme.cardWhite,
        border: Border(
          top: BorderSide(color: CyberTheme.outlineBlack, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: CyberTheme.outlineBlack,
            offset: Offset(0, -4),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              return _NavTabItem(
                item: items[i],
                isSelected: i == currentIndex,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Individual Tab Item ──────────────────────────────────────────────────────
class _NavTabItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavTabItem> createState() => _NavTabItemState();
}

class _NavTabItemState extends State<_NavTabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? widget.item.color : const Color(0xFFCCCCCC);

    return GestureDetector(
      onTap: () {
        _ctrl.forward().then((_) => _ctrl.reverse());
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: widget.isSelected
              ? BoxDecoration(
                  color: widget.item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.item.color, width: 2.5),
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji with optional pop badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    widget.item.emoji,
                    style: TextStyle(
                      fontSize: widget.isSelected ? 26 : 22,
                    ),
                  ),
                  if (widget.isSelected)
                    Positioned(
                      top: -3,
                      right: -6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.item.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CyberTheme.outlineBlack,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────
class _NavItem {
  final String emoji;
  final String label;
  final Color color;

  const _NavItem({
    required this.emoji,
    required this.label,
    required this.color,
  });
}
