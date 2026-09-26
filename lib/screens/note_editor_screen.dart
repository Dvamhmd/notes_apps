import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../services/rich_clipboard_service.dart';
import '../services/smart_quill_controller.dart';
import '../utils/folder_utils.dart';
import '../widgets/custom_selection_controls.dart';
import '../widgets/custom_toolbar.dart';
import '../widgets/line_spacing_sheet.dart';
import '../widgets/move_note_dialog.dart';

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

  late String? _currentFolderId;
  late bool _isPinned;
  late double _lineSpacing;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
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

  FolderModel? get _currentFolder {
    if (_currentFolderId == null) return null;
    try {
      return widget.folders.firstWhere((f) => f.id == _currentFolderId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _changeFolder() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => MoveNoteDialog(
        folders: widget.folders,
        currentFolderId: _currentFolderId,
        onFolderCreated: widget.onFolderCreated,
      ),
    );

    if (selected != null) {
      setState(() {
        if (selected == '__UNASSIGNED__') {
          _currentFolderId = null;
        } else {
          _currentFolderId = selected;
        }
      });
      _saveImmediately();
    }
  }

  void _showLineSpacingDialog() {
    LineSpacingSheet.show(
      context: context,
      currentSpacing: _lineSpacing,
      onSpacingChanged: (newSpacing) {
        setState(() {
          _lineSpacing = newSpacing;
        });
        _scheduleAutoSave();
      },
      onReset: () {
        setState(() {
          _lineSpacing = 1.6;
        });
        _scheduleAutoSave();
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Catatan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus catatan ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete(widget.note.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folder = _currentFolder;
    final folderPathStr = _currentFolderId != null
        ? FolderUtils.getFolderPathString(_currentFolderId, widget.folders)
        : 'Tanpa Folder';

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _saveImmediately();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
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
          title: InkWell(
            onTap: _changeFolder,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: folder != null
                    ? Color(folder.colorValue).withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: folder != null
                      ? Color(folder.colorValue).withValues(alpha: 0.3)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    folder != null ? Icons.folder_rounded : Icons.inbox_rounded,
                    size: 14,
                    color: folder != null
                        ? Color(folder.colorValue)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      folderPathStr,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: folder != null
                            ? Color(folder.colorValue)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: folder != null
                        ? Color(folder.colorValue)
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF64748B),
                size: 22,
              ),
              tooltip: _isPinned ? 'Lepas Pin' : 'Sematkan Catatan',
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                });
                _saveImmediately();
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF1E293B),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (val) {
                if (val == 'spacing') {
                  _showLineSpacingDialog();
                } else if (val == 'move') {
                  _changeFolder();
                } else if (val == 'delete') {
                  _confirmDelete();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'spacing',
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_line_spacing_rounded,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                      SizedBox(width: 10),
                      Text('Jarak Antar Baris', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'move',
                  child: Row(
                    children: [
                      Icon(
                        Icons.drive_file_move_rounded,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                      SizedBox(width: 10),
                      Text('Pindahkan Folder', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Hapus Catatan',
                        style: TextStyle(fontSize: 14, color: Color(0xFFEF4444)),
                      ),
                    ],
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
                // Title Input
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: TextField(
                    controller: _titleController,
                    selectionControls: CustomTouchTextSelectionControls.instance,
                    enableInteractiveSelection: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Judul Catatan...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF94A3B8),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                  indent: 20,
                  endIndent: 20,
                ),
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
                        child: QuillEditor.basic(
                          controller: _quillController,
                          config: QuillEditorConfig(
                            enableInteractiveSelection: true,
                            showCursor: true,
                            paintCursorAboveText: true,
                            enableSelectionToolbar: true,
                            textSelectionControls: CustomTouchTextSelectionControls.instance,
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
                            customStyleBuilder: (Attribute attribute) {
                              if (attribute.key == Attribute.underline.key) {
                                return const TextStyle(
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 1.3,
                                  decorationStyle: TextDecorationStyle.solid,
                                );
                              }
                              return const TextStyle();
                            },
                            // ignore: experimental_member_use
                            customLeadingBlockBuilder: (node, config) {
                              final baseListStyle = TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: const Color(0xFF1E293B),
                                height: _lineSpacing,
                              );
                              final effectiveStyle = (config.style ?? baseListStyle).copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                height: _lineSpacing,
                              );
                              final firstLineHeight = 15.0 * _lineSpacing;

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
                            customStyles: DefaultStyles(
                              paragraph: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: const Color(0xFF1E293B),
                                  height: _lineSpacing,
                                ),
                                const HorizontalSpacing(0, 0),
                                VerticalSpacing(0, (_lineSpacing - 1.0).clamp(0.0, 10.0) * 3),
                                const VerticalSpacing(0, 0),
                                null,
                              ),
                              h1: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                  height: (_lineSpacing * 0.85).clamp(1.1, 2.5),
                                ),
                                const HorizontalSpacing(0, 0),
                                const VerticalSpacing(16, 8),
                                const VerticalSpacing(0, 0),
                                null,
                              ),
                              h2: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                  height: (_lineSpacing * 0.9).clamp(1.1, 2.5),
                                ),
                                const HorizontalSpacing(0, 0),
                                const VerticalSpacing(12, 6),
                                const VerticalSpacing(0, 0),
                                null,
                              ),
                              h3: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                  height: (_lineSpacing * 0.95).clamp(1.1, 2.5),
                                ),
                                const HorizontalSpacing(0, 0),
                                const VerticalSpacing(8, 4),
                                const VerticalSpacing(0, 0),
                                null,
                              ),
                              lists: DefaultListBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: const Color(0xFF1E293B),
                                  height: _lineSpacing,
                                ),
                                const HorizontalSpacing(0, 0),
                                VerticalSpacing(2, (_lineSpacing - 1.0).clamp(0.0, 6.0) * 2),
                                const VerticalSpacing(0, 0),
                                null,
                                null,
                              ),
                              leading: DefaultTextBlockStyle(
                                TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: const Color(0xFF1E293B),
                                  height: _lineSpacing,
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
                // Custom Toolbar for Rich Text Styling & Line Spacing
                CustomToolbar(
                  controller: _quillController,
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
