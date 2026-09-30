import 'dart:async';
import 'dart:convert';
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
                              return const TextStyle();
                            },
                            // ignore: experimental_member_use
                            customLeadingBlockBuilder: (node, config) {
                              final blockHeightAttr = node.style.attributes[Attribute.lineHeight.key];
                              final customHeight = blockHeightAttr?.value != null
                                  ? double.tryParse(blockHeightAttr!.value.toString())
                                  : null;
                              final effectiveHeight = customHeight ?? 1.6;

                              final baseListStyle = TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: const Color(0xFF1E293B),
                                height: effectiveHeight,
                              );
                              final effectiveStyle = (config.style ?? baseListStyle).copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                height: effectiveHeight,
                              );
                              final firstLineHeight = 15.0 * effectiveHeight;

                              if (config.attribute == Attribute.ul) {
                                return Container(
                                  width: config.width ?? 28.0,
                                  height: firstLineHeight,
                                  padding: EdgeInsetsDirectional.only(end: config.padding ?? 8.0),
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Container(
                                    width: 5.5,
                                    height: 5.5,
                                    decoration: BoxDecoration(
                                      color: effectiveStyle.color ?? const Color(0xFF1E293B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              }

                              if (config.attribute == Attribute.ol) {
                                final numberStr =
                                    '${config.getIndexNumberByIndent ?? '1'}${config.withDot ? '.' : ''}';
                                return Container(
                                  width: config.width ?? 28.0,
                                  height: firstLineHeight,
                                  padding: EdgeInsetsDirectional.only(end: config.padding ?? 8.0),
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Text(
                                    numberStr,
                                    style: effectiveStyle,
                                    strutStyle: StrutStyle.fromTextStyle(
                                      effectiveStyle,
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
