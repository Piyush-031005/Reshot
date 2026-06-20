import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class CompositionOverlayPainter extends CustomPainter {
  final double pitch;
  final double roll;
  final double posX;
  final double scale;
  final bool isAligned;
  final String activeState;

  CompositionOverlayPainter({
    required this.pitch,
    required this.roll,
    required this.posX,
    required this.scale,
    required this.isAligned,
    required this.activeState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final themeColor = isAligned ? CyberTheme.limeGreen : CyberTheme.hotPink;

    _drawGrid(canvas, size);
    _drawTiltIndicator(canvas, center, themeColor);
    _drawSilhouette(canvas, size, themeColor);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(38)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal third lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );

    // Draw vertical third lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );
  }

  void _drawTiltIndicator(Canvas canvas, Offset center, Color color) {
    // 1. Draw static center viewfinder circle
    final outerPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 40, outerPaint);

    // Crosshairs ticks
    canvas.drawLine(Offset(center.dx - 50, center.dy), Offset(center.dx - 40, center.dy), outerPaint);
    canvas.drawLine(Offset(center.dx + 40, center.dy), Offset(center.dx + 50, center.dy), outerPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 50), Offset(center.dx, center.dy - 40), outerPaint);
    canvas.drawLine(Offset(center.dx, center.dy + 40), Offset(center.dx, center.dy + 50), outerPaint);

    // 2. Draw live tilt horizon bar
    // Pitch governs Y offset, roll governs X offset and rotation angle
    double deltaY = roll.clamp(-10.0, 10.0) * 4.0; 
    double deltaX = pitch.clamp(-10.0, 10.0) * 4.0;
    double rotationAngle = pitch / 10.0 * math.pi / 4; // angle

    final indicatorCenter = Offset(center.dx + deltaX, center.dy + deltaY);

    // Draw target indicator dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(indicatorCenter, 6, dotPaint);

    // Draw level line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(indicatorCenter.dx, indicatorCenter.dy);
    canvas.rotate(rotationAngle);
    canvas.drawLine(const Offset(-30, 0), const Offset(30, 0), linePaint);
    canvas.drawLine(const Offset(-30, 0), const Offset(-30, 8), linePaint);
    canvas.drawLine(const Offset(30, 0), const Offset(30, 8), linePaint);
    canvas.restore();
  }

  void _drawSilhouette(Canvas canvas, Size size, Color color) {
    // Draw the "Locked Composition" outer frame boundaries
    final borderPaint = Paint()
      ..color = activeState == 'handover' ? color.withAlpha(128) : Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Corner brackets
    const bracketSize = 25.0;
    canvas.drawPath(
      Path()
        ..moveTo(bracketSize, bracketSize)
        ..lineTo(bracketSize, 10)
        ..lineTo(10, 10)
        ..lineTo(10, bracketSize),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketSize, bracketSize)
        ..lineTo(size.width - bracketSize, 10)
        ..lineTo(size.width - 10, 10)
        ..lineTo(size.width - 10, bracketSize),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(bracketSize, size.height - bracketSize)
        ..lineTo(bracketSize, size.height - 10)
        ..lineTo(10, size.height - 10)
        ..lineTo(10, size.height - bracketSize),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketSize, size.height - bracketSize)
        ..lineTo(size.width - bracketSize, size.height - 10)
        ..lineTo(size.width - 10, size.height - 10)
        ..lineTo(size.width - 10, size.height - bracketSize),
      borderPaint,
    );

    // 2. Draw static target skeleton frame
    final targetPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final targetCenter = Offset(size.width / 2, size.height / 2 + 50);
    _drawPersonFigure(canvas, targetCenter, 100.0, targetPaint);

    // 3. Draw moving user skeleton matching coordinates
    final userPaint = Paint()
      ..color = color
      ..strokeWidth = isAligned ? 5.0 : 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Map posX slider to viewport coordinates
    double xOffset = (posX - 50.0) * (size.width / 150.0);
    final userCenter = Offset(size.width / 2 + xOffset, size.height / 2 + 50);
    _drawPersonFigure(canvas, userCenter, scale, userPaint);
  }

  void _drawPersonFigure(Canvas canvas, Offset bottomCenter, double figureScale, Paint paint) {
    // scale defaults around 100
    double scaleFactor = figureScale / 100.0;
    double figureHeight = 160.0 * scaleFactor;

    final headCenter = Offset(bottomCenter.dx, bottomCenter.dy - figureHeight + (25 * scaleFactor));
    final neck = Offset(bottomCenter.dx, bottomCenter.dy - figureHeight + (45 * scaleFactor));
    final spine = Offset(bottomCenter.dx, bottomCenter.dy - (60 * scaleFactor));
    final leftShoulder = Offset(bottomCenter.dx - (35 * scaleFactor), bottomCenter.dy - figureHeight + (55 * scaleFactor));
    final rightShoulder = Offset(bottomCenter.dx + (35 * scaleFactor), bottomCenter.dy - figureHeight + (55 * scaleFactor));
    final leftHip = Offset(bottomCenter.dx - (20 * scaleFactor), bottomCenter.dy - (60 * scaleFactor));
    final rightHip = Offset(bottomCenter.dx + (20 * scaleFactor), bottomCenter.dy - (60 * scaleFactor));

    // Draw head circle
    canvas.drawCircle(headCenter, 18 * scaleFactor, paint);

    // Draw torso bones
    canvas.drawLine(neck, spine, paint);
    canvas.drawLine(leftShoulder, rightShoulder, paint);
    canvas.drawLine(leftHip, rightHip, paint);

    // Draw left arm (waving slightly)
    final leftElbow = Offset(leftShoulder.dx - (25 * scaleFactor), leftShoulder.dy + (20 * scaleFactor));
    final leftHand = Offset(leftElbow.dx - (15 * scaleFactor), leftElbow.dy - (15 * scaleFactor));
    canvas.drawLine(leftShoulder, leftElbow, paint);
    canvas.drawLine(leftElbow, leftHand, paint);

    // Draw right arm
    final rightElbow = Offset(rightShoulder.dx + (20 * scaleFactor), rightShoulder.dy + (25 * scaleFactor));
    final rightHand = Offset(rightElbow.dx + (10 * scaleFactor), rightElbow.dy + (35 * scaleFactor));
    canvas.drawLine(rightShoulder, rightElbow, paint);
    canvas.drawLine(rightElbow, rightHand, paint);

    // Draw legs
    final leftFoot = Offset(leftHip.dx - (10 * scaleFactor), bottomCenter.dy);
    final rightFoot = Offset(rightHip.dx + (10 * scaleFactor), bottomCenter.dy);
    canvas.drawLine(leftHip, leftFoot, paint);
    canvas.drawLine(rightHip, rightFoot, paint);
  }

  @override
  bool shouldRepaint(covariant CompositionOverlayPainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.roll != roll ||
        oldDelegate.posX != posX ||
        oldDelegate.scale != scale ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.activeState != activeState;
  }
}
