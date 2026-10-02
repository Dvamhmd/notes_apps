import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../services/link_service.dart';
import '../services/rich_clipboard_service.dart';
import '../services/smart_quill_controller.dart';
import '../widgets/custom_selection_controls.dart';
import '../widgets/custom_toolbar.dart';
import '../widgets/divider_embed_builder.dart';
import '../widgets/line_spacing_sheet.dart';
import '../widgets/quill_cursor_handle_overlay.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel note;
  final List<FolderModel> folders;
  final Function(NoteModel) onSave;
  final Function(String) onDelete;
  final Function(FolderModel) onFolderCreated;

  const NoteEditorScreen({
    super.key,
    required this.note,
    required this.folders,
    required this.onSave,
    required this.onDelete,
    required this.onFolderCreated,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late SmartQuillController _quillController;
  late FocusNode _editorFocusNode;
  late ScrollController _editorScrollController;
  final GlobalKey<QuillEditorState> _editorKey = GlobalKey<QuillEditorState>();

  late String? _currentFolderId;
  late bool _isPinned;
  late double _lineSpacing;
  Timer? _debounceTimer;

  // Search in note state
  bool _isSearchMode = false;
  final TextEditingController _inNoteSearchController = TextEditingController();
  final FocusNode _inNoteSearchFocusNode = FocusNode();
  List<int> _searchMatches = [];
  int _currentMatchIndex = 0;

  // Zoom state for pinch-to-zoom (gesture cubit)
  double _zoomScale = 1.0;
  double _baseZoomScale = 1.0;
  double _initialPinchDistance = 0.0;
  final Map<int, Offset> _pinchPointers = {};

  void _handlePointerDown(PointerDownEvent event) {
    _pinchPointers[event.pointer] = event.position;
    if (_pinchPointers.length == 2) {
      final points = _pinchPointers.values.toList();
      _initialPinchDistance = (points[0] - points[1]).distance;
      _baseZoomScale = _zoomScale;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_pinchPointers.containsKey(event.pointer)) {
      _pinchPointers[event.pointer] = event.position;
    }
    if (_pinchPointers.length >= 2 && _initialPinchDistance > 10.0) {
      final points = _pinchPointers.values.toList();
      final currentDistance = (points[0] - points[1]).distance;
      final scaleFactor = currentDistance / _initialPinchDistance;
      final newScale = (_baseZoomScale * scaleFactor).clamp(0.6, 3.0);
      if ((newScale - _zoomScale).abs() > 0.005) {
        setState(() {
          _zoomScale = newScale;
        });
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pinchPointers.remove(event.pointer);
    if (_pinchPointers.length < 2) {
      _initialPinchDistance = 0.0;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pinchPointers.remove(event.pointer);
    if (_pinchPointers.length < 2) {
      _initialPinchDistance = 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _editorFocusNode = FocusNode();
    _editorScrollController = ScrollController();
    _currentFolderId = widget.note.folderId;
    _isPinned = widget.note.isPinned;
    _lineSpacing = widget.note.lineSpacing ?? 1.6;

    _initQuill();
    RichClipboardService.activeController = _quillController;

    _titleController.addListener(_scheduleAutoSave);
    _quillController.addListener(_scheduleAutoSave);
  }

  void _initQuill() {
    try {
      if (widget.note.contentJson.isNotEmpty) {
        final dynamic decoded = json.decode(widget.note.contentJson);
        if (decoded is List) {
          final doc = Document.fromJson(decoded);
          _quillController = SmartQuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
          return;
        }
      }
    } catch (_) {}

    _quillController = SmartQuillController.basic();
  }

  @override
  void dispose() {
    if (RichClipboardService.activeController == _quillController) {
      RichClipboardService.activeController = null;
    }
    _debounceTimer?.cancel();
    _saveImmediately();
    _titleController.dispose();
    _inNoteSearchController.dispose();
    _inNoteSearchFocusNode.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _openSearchMode() {
    _editorFocusNode.canRequestFocus = false;
    _editorFocusNode.unfocus();
    setState(() {
      _isSearchMode = true;
      _searchMatches.clear();
      _currentMatchIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isSearchMode) {
        _inNoteSearchFocusNode.requestFocus();
        if (_inNoteSearchController.text.trim().isNotEmpty) {
          _performSearch(_inNoteSearchController.text);
        }
      }
    });
  }

  void _closeSearchMode() {
    final int? selectedMatchOffset = (_searchMatches.isNotEmpty &&
            _currentMatchIndex >= 0 &&
            _currentMatchIndex < _searchMatches.length)
        ? _searchMatches[_currentMatchIndex]
        : null;

    _editorFocusNode.canRequestFocus = true;
    setState(() {
      _isSearchMode = false;
      _searchMatches.clear();
      _currentMatchIndex = 0;
      _inNoteSearchController.clear();
    });
    _inNoteSearchFocusNode.unfocus();

    final docLen = _quillController.document.length;
    final targetOffset = selectedMatchOffset != null
        ? selectedMatchOffset.clamp(0, docLen > 0 ? docLen - 1 : 0)
        : _quillController.selection.baseOffset.clamp(0, docLen > 0 ? docLen - 1 : 0);

    _quillController.updateSelection(
      TextSelection.collapsed(offset: targetOffset),
      ChangeSource.local,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isSearchMode) {
        _editorFocusNode.requestFocus();
      }
    });
  }

  void _performSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchMatches = [];
        _currentMatchIndex = 0;
      });
      final docLen = _quillController.document.length;
      final currentOffset = _quillController.selection.baseOffset.clamp(0, docLen > 0 ? docLen - 1 : 0);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: currentOffset),
        ChangeSource.local,
      );
      return;
    }

    final plainText = _quillController.document.toPlainText();
    final lowerText = plainText.toLowerCase();
    final lowerQuery = trimmed.toLowerCase();
    final matches = <int>[];

    int startIndex = 0;
    while (startIndex < lowerText.length) {
      final index = lowerText.indexOf(lowerQuery, startIndex);
      if (index == -1) break;
      matches.add(index);
      startIndex = index + lowerQuery.length;
    }

    setState(() {
      _searchMatches = matches;
      if (_currentMatchIndex >= _searchMatches.length) {
        _currentMatchIndex = 0;
      }
    });

    if (matches.isNotEmpty) {
      _highlightCurrentMatch(trimmed.length);
    } else {
      final docLen = _quillController.document.length;
      final currentOffset = _quillController.selection.baseOffset.clamp(0, docLen > 0 ? docLen - 1 : 0);
      _quillController.updateSelection(
        TextSelection.collapsed(offset: currentOffset),
        ChangeSource.local,
      );
    }
  }

  void _highlightCurrentMatch(int matchLength) {
    if (_searchMatches.isEmpty || _currentMatchIndex < 0 || _currentMatchIndex >= _searchMatches.length) {
      return;
    }
    final offset = _searchMatches[_currentMatchIndex];
    _quillController.updateSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + matchLength),
      ChangeSource.remote,
    );

    if (_editorScrollController.hasClients && _editorScrollController.position.maxScrollExtent > 0) {
      final docLen = math.max(1, _quillController.document.length);
      final progress = offset / docLen;
      final targetScroll = (progress * _editorScrollController.position.maxScrollExtent)
          .clamp(0.0, _editorScrollController.position.maxScrollExtent);
      _editorScrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  void _goToNextMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
    });
    _highlightCurrentMatch(_inNoteSearchController.text.trim().length);
  }

  void _goToPreviousMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) % _searchMatches.length;
    });
    _highlightCurrentMatch(_inNoteSearchController.text.trim().length);
  }

  void _scheduleAutoSave() {
    if (_isSearchMode) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _saveImmediately();
    });
  }

  void _saveImmediately() {
    if (!mounted) return;
    final contentJson = json.encode(
      _quillController.document.toDelta().toJson(),
    );
    final plainText = _quillController.document.toPlainText().trim();
    final title = _titleController.text.trim().isEmpty
        ? 'Tanpa Judul'
        : _titleController.text.trim();

    final updatedNote = widget.note.copyWith(
      title: title,
      contentJson: contentJson,
      plainText: plainText,
      folderId: _currentFolderId,
      isPinned: _isPinned,
      lineSpacing: _lineSpacing,
      updatedAt: DateTime.now(),
    );

    widget.onSave(updatedNote);
  }

  void _showLineSpacingDialog() async {
    _editorFocusNode.canRequestFocus = false;
    _editorFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final selStyle = _quillController.getSelectionStyle();
    final lineAttr = selStyle.attributes[Attribute.lineHeight.key];
    final double activeSpacing =
        (lineAttr?.value != null ? double.tryParse(lineAttr!.value.toString()) : null) ?? _lineSpacing;

    try {
      await LineSpacingSheet.show(
        context: context,
        currentSpacing: activeSpacing.clamp(1.0, 2.8),
        onSpacingChanged: (newSpacing) {
          final clampedVal = double.parse(newSpacing.clamp(1.0, 2.8).toStringAsFixed(2));
          final selection = _quillController.selection;
          if (selection.isCollapsed) {
            final docLength = _quillController.document.length;
            if (docLength > 0) {
              _quillController.document.format(
                0,
                docLength,
                Attribute.clone(Attribute.lineHeight, clampedVal),
              );
            }
          } else {
            _quillController.formatSelection(
              Attribute.clone(Attribute.lineHeight, clampedVal),
            );
          }
          setState(() {
            _lineSpacing = clampedVal;
          });
          _scheduleAutoSave();
        },
        onReset: () {
          final selection = _quillController.selection;
          if (selection.isCollapsed) {
            final docLength = _quillController.document.length;
            if (docLength > 0) {
              _quillController.document.format(
                0,
                docLength,
                Attribute.clone(Attribute.lineHeight, null),
              );
            }
          } else {
            _quillController.formatSelection(
              Attribute.clone(Attribute.lineHeight, null),
            );
          }
          setState(() {
            _lineSpacing = 1.6;
          });
          _scheduleAutoSave();
        },
      );
    } finally {
      _editorFocusNode.canRequestFocus = true;
    }
  }

  Widget _buildPopupIconButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? (isActive ? const Color(0xFF4F46E5) : const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }

  double _resolveEffectiveFontSize(dynamic node, dynamic config) {
    // 1. Check direct attributes on node.style
    if (node != null && node.style != null) {
      final sizeAttr = node.style.attributes[Attribute.size.key];
      if (sizeAttr != null && sizeAttr.value != null) {
        final s = _parseSizeValue(sizeAttr.value);
        if (s != null) return s;
      }
      final headerAttr = node.style.attributes[Attribute.header.key];
      if (headerAttr != null && headerAttr.value != null) {
        final h = _parseHeaderValue(headerAttr.value);
        if (h != null) return h;
      }
    }

    // 2. Check child leaves within the line
    try {
      if (node != null && node.children != null) {
        for (final child in node.children) {
          if (child != null && child.style != null) {
            final sizeAttr = child.style.attributes[Attribute.size.key];
            if (sizeAttr != null && sizeAttr.value != null) {
              final s = _parseSizeValue(sizeAttr.value);
              if (s != null) return s;
            }
            final headerAttr = child.style.attributes[Attribute.header.key];
            if (headerAttr != null && headerAttr.value != null) {
              final h = _parseHeaderValue(headerAttr.value);
              if (h != null) return h;
            }
          }
        }
      }
    } catch (_) {}

    // 3. Check config.style
    if (config != null && config.style != null && config.style.fontSize != null) {
      return config.style.fontSize!;
    }

    return 15.0;
  }

  double? _parseSizeValue(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim().toLowerCase();
    if (str == 'small') return 12.0;
    if (str == 'normal') return 15.0;
    if (str == 'large') return 20.0;
    if (str == 'huge') return 26.0;
    final num = double.tryParse(str);
    if (num != null && num > 0) return num;
    return null;
  }

  double? _parseHeaderValue(dynamic value) {
    if (value == null) return null;
    if (value == 1 || value == '1' || value == 'h1') return 24.0;
    if (value == 2 || value == '2' || value == 'h2') return 20.0;
    if (value == 3 || value == '3' || value == 'h3') return 17.0;
    return null;
  }

  Color _resolveEffectiveColor(dynamic node, dynamic config) {
    try {
      if (node != null && node.children != null) {
        for (final child in node.children) {
          if (child != null && child.style != null) {
            final colorAttr = child.style.attributes[Attribute.color.key];
            if (colorAttr != null && colorAttr.value != null) {
              final c = _parseColorValue(colorAttr.value);
              if (c != null) return c;
            }
          }
        }
      }
    } catch (_) {}

    if (node != null && node.style != null) {
      final colorAttr = node.style.attributes[Attribute.color.key];
      if (colorAttr != null && colorAttr.value != null) {
        final c = _parseColorValue(colorAttr.value);
        if (c != null) return c;
      }
    }

    if (config != null && config.style != null && config.style.color != null) {
      return config.style.color!;
    }

    return const Color(0xFF1E293B);
  }

  Color? _parseColorValue(dynamic value) {
    if (value == null) return null;
    try {
      final hexStr = value.toString().replaceAll('#', '');
      if (hexStr.length == 6) {
        return Color(int.parse('FF$hexStr', radix: 16));
      } else if (hexStr.length == 8) {
        return Color(int.parse(hexStr, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  FontWeight _resolveEffectiveFontWeight(dynamic node, dynamic config) {
    try {
      if (node != null && node.children != null) {
        for (final child in node.children) {
          if (child != null && child.style != null) {
            if (child.style.attributes.containsKey(Attribute.bold.key)) {
              return FontWeight.w700;
            }
          }
        }
      }
    } catch (_) {}
    if (node != null && node.style != null && node.style.attributes.containsKey(Attribute.bold.key)) {
      return FontWeight.w700;
    }
    return FontWeight.w500;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearchMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearchMode) {
          _closeSearchMode();
          return;
        }
        _saveImmediately();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
          ),
          leading: _isSearchMode
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFF1E293B),
                  ),
                  tooltip: 'Kembali',
                  onPressed: _closeSearchMode,
                )
              : IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: Color(0xFF1E293B),
                  ),
                  tooltip: 'Kembali',
                  onPressed: () {
                    _saveImmediately();
                    Navigator.of(context).pop();
                  },
                ),
          title: _isSearchMode
              ? TextField(
                  controller: _inNoteSearchController,
                  focusNode: _inNoteSearchFocusNode,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari dalam catatan...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    suffixIcon: _inNoteSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            tooltip: 'Hapus Teks',
                            onPressed: () {
                              _inNoteSearchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _performSearch,
                  onSubmitted: (_) => _goToNextMatch(),
                )
              : TextField(
                  controller: _titleController,
                  selectionControls: CustomTouchTextSelectionControls.instance,
                  enableInteractiveSelection: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Judul Catatan...',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF94A3B8),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
          actions: _isSearchMode
              ? [
                  if (_inNoteSearchController.text.trim().isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _searchMatches.isNotEmpty
                            ? const Color(0xFFEEF2FF)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _searchMatches.isNotEmpty
                              ? const Color(0xFFC7D2FE)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _searchMatches.isNotEmpty
                            ? '${_currentMatchIndex + 1}/${_searchMatches.length}'
                            : '0 hasil',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _searchMatches.isNotEmpty
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 22),
                      color: _searchMatches.isNotEmpty
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFCBD5E1),
                      tooltip: 'Sebelumnya',
                      onPressed: _searchMatches.isNotEmpty ? _goToPreviousMatch : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                      color: _searchMatches.isNotEmpty
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFCBD5E1),
                      tooltip: 'Berikutnya',
                      onPressed: _searchMatches.isNotEmpty ? _goToNextMatch : null,
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    tooltip: 'Tutup Pencarian',
                    onPressed: _closeSearchMode,
                  ),
                  const SizedBox(width: 4),
                ]
              : [
                  // Tombol Cari Teks di Catatan
                  IconButton(
                    icon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1E293B),
                      size: 22,
                    ),
                    tooltip: 'Cari Teks di Catatan',
                    onPressed: _openSearchMode,
                  ),
                  // Tombol Undo & Redo (Menyamping, Icon Saja, Tidak Tertutup Otomatis + Tombol Silang)
                  PopupMenuButton<void>(
                    tooltip: 'Riwayat (Undo / Redo)',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    color: Colors.white,
                    elevation: 4,
                    icon: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF1E293B),
                      size: 22,
                    ),
                    itemBuilder: (ctx) => [
                      PopupMenuItem<void>(
                        enabled: false,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: StatefulBuilder(
                          builder: (context, setMenuState) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildPopupIconButton(
                                  icon: Icons.undo_rounded,
                                  tooltip: 'Batal (Undo)',
                                  isActive: false,
                                  onTap: () {
                                    _quillController.undo();
                                    setMenuState(() {});
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(width: 4),
                                _buildPopupIconButton(
                                  icon: Icons.redo_rounded,
                                  tooltip: 'Ulangi (Redo)',
                                  isActive: false,
                                  onTap: () {
                                    _quillController.redo();
                                    setMenuState(() {});
                                    setState(() {});
                                  },
                                ),
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: const Color(0xFFE2E8F0),
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                                _buildPopupIconButton(
                                  icon: Icons.close_rounded,
                                  tooltip: 'Tutup',
                                  isActive: false,
                                  iconColor: const Color(0xFF64748B),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                // Editor Body
                Expanded(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: _handlePointerDown,
                    onPointerMove: _handlePointerMove,
                    onPointerUp: _handlePointerUp,
                    onPointerCancel: _handlePointerCancel,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: CallbackShortcuts(
                        bindings: <ShortcutActivator, VoidCallback>{
                          const SingleActivator(LogicalKeyboardKey.keyC, control: true): () {
                            RichClipboardService.copySelection(_quillController);
                          },
                          const SingleActivator(LogicalKeyboardKey.keyC, meta: true): () {
                            RichClipboardService.copySelection(_quillController);
                          },
                          const SingleActivator(LogicalKeyboardKey.keyX, control: true): () {
                            RichClipboardService.cutSelection(_quillController);
                          },
                          const SingleActivator(LogicalKeyboardKey.keyX, meta: true): () {
                            RichClipboardService.cutSelection(_quillController);
                          },
                          const SingleActivator(LogicalKeyboardKey.keyV, control: true): () {
                            RichClipboardService.paste(_quillController);
                          },
                          const SingleActivator(LogicalKeyboardKey.keyV, meta: true): () {
                            RichClipboardService.paste(_quillController);
                          },
                        },
                        child: Actions(
                          actions: <Type, Action<Intent>>{
                            CopySelectionTextIntent: CallbackAction<CopySelectionTextIntent>(
                              onInvoke: (intent) {
                                RichClipboardService.copySelection(_quillController);
                                return null;
                              },
                            ),
                            PasteTextIntent: CallbackAction<PasteTextIntent>(
                              onInvoke: (intent) {
                                RichClipboardService.paste(_quillController);
                                return null;
                              },
                            ),
                            SelectAllTextIntent: CallbackAction<SelectAllTextIntent>(
                              onInvoke: (intent) {
                                final docLength = _quillController.document.length;
                                if (docLength > 1) {
                                  _quillController.updateSelection(
                                    TextSelection(baseOffset: 0, extentOffset: docLength - 1),
                                    ChangeSource.local,
                                  );
                                }
                                return null;
                              },
                            ),
                          },
                          child: QuillCursorHandleOverlay(
                            controller: _quillController,
                            focusNode: _editorFocusNode,
                            scrollController: _editorScrollController,
                            editorKey: _editorKey,
                            child: QuillEditor.basic(
                              key: _editorKey,
                            controller: _quillController,
                            focusNode: _editorFocusNode,
                            scrollController: _editorScrollController,
                            config: QuillEditorConfig(
                              enableInteractiveSelection: true,
                              showCursor: true,
                              paintCursorAboveText: true,
                              enableSelectionToolbar: !_isSearchMode,
                              textSelectionControls: CustomTouchTextSelectionControls.instance,
                              linkActionPickerDelegate: (context, link, node) async {
                                await LinkService.showLinkActionDialog(
                                  context,
                                  link,
                                  controller: _quillController,
                                );
                                return LinkMenuAction.none;
                              },
                              onLaunchUrl: (url) async {
                                await LinkService.showLinkActionDialog(
                                  context,
                                  url,
                                  controller: _quillController,
                                );
                              },
                              contextMenuBuilder: (context, rawEditorState) {
                                final selection = _quillController.selection;
                                final isCollapsed = selection.isCollapsed;

                                final items = <ContextMenuButtonItem>[];

                                if (!isCollapsed) {
                                  items.add(
                                    ContextMenuButtonItem(
                                      type: ContextMenuButtonType.cut,
                                      label: 'Potong',
                                      onPressed: () {
                                        RichClipboardService.cutSelection(_quillController);
                                        rawEditorState.hideToolbar();
                                      },
                                    ),
                                  );
                                  items.add(
                                    ContextMenuButtonItem(
                                      type: ContextMenuButtonType.copy,
                                      label: 'Salin',
                                      onPressed: () {
                                        RichClipboardService.copySelection(_quillController);
                                        rawEditorState.hideToolbar();
                                      },
                                    ),
                                  );
                                }

                                items.add(
                                  ContextMenuButtonItem(
                                    type: ContextMenuButtonType.paste,
                                    label: 'Tempel',
                                    onPressed: () async {
                                      await RichClipboardService.paste(_quillController);
                                      rawEditorState.hideToolbar();
                                    },
                                  ),
                                );

                                items.add(
                                  ContextMenuButtonItem(
                                    type: ContextMenuButtonType.selectAll,
                                    label: 'Pilih Semua',
                                    onPressed: () {
                                      rawEditorState.selectAll(SelectionChangedCause.toolbar);
                                    },
                                  ),
                                );

                                // Append any additional system/custom items (like share)
                                for (final rawItem in rawEditorState.contextMenuButtonItems) {
                                  if (rawItem.type != ContextMenuButtonType.cut &&
                                      rawItem.type != ContextMenuButtonType.copy &&
                                      rawItem.type != ContextMenuButtonType.paste &&
                                      rawItem.type != ContextMenuButtonType.selectAll) {
                                    items.add(rawItem);
                                  }
                                }

                                return AdaptiveTextSelectionToolbar.buttonItems(
                                  anchors: rawEditorState.contextMenuAnchors,
                                  buttonItems: items,
                                );
                              },
                              scrollable: true,
                              expands: true,
                              padding: const EdgeInsets.only(bottom: 80),
                              embedBuilders: [
                                DividerEmbedBuilder(),
                              ],
                              customStyleBuilder: (Attribute attribute) {
                                if (attribute.key == Attribute.link.key) {
                                  return const TextStyle(
                                    color: Color(0xFF2563EB),
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF2563EB),
                                    decorationThickness: 1.3,
                                  );
                                }
                                if (attribute.key == Attribute.underline.key) {
                                  return const TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 1.3,
                                    decorationStyle: TextDecorationStyle.solid,
                                  );
                                }
                                if (attribute.key == Attribute.lineHeight.key) {
                                  final h = double.tryParse(attribute.value?.toString() ?? '');
                                  if (h != null && h > 0) {
                                    return TextStyle(height: h.clamp(1.0, 3.0));
                                  }
                                }
                                if (attribute.key == Attribute.size.key) {
                                  final val = attribute.value;
                                  if (val != null) {
                                    if (val == 'small') return TextStyle(fontSize: 12 * _zoomScale);
                                    if (val == 'normal') return TextStyle(fontSize: 15 * _zoomScale);
                                    if (val == 'large') return TextStyle(fontSize: 20 * _zoomScale);
                                    if (val == 'huge') return TextStyle(fontSize: 26 * _zoomScale);
                                    final size = double.tryParse(val.toString());
                                    if (size != null) {
                                      return TextStyle(fontSize: size * _zoomScale);
                                    }
                                  }
                                }
                                if (attribute.key == Attribute.header.key) {
                                  final h = _parseHeaderValue(attribute.value);
                                  if (h != null) {
                                    return TextStyle(fontSize: h * _zoomScale);
                                  }
                                }
                                return const TextStyle();
                              },
                              // ignore: experimental_member_use
                              customLeadingBlockBuilder: (node, config) {
                                final effectiveFontSize = _resolveEffectiveFontSize(node, config) * _zoomScale;
                                final effectiveColor = _resolveEffectiveColor(node, config);
                                final effectiveFontWeight = _resolveEffectiveFontWeight(node, config);

                                final blockHeightAttr = node.style.attributes[Attribute.lineHeight.key];
                                final customHeight = blockHeightAttr?.value != null
                                    ? double.tryParse(blockHeightAttr!.value.toString())
                                    : null;
                                final effectiveHeight = (customHeight ?? _lineSpacing).clamp(1.0, 3.0);

                                // The list line in Flutter Quill has a minimum bounding strut of 15.0 pt
                                // and expands when text font size is larger than 15.0 pt.
                                final nominalFontSize = math.max(15.0 * _zoomScale, effectiveFontSize);
                                final lineBoxHeight = nominalFontSize * effectiveHeight;

                                if (config.attribute == Attribute.ul) {
                                  final bulletSize = (effectiveFontSize * 0.38).clamp(3.5 * _zoomScale, 14.0 * _zoomScale);
                                  final leadingWidth = (effectiveFontSize * 1.7).clamp(24.0 * _zoomScale, 48.0 * _zoomScale);
                                  final paddingEnd = (effectiveFontSize * 0.45).clamp(6.0 * _zoomScale, 16.0 * _zoomScale);

                                  // Optical vertical center calculation for Poppins text glyphs
                                  final baselineY = (lineBoxHeight / 2) + (nominalFontSize * 0.35);
                                  final opticalCenterY = baselineY - (effectiveFontSize * 0.35);
                                  final maxBulletTop = math.max(0.0, lineBoxHeight - bulletSize);
                                  final bulletTop = (opticalCenterY - (bulletSize / 2)).clamp(0.0, maxBulletTop);

                                  return Container(
                                    width: leadingWidth,
                                    height: lineBoxHeight,
                                    padding: EdgeInsetsDirectional.only(end: paddingEnd),
                                    child: Align(
                                      alignment: AlignmentDirectional.topEnd,
                                      child: Padding(
                                        padding: EdgeInsets.only(top: bulletTop),
                                        child: Container(
                                          width: bulletSize,
                                          height: bulletSize,
                                          decoration: BoxDecoration(
                                            color: effectiveColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                if (config.attribute == Attribute.ol) {
                                  final numberStr =
                                      '${config.getIndexNumberByIndent ?? '1'}${config.withDot ? '.' : ''}';
                                  final paddingEnd = (effectiveFontSize * 0.4).clamp(6.0 * _zoomScale, 16.0 * _zoomScale);
                                  final estimatedCharWidth = effectiveFontSize * 0.62;
                                  final neededWidth = (numberStr.length * estimatedCharWidth) + paddingEnd + (4.0 * _zoomScale);
                                  final dynamicWidth = neededWidth.clamp(28.0 * _zoomScale, 72.0 * _zoomScale);

                                  final effectiveStyle = TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: effectiveFontSize,
                                    fontWeight: effectiveFontWeight,
                                    color: effectiveColor,
                                    height: effectiveHeight,
                                  );

                                  return Container(
                                    width: dynamicWidth,
                                    height: lineBoxHeight,
                                    padding: EdgeInsetsDirectional.only(end: paddingEnd),
                                    alignment: AlignmentDirectional.topEnd,
                                    child: Text(
                                      numberStr,
                                      style: effectiveStyle,
                                      strutStyle: StrutStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: nominalFontSize,
                                        height: effectiveHeight,
                                        forceStrutHeight: true,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  );
                                }

                                return null;
                              },
                              customStyles: DefaultStyles(
                                link: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFF2563EB),
                                  decorationThickness: 1.3,
                                ),
                                paragraph: DefaultTextBlockStyle(
                                  TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15 * _zoomScale,
                                    color: const Color(0xFF1E293B),
                                    height: _lineSpacing.clamp(1.0, 3.0),
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(0, 1.8),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                                h1: DefaultTextBlockStyle(
                                  TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 24 * _zoomScale,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                    height: (_lineSpacing * 0.85).clamp(1.1, 2.4),
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(16, 8),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                                h2: DefaultTextBlockStyle(
                                  TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20 * _zoomScale,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                    height: (_lineSpacing * 0.9).clamp(1.15, 2.5),
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(12, 6),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                                h3: DefaultTextBlockStyle(
                                  TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 17 * _zoomScale,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF334155),
                                    height: (_lineSpacing * 0.95).clamp(1.2, 2.6),
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(8, 4),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                                lists: DefaultListBlockStyle(
                                  TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15 * _zoomScale,
                                    color: const Color(0xFF1E293B),
                                    height: _lineSpacing.clamp(1.0, 3.0),
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(2, 1.2),
                                  const VerticalSpacing(0, 0),
                                  null,
                                  null,
                                ),
                                leading: DefaultTextBlockStyle(
                                  TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15 * _zoomScale,
                                    color: const Color(0xFF1E293B),
                                    height: _lineSpacing.clamp(1.0, 3.0),
                                  ),
                                  const HorizontalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  const VerticalSpacing(0, 0),
                                  null,
                                ),
                              ),
                            ),

                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
                // Custom Toolbar for Rich Text Styling & Line Spacing
                CustomToolbar(
                  controller: _quillController,
                  focusNode: _editorFocusNode,
                  lineSpacing: _lineSpacing,
                  onLineSpacingChanged: (val) {
                    setState(() {
                      _lineSpacing = val;
                    });
                    _scheduleAutoSave();
                  },
                  onOpenLineSpacing: _showLineSpacingDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
