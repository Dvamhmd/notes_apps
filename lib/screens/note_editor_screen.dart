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
    _debounceTimer?.cancel();
    _saveImmediately();
    _titleController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  void _scheduleAutoSave() {
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

  void _showLineSpacingDialog() {
    final selStyle = _quillController.getSelectionStyle();
    final lineAttr = selStyle.attributes[Attribute.lineHeight.key];
    final double activeSpacing =
        (lineAttr?.value != null ? double.tryParse(lineAttr!.value.toString()) : null) ?? 1.6;

    LineSpacingSheet.show(
      context: context,
      currentSpacing: activeSpacing,
      onSpacingChanged: (newSpacing) {
        _quillController.formatSelection(
          Attribute.clone(Attribute.lineHeight, newSpacing),
        );
        _scheduleAutoSave();
      },
      onReset: () {
        _quillController.formatSelection(
          Attribute.clone(Attribute.lineHeight, null),
        );
        _scheduleAutoSave();
      },
    );
  }

  bool get _isAlignCenter {
    final style = _quillController.getSelectionStyle();
    final attr = style.attributes[Attribute.align.key];
    return attr != null && attr.value == 'center';
  }

  bool get _isAlignRight {
    final style = _quillController.getSelectionStyle();
    final attr = style.attributes[Attribute.align.key];
    return attr != null && attr.value == 'right';
  }

  bool get _isAlignJustify {
    final style = _quillController.getSelectionStyle();
    final attr = style.attributes[Attribute.align.key];
    return attr != null && attr.value == 'justify';
  }

  bool get _isAlignLeft {
    final style = _quillController.getSelectionStyle();
    final attr = style.attributes[Attribute.align.key];
    return attr == null || attr.value == 'left' || attr.value == null;
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
      onPopInvokedWithResult: (didPop, result) {
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
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF1E293B),
            ),
            onPressed: () {
              _saveImmediately();
              Navigator.of(context).pop();
            },
          ),
          title: TextField(
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
          actions: [
            // 1. Tombol Perataan Teks (Menyamping, Icon Saja, Tidak Tertutup Otomatis + Tombol Silang)
            PopupMenuButton<void>(
              tooltip: 'Perataan Teks',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: Colors.white,
              elevation: 4,
              icon: Icon(
                _isAlignCenter
                    ? Icons.format_align_center_rounded
                    : (_isAlignRight
                        ? Icons.format_align_right_rounded
                        : (_isAlignJustify
                            ? Icons.format_align_justify_rounded
                            : Icons.format_align_left_rounded)),
                color: const Color(0xFF1E293B),
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
                            icon: Icons.format_align_left_rounded,
                            tooltip: 'Rata Kiri',
                            isActive: _isAlignLeft,
                            onTap: () {
                              _quillController.formatSelection(Attribute.leftAlignment);
                              setMenuState(() {});
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 4),
                          _buildPopupIconButton(
                            icon: Icons.format_align_center_rounded,
                            tooltip: 'Rata Tengah',
                            isActive: _isAlignCenter,
                            onTap: () {
                              _quillController.formatSelection(Attribute.centerAlignment);
                              setMenuState(() {});
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 4),
                          _buildPopupIconButton(
                            icon: Icons.format_align_right_rounded,
                            tooltip: 'Rata Kanan',
                            isActive: _isAlignRight,
                            onTap: () {
                              _quillController.formatSelection(Attribute.rightAlignment);
                              setMenuState(() {});
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 4),
                          _buildPopupIconButton(
                            icon: Icons.format_align_justify_rounded,
                            tooltip: 'Rata Kanan-Kiri (Justify)',
                            isActive: _isAlignJustify,
                            onTap: () {
                              _quillController.formatSelection(Attribute.justifyAlignment);
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
            // 2. Tombol Undo & Redo (Menyamping, Icon Saja, Tidak Tertutup Otomatis + Tombol Silang)
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
                            enableSelectionToolbar: true,
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
                              final buttonItems = rawEditorState.contextMenuButtonItems;
                              return AdaptiveTextSelectionToolbar.buttonItems(
                                anchors: rawEditorState.contextMenuAnchors,
                                buttonItems: buttonItems.map((item) {
                                  if (item.type == ContextMenuButtonType.copy) {
                                    return item.copyWith(
                                      onPressed: () {
                                        RichClipboardService.copySelection(_quillController);
                                        rawEditorState.hideToolbar();
                                      },
                                    );
                                  }
                                  if (item.type == ContextMenuButtonType.cut) {
                                    return item.copyWith(
                                      onPressed: () {
                                        RichClipboardService.cutSelection(_quillController);
                                        rawEditorState.hideToolbar();
                                      },
                                    );
                                  }
                                  if (item.type == ContextMenuButtonType.paste) {
                                    return item.copyWith(
                                      onPressed: () async {
                                        await RichClipboardService.paste(_quillController);
                                        rawEditorState.hideToolbar();
                                      },
                                    );
                                  }
                                  return item;
                                }).toList(),
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
                                if (h != null) {
                                  return TextStyle(height: h);
                                }
                              }
                              if (attribute.key == Attribute.size.key) {
                                final val = attribute.value;
                                if (val != null) {
                                  if (val == 'small') return const TextStyle(fontSize: 12);
                                  if (val == 'normal') return const TextStyle(fontSize: 15);
                                  if (val == 'large') return const TextStyle(fontSize: 20);
                                  if (val == 'huge') return const TextStyle(fontSize: 26);
                                  final size = double.tryParse(val.toString());
                                  if (size != null) {
                                    return TextStyle(fontSize: size);
                                  }
                                }
                              }
                              return const TextStyle();
                            },
                            // ignore: experimental_member_use
                            customLeadingBlockBuilder: (node, config) {
                              final effectiveFontSize = _resolveEffectiveFontSize(node, config);
                              final effectiveColor = _resolveEffectiveColor(node, config);
                              final effectiveFontWeight = _resolveEffectiveFontWeight(node, config);

                              final blockHeightAttr = node.style.attributes[Attribute.lineHeight.key];
                              final customHeight = blockHeightAttr?.value != null
                                  ? double.tryParse(blockHeightAttr!.value.toString())
                                  : null;
                              final effectiveHeight = customHeight ?? 1.6;

                              // The list line in Flutter Quill has a minimum bounding strut of 15.0 pt
                              // and expands when text font size is larger than 15.0 pt.
                              final nominalFontSize = math.max(15.0, effectiveFontSize);
                              final lineBoxHeight = nominalFontSize * effectiveHeight;

                              if (config.attribute == Attribute.ul) {
                                final bulletSize = (effectiveFontSize * 0.38).clamp(3.5, 14.0);
                                final leadingWidth = (effectiveFontSize * 1.7).clamp(24.0, 48.0);
                                final paddingEnd = (effectiveFontSize * 0.45).clamp(6.0, 16.0);

                                // Optical vertical center calculation for Poppins text glyphs
                                final baselineY = (lineBoxHeight / 2) + (nominalFontSize * 0.35);
                                final opticalCenterY = baselineY - (effectiveFontSize * 0.35);
                                final bulletTop = (opticalCenterY - (bulletSize / 2)).clamp(0.0, lineBoxHeight - bulletSize);

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
                                final paddingEnd = (effectiveFontSize * 0.4).clamp(6.0, 16.0);
                                final estimatedCharWidth = effectiveFontSize * 0.62;
                                final neededWidth = (numberStr.length * estimatedCharWidth) + paddingEnd + 4.0;
                                final dynamicWidth = neededWidth.clamp(28.0, 72.0);

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
                            customStyles: const DefaultStyles(
                              link: TextStyle(
                                color: Color(0xFF2563EB),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF2563EB),
                                decorationThickness: 1.3,
                              ),
                              paragraph: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                  height: 1.6,
                                ),
                                HorizontalSpacing(0, 0),
                                VerticalSpacing(0, 1.8),
                                VerticalSpacing(0, 0),
                                null,
                              ),
                              h1: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  height: 1.35,
                                ),
                                HorizontalSpacing(0, 0),
                                VerticalSpacing(16, 8),
                                VerticalSpacing(0, 0),
                                null,
                              ),
                              h2: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                  height: 1.45,
                                ),
                                HorizontalSpacing(0, 0),
                                VerticalSpacing(12, 6),
                                VerticalSpacing(0, 0),
                                null,
                              ),
                              h3: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                  height: 1.5,
                                ),
                                HorizontalSpacing(0, 0),
                                VerticalSpacing(8, 4),
                                VerticalSpacing(0, 0),
                                null,
                              ),
                              lists: DefaultListBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                  height: 1.6,
                                ),
                                HorizontalSpacing(0, 0),
                                VerticalSpacing(2, 1.2),
                                VerticalSpacing(0, 0),
                                null,
                                null,
                              ),
                              leading: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                  height: 1.6,
                                ),
                                HorizontalSpacing(0, 0),
                                VerticalSpacing(0, 0),
                                VerticalSpacing(0, 0),
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
                // Custom Toolbar for Rich Text Styling & Line Spacing
                CustomToolbar(
                  controller: _quillController,
                  lineSpacing: 1.6,
                  onLineSpacingChanged: (val) {
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
