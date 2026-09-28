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
      // Left handle: Smooth teardrop hanging down-left, pointing up-right at (w, 0)
      const double radius = 12.0;
      path.moveTo(w, 0.5);
      path.cubicTo(w - 1.5, 3.0, w, h - radius * 2, w - radius, h - radius * 2);
      path.arcToPoint(
        Offset(w - radius * 2, h - radius),
        radius: const Radius.circular(radius),
        clockwise: false,
      );
      path.arcToPoint(
        Offset(w - radius, h),
        radius: const Radius.circular(radius),
        clockwise: false,
      );
      path.lineTo(w, h - radius);
      path.lineTo(w, 0.5);
      path.close();
    } else if (type == TextSelectionHandleType.right) {
      // Right handle: Smooth teardrop hanging down-right, pointing up-left at (0, 0)
      const double radius = 12.0;
      path.moveTo(0, 0.5);
      path.cubicTo(1.5, 3.0, 0, h - radius * 2, radius, h - radius * 2);
      path.arcToPoint(
        Offset(radius * 2, h - radius),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.arcToPoint(
        Offset(radius, h),
        radius: const Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(0, h - radius);
      path.lineTo(0, 0.5);
      path.close();
    } else if (type == TextSelectionHandleType.collapsed) {
      // Collapsed cursor handle: Pure elegant organic teardrop pointing straight UP at (cx, 0)
      final double cx = w / 2;
      const double r = 9.5;
      const double cy = 18.0;

      path.moveTo(cx, 0.5);
      path.cubicTo(
        cx + 2.0, 4.5,
        cx + r, cy - 6.0,
        cx + r, cy,
      );
      path.arcToPoint(
        Offset(cx - r, cy),
        radius: const Radius.circular(r),
        clockwise: true,
      );
      path.cubicTo(
        cx - r, cy - 6.0,
        cx - 2.0, 4.5,
        cx, 0.5,
      );
      path.close();
    }

    // Draw smooth drop shadow for high contrast & clarity on any background
    canvas.drawPath(path.shift(const Offset(0, 1.5)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TeardropHandlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.type != type;
  }
}

