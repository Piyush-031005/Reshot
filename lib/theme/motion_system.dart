import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The ReShot Motion System (Perform, don't just animate).
/// 
/// Contains reusable wrappers for bouncy, elastic, and comic-style micro-interactions.
class MotionSystem {
  
  /// Bouncing button interaction used across Dashboard and Gamified screens
  static Widget elasticBounce({
    required Widget child,
    required VoidCallback onTap,
    double scaleDown = 0.9,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return _ElasticBounceWrapper(
      onTap: onTap,
      scaleDown: scaleDown,
      duration: duration,
      child: child,
    );
  }

  /// Comic stamp effect (slams down onto screen)
  static Widget comicStamp({
    required Widget child,
    required bool isVisible,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimatedScale(
      scale: isVisible ? 1.0 : 5.0, // Drops from massive to normal
      duration: duration,
      curve: Curves.elasticOut, // Huge spring effect
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 100),
        child: child,
      ),
    );
  }

  /// Simple fast shake, usually paired with HapticFeedback.heavyImpact()
  static void triggerImpactShake() {
    HapticFeedback.heavyImpact();
    // To do a real UI shake, we'd need a ShakeController in the widget tree,
    // but triggering the haptic feedback is the core physical sensation.
  }
}

class _ElasticBounceWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;
  final Duration duration;

  const _ElasticBounceWrapper({
    required this.child,
    required this.onTap,
    required this.scaleDown,
    required this.duration,
  });

  @override
  State<_ElasticBounceWrapper> createState() => _ElasticBounceWrapperState();
}

class _ElasticBounceWrapperState extends State<_ElasticBounceWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 250), // Elastic snap back
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
