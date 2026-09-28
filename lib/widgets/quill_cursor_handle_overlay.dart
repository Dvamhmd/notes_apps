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
/// - Smooth fade animation after 1.5 seconds of idle time.
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
  Offset _dragStartTouchOffset = Offset.zero;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  double? _activeLineTop;
  double? _activeLineBottom;
  double? _activeLineCenterY;

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
      if (!_isDragging) {
        _showHandle();
      }
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
    _fadeTimer = Timer(const Duration(milliseconds: 1500), () {
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
        _activeLineTop = caretRect.top;
        _activeLineBottom = caretRect.bottom;
        _activeLineCenterY = caretRect.top + (caretRect.height / 2);
      });
    } catch (_) {
      // Handle transient layout phases safely
    }
  }

  TextPosition _getPositionForOffset(dynamic renderEditor, Offset localInEditor) {
    try {
      dynamic current = renderEditor.firstChild;
      dynamic closestChild;
      double closestDistance = double.infinity;

      while (current != null) {
        final childOffset = (current.parentData as dynamic).offset as Offset;
        final childSize = current.size as Size;
        final childRect = childOffset & childSize;

        if (localInEditor.dy >= childRect.top && localInEditor.dy <= childRect.bottom) {
          closestChild = current;
          break;
        }

        final dist = (localInEditor.dy < childRect.top)
            ? (childRect.top - localInEditor.dy)
            : (localInEditor.dy - childRect.bottom);
        if (dist < closestDistance) {
          closestDistance = dist;
          closestChild = current;
        }

        current = renderEditor.childAfter(current);
      }

      if (closestChild != null) {
        final childOffset = (closestChild.parentData as dynamic).offset as Offset;
        final childLocal = localInEditor - childOffset;
        final TextPosition childPos = closestChild.getPositionForOffset(childLocal);
        final int lineStart = (closestChild.line?.documentOffset ?? closestChild.line?.offset ?? 0) as int;
        return TextPosition(offset: lineStart + childPos.offset, affinity: childPos.affinity);
      }
    } catch (_) {}

    return renderEditor.getPositionForOffset(localInEditor);
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.focusNode.hasFocus) {
      widget.focusNode.requestFocus();
    }
    _isDragging = true;
    _fadeTimer?.cancel();
    _fadeController.value = 1.0;

    final rawEditorState =
        widget.editorKey.currentState?.editableTextKey.currentState;
    if (rawEditorState != null) {
      final renderEditor = rawEditorState.renderEditor;
      final selection = widget.controller.selection;
      if (selection.isCollapsed && selection.baseOffset >= 0) {
        try {
          final caretRect = renderEditor.getLocalRectForCaret(selection.extent);
          final caretGlobal = renderEditor.localToGlobal(
            Offset(caretRect.left + (caretRect.width / 2), caretRect.bottom),
          );
          _caretBottomPosition = caretGlobal;
          _caretHeight = caretRect.height > 0 ? caretRect.height : 20.0;
          _activeLineTop = caretRect.top;
          _activeLineBottom = caretRect.bottom;
          _activeLineCenterY = caretRect.top + (caretRect.height / 2);
        } catch (_) {}
      }
    }

    if (_caretBottomPosition != null) {
      _dragStartTouchOffset = details.globalPosition - _caretBottomPosition!;
    } else {
      _dragStartTouchOffset = const Offset(0.0, 20.0);
    }
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final rawEditorState =
        widget.editorKey.currentState?.editableTextKey.currentState;
    if (rawEditorState == null) return;

    final renderEditor = rawEditorState.renderEditor;
    final selection = widget.controller.selection;
    if (!selection.isCollapsed || selection.baseOffset < 0) return;

    // Track target caret point smoothly based on initial grab offset
    final targetCaretGlobal = details.globalPosition - _dragStartTouchOffset;
    // Aim for the vertical center of the text line
    final targetPointInGlobal = targetCaretGlobal.translate(0, -(_caretHeight * 0.5));
    final targetInEditor = renderEditor.globalToLocal(targetPointInGlobal);

    final double maxW = math.max(0.0, renderEditor.size.width);
    final double maxH = math.max(0.0, renderEditor.size.height - 1.0);

    // Apply vertical hysteresis / line-locking to eliminate erratic jumping between lines
    double effectiveTargetY = targetInEditor.dy;
    if (_activeLineCenterY != null && _activeLineTop != null && _activeLineBottom != null) {
      final lineH = math.max(16.0, _activeLineBottom! - _activeLineTop!);
      final threshold = lineH * 0.75;
      final distFromCenter = targetInEditor.dy - _activeLineCenterY!;
      if (distFromCenter.abs() < threshold) {
        // Locked stably to current line's vertical center for ultra-sensitive, jitter-free horizontal scrubbing
        effectiveTargetY = _activeLineCenterY!;
      }
    }

    final safeTarget = Offset(
      targetInEditor.dx.clamp(0.0, maxW),
      effectiveTargetY.clamp(0.0, maxH),
    );

    final resolvedPosition = _getPositionForOffset(renderEditor, safeTarget);
    final currentOffset = widget.controller.selection.baseOffset;

    if (resolvedPosition.offset != currentOffset) {
      HapticFeedback.selectionClick();
      widget.controller.updateSelection(
        TextSelection.collapsed(offset: resolvedPosition.offset),
        ChangeSource.local,
      );
    }

    // Immediately re-sync line metrics & exact caret position with high fidelity
    try {
      final currentSelection = widget.controller.selection;
      final newCaretRect = renderEditor.getLocalRectForCaret(currentSelection.extent);
      _activeLineTop = newCaretRect.top;
      _activeLineBottom = newCaretRect.bottom;
      _activeLineCenterY = newCaretRect.top + (newCaretRect.height / 2);
      _caretHeight = newCaretRect.height > 0 ? newCaretRect.height : 20.0;
      final caretGlobal = renderEditor.localToGlobal(
        Offset(newCaretRect.left + (newCaretRect.width / 2), newCaretRect.bottom),
      );
      setState(() {
        _caretBottomPosition = caretGlobal;
      });
    } catch (_) {}

    // Auto-scroll vertically if dragged near top/bottom viewport edge and content is scrollable
    final scrollCtrl = widget.scrollController;
    if (scrollCtrl != null && scrollCtrl.hasClients && scrollCtrl.position.maxScrollExtent > 0) {
      final editorBox = widget.editorKey.currentContext?.findRenderObject() as RenderBox?;
      if (editorBox != null && editorBox.hasSize) {
        final localTouchInViewport = editorBox.globalToLocal(details.globalPosition);
        const edgeThreshold = 36.0;
        final viewportHeight = editorBox.size.height;

        if (localTouchInViewport.dy < edgeThreshold && scrollCtrl.offset > 0) {
          final speed = math.min(10.0, math.max(1.0, (edgeThreshold - localTouchInViewport.dy) / 3));
          scrollCtrl.jumpTo(math.max(0.0, scrollCtrl.offset - speed));
        } else if (localTouchInViewport.dy > viewportHeight - edgeThreshold &&
            scrollCtrl.offset < scrollCtrl.position.maxScrollExtent) {
          final speed = math.min(10.0, math.max(1.0, (localTouchInViewport.dy - (viewportHeight - edgeThreshold)) / 3));
          scrollCtrl.jumpTo(
            math.min(scrollCtrl.position.maxScrollExtent, scrollCtrl.offset + speed),
          );
        }
      }
    }
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
