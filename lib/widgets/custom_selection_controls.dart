import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/rich_clipboard_service.dart';

/// Custom Material TextSelectionControls that provides prominent, touch-friendly
/// Android-style teardrop/circular handles for text selection and cursor positioning,
/// while maintaining a clean look and suppressing stuck legacy popups.
class CustomTouchTextSelectionControls extends MaterialTextSelectionControls {
  static final CustomTouchTextSelectionControls instance =
      CustomTouchTextSelectionControls();

  static int _suppressionCount = 0;
  static final ValueNotifier<bool> suppressedNotifier = ValueNotifier<bool>(false);

  static bool get isSuppressed => suppressedNotifier.value;

  static void suppress() {
    _suppressionCount++;
    if (_suppressionCount == 1) {
      suppressedNotifier.value = true;
    }
  }

  static void unsuppress() {
    if (_suppressionCount > 0) {
      _suppressionCount--;
      if (_suppressionCount == 0) {
        suppressedNotifier.value = false;
      }
    }
  }

  /// Convenience helper to run an async action (e.g. showModalBottomSheet or showDialog)
  /// while automatically suppressing text selection handles to prevent them from
  /// floating over modal sheets and dialogs.
  static Future<T?> showSuppressed<T>(Future<T?> Function() action) async {
    suppress();
    try {
      return await action();
    } finally {
      unsuppress();
    }
  }

  static const double handleWidth = 28.0;
  static const double handleHeight = 30.0;

  @override
  Size getHandleSize(double textLineHeight) {
    return const Size(handleWidth, handleHeight);
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return const Offset(handleWidth / 2, 0.0);
  }

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textHeight, [
    VoidCallback? onTap,
  ]) {
    // For collapsed cursor handle, QuillCursorHandleOverlay handles the interactive
    // floating teardrop with auto-fade and precision drag to avoid duplicate handles.
    if (type == TextSelectionHandleType.collapsed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final handleColor = theme.textSelectionTheme.selectionHandleColor ??
        theme.colorScheme.primary;

    Widget handle = SizedBox(
      width: handleWidth,
      height: handleHeight,
      child: CustomPaint(
        painter: TeardropHandlePainter(
          color: handleColor,
          type: type,
        ),
      ),
    );

    if (onTap != null) {
      handle = GestureDetector(
        onTap: onTap,
        child: handle,
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: suppressedNotifier,
      builder: (context, suppressed, child) {
        if (suppressed) {
          return const SizedBox.shrink();
        }
        return child!;
      },
      child: handle,
    );
  }

  @override
  bool canPaste(TextSelectionDelegate delegate) => true;

  @override
  bool canCopy(TextSelectionDelegate delegate) =>
      !delegate.textEditingValue.selection.isCollapsed;

  @override
  bool canCut(TextSelectionDelegate delegate) =>
      !delegate.textEditingValue.selection.isCollapsed;

  @override
  void handleCopy(TextSelectionDelegate delegate) {
    final controller = RichClipboardService.activeController;
    if (controller != null && !controller.selection.isCollapsed) {
      RichClipboardService.copySelection(controller);
    } else {
      final text = delegate.textEditingValue.selection.textInside(delegate.textEditingValue.text);
      Clipboard.setData(ClipboardData(text: text));
    }
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
    delegate.hideToolbar();
  }

  @override
  void handleCut(TextSelectionDelegate delegate) {
    final controller = RichClipboardService.activeController;
    if (controller != null && !controller.selection.isCollapsed) {
      RichClipboardService.cutSelection(controller);
    } else {
      final text = delegate.textEditingValue.selection.textInside(delegate.textEditingValue.text);
      Clipboard.setData(ClipboardData(text: text));
      delegate.userUpdateTextEditingValue(
        delegate.textEditingValue.copyWith(
          text: delegate.textEditingValue.selection.textBefore(delegate.textEditingValue.text) +
              delegate.textEditingValue.selection.textAfter(delegate.textEditingValue.text),
          selection: TextSelection.collapsed(offset: delegate.textEditingValue.selection.start),
        ),
        SelectionChangedCause.toolbar,
      );
    }
    delegate.hideToolbar();
  }

  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    final controller = RichClipboardService.activeController;
    if (controller != null) {
      await RichClipboardService.paste(controller);
    } else {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        delegate.userUpdateTextEditingValue(
          delegate.textEditingValue.copyWith(
            text: delegate.textEditingValue.selection.textBefore(delegate.textEditingValue.text) +
                data.text! +
                delegate.textEditingValue.selection.textAfter(delegate.textEditingValue.text),
            selection: TextSelection.collapsed(
              offset: delegate.textEditingValue.selection.start + data.text!.length,
            ),
          ),
          SelectionChangedCause.toolbar,
        );
      }
    }
    delegate.hideToolbar();
  }

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

/// Custom painter that renders native Android & WhatsApp style full organic teardrop handles
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

    final double w = size.width;
    final double cx = w / 2;
    const double r = 9.5;
    const double cy = 18.0;

    // Full, elegant organic teardrop pointing straight UP at (cx, 0.5)
    final path = Path();
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

    // Draw smooth drop shadow for high contrast & clarity on any background
    canvas.drawPath(path.shift(const Offset(0, 1.5)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TeardropHandlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.type != type;
  }
}

