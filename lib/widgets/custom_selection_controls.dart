import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom Material TextSelectionControls that provides prominent, touch-friendly
/// Android-style teardrop/circular handles (bulat-bulat) for text selection,
/// while completely suppressing any stuck floating Paste indicators/popups.
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
    // Suppress single cursor collapsed handle so no paste popup is triggered on tap
    if (type == TextSelectionHandleType.collapsed) {
      return const SizedBox.shrink();
    }

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
    // Suppress floating toolbar to prevent stuck paste overlays on web/desktop
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
