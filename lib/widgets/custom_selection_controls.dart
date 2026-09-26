import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom Material TextSelectionControls that provides prominent, touch-friendly
/// Android-style teardrop/circular handles for text selection and cursor positioning,
/// while maintaining a clean look and suppressing stuck legacy popups.
class CustomTouchTextSelectionControls extends MaterialTextSelectionControls {
  static final CustomTouchTextSelectionControls instance =
      CustomTouchTextSelectionControls();

  static const double handleWidth = 28.0;
  static const double handleHeight = 30.0;

  @override
  Size getHandleSize(double textLineHeight) {
    return const Size(handleWidth, handleHeight);
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(handleWidth, 0.0);
      case TextSelectionHandleType.right:
        return const Offset(0.0, 0.0);
      case TextSelectionHandleType.collapsed:
        return const Offset(handleWidth / 2, 0.0);
    }
  }

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textHeight, [
    VoidCallback? onTap,
  ]) {
    final theme = Theme.of(context);
    final handleColor = theme.textSelectionTheme.selectionHandleColor ??
        theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: handleWidth,
        height: handleHeight,
        child: CustomPaint(
          painter: TeardropHandlePainter(
            color: handleColor,
            type: type,
          ),
        ),
      ),
    );
  }

  // ignore: deprecated_member_use
  @override
  bool canPaste(TextSelectionDelegate delegate) => false;

  // ignore: deprecated_member_use
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    // Suppress legacy floating toolbar to prevent stuck paste overlays;
    // modern contextMenuBuilder handles adaptive menus gracefully.
    return const SizedBox.shrink();
  }
}

/// Custom painter that renders native Android & WhatsApp style teardrop/circular handles
/// with subtle drop shadow for maximum visibility on all Android screens.
class TeardropHandlePainter extends CustomPainter {
  final Color color;
  final TextSelectionHandleType type;

  const TeardropHandlePainter({
    required this.color,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final path = Path();
    final double w = size.width;
    final double h = size.height;

    if (type == TextSelectionHandleType.left) {
      // Left handle: Circle hanging down-left, with top-right corner pointing up at (w, 0)
      const double radius = 13.0;
      path.moveTo(w, 0);
      path.lineTo(w, h - radius);
      path.arcToPoint(
        Offset(w - radius, h),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(radius, h);
      path.arcToPoint(
        const Offset(0, radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.arcToPoint(
        Offset(w - radius, 0),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(w, 0);
      path.close();
    } else if (type == TextSelectionHandleType.right) {
      // Right handle: Circle hanging down-right, with top-left corner pointing up at (0, 0)
      const double radius = 13.0;
      path.moveTo(0, 0);
      path.lineTo(radius, 0);
      path.arcToPoint(
        Offset(w, radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.arcToPoint(
        Offset(w - radius, h),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(radius, h);
      path.arcToPoint(
        Offset(0, h - radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(0, 0);
      path.close();
    } else if (type == TextSelectionHandleType.collapsed) {
      // Collapsed cursor handle: Symmetrical teardrop pointing straight UP at (cx, 0)
      // Tangent to bottom circle bulb
      final double cx = w / 2;
      const double r = 10.0;
      const double cy = 16.0;

      // sin(theta) = r / cy
      final double sinTheta = r / cy;
      final double cosTheta = math.sqrt(1.0 - sinTheta * sinTheta);

      final double tx = r * cosTheta;
      final double ty = cy - (r * sinTheta);

      path.moveTo(cx, 0.0);
      path.lineTo(cx + tx, ty);
      path.arcToPoint(
        Offset(cx - tx, ty),
        radius: const Radius.circular(r),
        clockwise: true,
      );
      path.lineTo(cx, 0.0);
      path.close();
    }

    // Draw drop shadow for clear visibility over any text/background
    canvas.drawPath(path.shift(const Offset(0, 1.5)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TeardropHandlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.type != type;
  }
}

