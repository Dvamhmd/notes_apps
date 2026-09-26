import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'custom_selection_controls.dart';

/// Overlay widget that provides a smooth, native Android/WhatsApp-style
/// interactive teardrop cursor handle for [QuillEditor].
///
/// Features:
/// - Exact teardrop pin geometry attached directly beneath the blinking cursor line.
/// - Fluid real-time drag positioning across characters, lines, and paragraphs.
/// - Smooth fade animation after 4 seconds of idle time.
/// - Auto-scrolling when dragging near top/bottom viewport boundaries.
/// - Enhanced touch target (48x48 dp) for effortless grabbing on any Android screen.
class QuillCursorHandleOverlay extends StatefulWidget {
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController? scrollController;
  final GlobalKey<QuillEditorState> editorKey;
  final Widget child;

  const QuillCursorHandleOverlay({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.editorKey,
    required this.child,
    this.scrollController,
  });

  @override
  State<QuillCursorHandleOverlay> createState() => _QuillCursorHandleOverlayState();
}

class _QuillCursorHandleOverlayState extends State<QuillCursorHandleOverlay>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();
  Timer? _fadeTimer;
  bool _isDragging = false;
  bool _isVisible = false;
  Offset? _caretBottomPosition;
  double _caretHeight = 20.0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    widget.controller.addListener(_onEditorChanged);
    widget.focusNode.addListener(_onFocusChanged);
    widget.scrollController?.addListener(_onScrollChanged);

    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.focusNode.hasFocus) {
        _showHandle();
      }
    });
  }

  @override
  void didUpdateWidget(covariant QuillCursorHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onEditorChanged);
      widget.controller.addListener(_onEditorChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScrollChanged);
      widget.scrollController?.addListener(_onScrollChanged);
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _fadeController.dispose();
    widget.controller.removeListener(_onEditorChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    widget.scrollController?.removeListener(_onScrollChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      _showHandle();
    } else {
      _hideHandleImmediate();
    }
  }

  void _onEditorChanged() {
    if (!mounted) return;
    final selection = widget.controller.selection;
    if (widget.focusNode.hasFocus && selection.isCollapsed && selection.baseOffset >= 0) {
      _showHandle();
    } else if (!selection.isCollapsed) {
      // Range selection active - hide collapsed handle
      _hideHandleImmediate();
    }
  }

  void _onScrollChanged() {
    if (!mounted || !_isVisible) return;
    _updateCaretPosition();
  }

  void _showHandle() {
    if (!mounted) return;
    final selection = widget.controller.selection;
    if (!selection.isCollapsed || selection.baseOffset < 0 || !widget.focusNode.hasFocus) {
      return;
    }

    _updateCaretPosition();
    _isVisible = true;
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
    _fadeController.forward();
    _restartFadeTimer();
  }

  void _hideHandleImmediate() {
    _fadeTimer?.cancel();
    _isDragging = false;
    if (_isVisible) {
      _isVisible = false;
      _fadeController.reverse().then((_) {
        if (mounted && !_isVisible && _overlayController.isShowing) {
          _overlayController.hide();
        }
      });
    }
  }

  void _restartFadeTimer() {
    _fadeTimer?.cancel();
    if (_isDragging) return;
    _fadeTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted && !_isDragging) {
        _isVisible = false;
        _fadeController.reverse().then((_) {
          if (mounted && !_isVisible && _overlayController.isShowing) {
            _overlayController.hide();
          }
        });
      }
    });
  }

  void _updateCaretPosition() {
    final rawEditorState =
        widget.editorKey.currentState?.editableTextKey.currentState;
    if (rawEditorState == null) return;

    final renderEditor = rawEditorState.renderEditor;
    final selection = widget.controller.selection;
    if (!selection.isCollapsed || selection.baseOffset < 0) return;

    try {
      final caretRect = renderEditor.getLocalRectForCaret(selection.extent);
      final caretGlobal = renderEditor.localToGlobal(
        Offset(caretRect.left + (caretRect.width / 2), caretRect.bottom),
      );

      setState(() {
        _caretBottomPosition = caretGlobal;
        _caretHeight = caretRect.height > 0 ? caretRect.height : 20.0;
      });
    } catch (_) {
      // Handle transient layout phases safely
    }
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _fadeTimer?.cancel();
    _fadeController.value = 1.0;
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final rawEditorState =
        widget.editorKey.currentState?.editableTextKey.currentState;
    if (rawEditorState == null) return;

    final renderEditor = rawEditorState.renderEditor;

    // Convert touch global position to renderEditor local coordinates
    // Aim ~18px above bottom teardrop to correspond to text baseline
    final touchInEditor = renderEditor.globalToLocal(
      details.globalPosition.translate(0, -(_caretHeight * 0.9)),
    );

    final resolvedPosition = renderEditor.getPositionForOffset(touchInEditor);
    final currentOffset = widget.controller.selection.baseOffset;

    if (resolvedPosition.offset != currentOffset) {
      HapticFeedback.selectionClick();
      widget.controller.updateSelection(
        TextSelection.collapsed(offset: resolvedPosition.offset),
        ChangeSource.local,
      );
    }

    // Auto-scroll vertically if dragged near top/bottom viewport edge
    final scrollCtrl = widget.scrollController;
    if (scrollCtrl != null && scrollCtrl.hasClients) {
      final localTouchInEditor = renderEditor.globalToLocal(details.globalPosition);
      const edgeThreshold = 50.0;
      final viewportHeight = renderEditor.size.height;

      if (localTouchInEditor.dy < edgeThreshold) {
        final speed = math.max(2.0, (edgeThreshold - localTouchInEditor.dy) / 2);
        scrollCtrl.jumpTo(math.max(0.0, scrollCtrl.offset - speed));
      } else if (localTouchInEditor.dy > viewportHeight - edgeThreshold) {
        final speed = math.max(2.0, (localTouchInEditor.dy - (viewportHeight - edgeThreshold)) / 2);
        scrollCtrl.jumpTo(
          math.min(scrollCtrl.position.maxScrollExtent, scrollCtrl.offset + speed),
        );
      }
    }

    _updateCaretPosition();
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _restartFadeTimer();
  }

  void _onPanCancel() {
    _isDragging = false;
    _restartFadeTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handleColor = theme.textSelectionTheme.selectionHandleColor ??
        theme.colorScheme.primary;

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) {
        if (_caretBottomPosition == null) return const SizedBox.shrink();

        return Positioned(
          left: _caretBottomPosition!.dx - 24.0, // Center 48px hit area at caret X
          top: _caretBottomPosition!.dy - 1.0,  // Pin tip directly touching caret bottom
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              key: const Key('quill_cursor_teardrop_handle'),
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: _onPanCancel,
              onTap: () {
                _showHandle();
                HapticFeedback.selectionClick();
              },
              child: SizedBox(
                width: 48.0,
                height: 48.0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 28.0,
                    height: 30.0,
                    child: CustomPaint(
                      painter: TeardropHandlePainter(
                        color: handleColor,
                        type: TextSelectionHandleType.collapsed,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Listener(
        onPointerDown: (_) {
          if (widget.focusNode.hasFocus) {
            _showHandle();
          }
        },
        child: widget.child,
      ),
    );
  }
}
