import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom Material TextSelectionControls that provides prominent, touch-friendly
/// Android-style teardrop/circular handles for text selection and cursor positioning,
/// while maintaining a clean look and suppressing stuck legacy popups.
class CustomTouchTextSelectionControls extends MaterialTextSelectionControls {
  static final CustomTouchTextSelectionControls instance =
      CustomTouchTextSelectionControls();

  @override
  Size getHandleSize(double textLineHeight) {
    return const Size(26.0, 26.0);
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(26.0, 0.0);
      case TextSelectionHandleType.right:
        return const Offset(0.0, 0.0);
      case TextSelectionHandleType.collapsed:
        return const Offset(13.0, 0.0);
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
        width: 26.0,
        height: 26.0,
        child: CustomPaint(
          painter: _TeardropHandlePainter(
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
    // Suppress legacy floating toolbar to prevent stuck paste overlays
    return const SizedBox.shrink();
  }
}

class _TeardropHandlePainter extends CustomPainter {
  final Color color;
  final TextSelectionHandleType type;

  _TeardropHandlePainter({
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
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final path = Path();
    const double radius = 13.0;

    if (type == TextSelectionHandleType.left) {
      // Left handle: Circle hanging down-left, with top-right corner pointing up at (26, 0)
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height - radius);
      path.arcToPoint(
        Offset(size.width - radius, size.height),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(radius, size.height);
      path.arcToPoint(
        const Offset(0, radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.arcToPoint(
        Offset(size.width - radius, 0),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(size.width, 0);
      path.close();
    } else if (type == TextSelectionHandleType.right) {
      // Right handle: Circle hanging down-right, with top-left corner pointing up at (0, 0)
      path.moveTo(0, 0);
      path.lineTo(radius, 0);
      path.arcToPoint(
        Offset(size.width, radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.arcToPoint(
        Offset(size.width - radius, size.height),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(radius, size.height);
      path.arcToPoint(
        Offset(0, size.height - radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(0, 0);
      path.close();
    } else if (type == TextSelectionHandleType.collapsed) {
      // Collapsed cursor handle: Centered teardrop pointing straight up to cursor tip at (13, 0)
      const double r = 10.5;
      const double cy = 15.0;
      final double cx = size.width / 2; // 13.0
      final double tx = 10.5 * math.sqrt(cy * cy - r * r) / cy; // ~7.50
      final double ty = cy - (r * r / cy); // ~7.65

      path.moveTo(cx, 0);
      path.lineTo(cx + tx, ty);
      path.arcToPoint(
        Offset(cx - tx, ty),
        radius: const Radius.circular(r),
        clockwise: true,
      );
      path.lineTo(cx, 0);
      path.close();
    }

    // Draw drop shadow for clear visibility over any text/background
    canvas.drawPath(path.shift(const Offset(0, 1.5)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TeardropHandlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.type != type;
  }
}
