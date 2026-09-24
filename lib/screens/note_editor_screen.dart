import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../utils/folder_utils.dart';
import '../widgets/custom_toolbar.dart';
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
  late QuillController _quillController;

  late String? _currentFolderId;
  late bool _isPinned;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _currentFolderId = widget.note.folderId;
    _isPinned = widget.note.isPinned;

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
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
          return;
        }
      }
    } catch (_) {}

    _quillController = QuillController.basic();
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
                if (val == 'move') {
                  _changeFolder();
                } else if (val == 'delete') {
                  _confirmDelete();
                }
              },
              itemBuilder: (ctx) => [
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
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Judul Catatan...',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF94A3B8),
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
                    child: QuillEditor.basic(
                      controller: _quillController,
                    ),
                  ),
                ),
                // Custom Toolbar for Rich Text Styling
                CustomToolbar(controller: _quillController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
