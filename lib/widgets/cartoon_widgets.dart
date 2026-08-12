import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';

// ─── CartoonCard ──────────────────────────────────────────────────────────────
/// A white card with thick black border and offset shadow (neo-brutalism style)
class CartoonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const CartoonCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? CyberTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor ?? CyberTheme.outlineBlack,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: CyberTheme.outlineBlack,
              offset: Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── PressableCartoonCard ─────────────────────────────────────────────────────
/// CartoonCard with press-down depth animation
class PressableCartoonCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BoxDecoration? decoration;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const PressableCartoonCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.decoration,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<PressableCartoonCard> createState() => _PressableCartoonCardState();
}

class _PressableCartoonCardState extends State<PressableCartoonCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ??
        BoxDecoration(
          color: widget.color ?? CyberTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CyberTheme.outlineBlack, width: 3),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(
                    color: CyberTheme.outlineBlack,
                    offset: Offset(5, 5),
                    blurRadius: 0,
                  ),
                ],
        );

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? (Matrix4.identity()..translate(5.0, 5.0))
            : Matrix4.identity(),
        padding: widget.padding ?? const EdgeInsets.all(16),
        decoration: decoration,
        child: widget.child,
      ),
    );
  }
}

// ─── CartoonButton ────────────────────────────────────────────────────────────
/// Full-width chunky button with press animation
class CartoonButton extends StatefulWidget {
  final String label;
  final String? emoji;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;

  const CartoonButton({
    super.key,
    required this.label,
    this.emoji,
    this.color = CyberTheme.limeGreen,
    this.textColor = CyberTheme.inkBlack,
    this.onTap,
    this.height = 56,
    this.fontSize = 16,
  });

  @override
  State<CartoonButton> createState() => _CartoonButtonState();
}

class _CartoonButtonState extends State<CartoonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? (Matrix4.identity()..translate(4.0, 4.0))
            : Matrix4.identity(),
        width: double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CyberTheme.outlineBlack, width: 3),
          boxShadow: _pressed
              ? []
              : const [
                  BoxShadow(
                    color: CyberTheme.outlineBlack,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.emoji != null) ...[
              Text(widget.emoji!, style: TextStyle(fontSize: widget.fontSize + 2)),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: GoogleFonts.boogaloo(
                fontSize: widget.fontSize,
                color: widget.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CartoonBadge ─────────────────────────────────────────────────────────────
/// Circular colored badge with emoji or icon
class CartoonBadge extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final Color color;
  final double size;
  final bool locked;

  const CartoonBadge({
    super.key,
    this.emoji,
    this.icon,
    this.color = CyberTheme.limeGreen,
    this.size = 56,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFEEEEEE) : color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: locked ? const Color(0xFFCCCCCC) : color,
          width: 3,
        ),
        boxShadow: locked
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
      ),
      child: Center(
        child: emoji != null
            ? Text(
                emoji!,
                style: TextStyle(
                  fontSize: size * 0.4,
                  color: locked ? const Color(0xFFAAAAAA) : null,
                ),
              )
            : Icon(
                icon ?? Icons.star,
                color: locked ? const Color(0xFFAAAAAA) : color,
                size: size * 0.45,
              ),
      ),
    );
  }
}

// ─── CartoonTag ───────────────────────────────────────────────────────────────
/// Rounded pill tag label
class CartoonTag extends StatelessWidget {
  final String label;
  final String? emoji;
  final Color color;
  final double fontSize;

  const CartoonTag({
    super.key,
    required this.label,
    this.emoji,
    this.color = CyberTheme.limeGreen,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        emoji != null ? '$emoji ${label.toUpperCase()}' : label.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ─── CartoonStatBox ───────────────────────────────────────────────────────────
/// Big number stat with label
class CartoonStatBox extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  final Color color;

  const CartoonStatBox({
    super.key,
    required this.value,
    required this.label,
    required this.emoji,
    this.color = CyberTheme.limeGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2.5),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.boogaloo(fontSize: 26, color: CyberTheme.inkBlack),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── CartoonXPBar ─────────────────────────────────────────────────────────────
/// Animated XP progress bar with candy-stripe feel
class CartoonXPBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final Color color;

  const CartoonXPBar({
    super.key,
    required this.progress,
    required this.label,
    this.color = CyberTheme.limeGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF666666),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.boogaloo(fontSize: 12, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CyberTheme.outlineBlack, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final Color? accentColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.emoji,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: GoogleFonts.boogaloo(
            fontSize: 18,
            color: accentColor ?? CyberTheme.inkBlack,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
