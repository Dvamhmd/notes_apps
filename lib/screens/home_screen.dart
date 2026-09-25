import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../services/storage_service.dart';
import '../utils/folder_utils.dart';
import '../widgets/create_folder_dialog.dart';
import '../widgets/create_note_dialog.dart';
import '../widgets/move_note_dialog.dart';
import '../widgets/note_card.dart';
import 'folder_manage_screen.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();

  List<NoteModel> _allNotes = [];
  List<FolderModel> _folders = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String? _currentFolderId; // null = Root / Beranda

  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};
  final Set<String> _selectedFolderIds = {};

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _breadcrumbScrollController = ScrollController();

  Object? _draggedItem;
  final ValueNotifier<String?> _activeHoveredFolderId = ValueNotifier<String?>(null);
  final Map<String, GlobalKey> _targetKeys = {};

  int get _totalSelectedCount => _selectedNoteIds.length + _selectedFolderIds.length;

  bool get _isAllSelected {
    final subfolders = _currentSubfolders;
    final notes = _currentNotes;
    if (subfolders.isEmpty && notes.isEmpty) return false;
    final allFoldersSelected = subfolders.isEmpty || subfolders.every((f) => _selectedFolderIds.contains(f.id));
    final allNotesSelected = notes.isEmpty || notes.every((n) => _selectedNoteIds.contains(n.id));
    return allFoldersSelected && allNotesSelected;
  }

  void _enterSelectionModeWithNote(String noteId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedNoteIds.add(noteId);
    });
  }

  void _enterSelectionModeWithFolder(String folderId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedFolderIds.add(folderId);
    });
  }

  void _toggleNoteSelection(String noteId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  void _toggleFolderSelection(String folderId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedFolderIds.contains(folderId)) {
        _selectedFolderIds.remove(folderId);
      } else {
        _selectedFolderIds.add(folderId);
      }
    });
  }

  void _toggleSelectAll() {
    HapticFeedback.selectionClick();
    final subfolders = _currentSubfolders;
    final notes = _currentNotes;
    setState(() {
      if (_isAllSelected) {
        _selectedNoteIds.clear();
        _selectedFolderIds.clear();
      } else {
        _selectedNoteIds.addAll(notes.map((n) => n.id));
        _selectedFolderIds.addAll(subfolders.map((f) => f.id));
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
      _selectedFolderIds.clear();
    });
  }

  GlobalKey _getKeyForTarget(String targetId) {
    return _targetKeys.putIfAbsent(targetId, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _breadcrumbScrollController.dispose();
    _activeHoveredFolderId.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _storageService.initializeDefaultsIfNeeded();
    final notes = await _storageService.getNotes();
    final folders = await _storageService.getFolders();
    if (mounted) {
      setState(() {
        _allNotes = notes;
        _folders = folders;
        _isLoading = false;

        // Verify if current folder still exists
        if (_currentFolderId != null &&
            !_folders.any((f) => f.id == _currentFolderId)) {
          _currentFolderId = null;
        }
      });
      _autoScrollBreadcrumbToEnd();
    }
  }

  void _autoScrollBreadcrumbToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_breadcrumbScrollController.hasClients) {
        _breadcrumbScrollController.animateTo(
          _breadcrumbScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  FolderModel? _getFolderById(String? id) {
    if (id == null) return null;
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  List<FolderModel> get _currentSubfolders {
    return FolderUtils.getSubfolders(_currentFolderId, _folders);
  }

  List<NoteModel> get _currentNotes {
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final list = _allNotes.where((n) {
        final matchTitle = n.title.toLowerCase().contains(q);
        final matchContent = n.plainText.toLowerCase().contains(q);
        return matchTitle || matchContent;
      }).toList();

      list.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    }

    final list = _allNotes
        .where((n) => n.folderId == _currentFolderId)
        .toList();

    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return list;
  }

  bool _isNavigatingForward = true;

  void _navigateToFolder(String? folderId) {
    final oldDepth = _currentFolderId == null
        ? 0
        : FolderUtils.getFolderPath(_currentFolderId, _folders).length;
    final newDepth = folderId == null
        ? 0
        : FolderUtils.getFolderPath(folderId, _folders).length;

    setState(() {
      _isNavigatingForward = newDepth >= oldDepth;
      _currentFolderId = folderId;
      _searchQuery = '';
      _searchController.clear();
    });
    _autoScrollBreadcrumbToEnd();
  }

  void _navigateUp() {
    if (_currentFolderId == null) return;
    final currentFolder = _getFolderById(_currentFolderId);
    _navigateToFolder(currentFolder?.parentId);
  }

  Future<void> _onAddNotePressed() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => CreateNoteDialog(
        folders: _folders,
        initialFolderId: _currentFolderId,
      ),
    );

    if (result != null && mounted) {
      final title = result['title'] as String;
      final folderId = result['folderId'] as String?;

      final newNote = NoteModel(
        id: const Uuid().v4(),
        title: title,
        contentJson: r'[{"insert":"\n"}]',
        plainText: '',
        folderId: folderId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storageService.saveOrUpdateNote(newNote);
      await _loadData();

      if (mounted) {
        _openNoteEditor(newNote);
      }
    }
  }

  void _openNoteEditor(NoteModel note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => NoteEditorScreen(
          note: note,
          folders: _folders,
          onSave: (updated) async {
            await _storageService.saveOrUpdateNote(updated);
            _loadData();
          },
          onDelete: (id) async {
            await _storageService.deleteNote(id);
            _loadData();
          },
          onFolderCreated: (newFolder) async {
            await _storageService.addFolder(newFolder);
            _loadData();
          },
        ),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _showCreateFolderDialog({String? parentId}) async {
    final folder = await showDialog<FolderModel>(
      context: context,
      builder: (ctx) => CreateFolderDialog(
        folders: _folders,
        initialParentId: parentId ?? _currentFolderId,
      ),
    );
    if (folder != null) {
      await _storageService.addFolder(folder);
      await _loadData();
    }
  }

  void _openManageFolders() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => FolderManageScreen(
          folders: _folders,
          notes: _allNotes,
          onAddFolder: (f) async {
            await _storageService.addFolder(f);
            _loadData();
          },
          onDeleteFolder: (id, deleteNotes) async {
            await _storageService.deleteFolder(id, deleteNotes: deleteNotes);
            if (_currentFolderId == id) {
              _currentFolderId = null;
            }
            _loadData();
          },
        ),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _moveNote(NoteModel note) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => MoveNoteDialog(
        folders: _folders,
        currentFolderId: note.folderId,
        onFolderCreated: (f) async {
          await _storageService.addFolder(f);
          _loadData();
        },
      ),
    );

    if (selected != null) {
      final targetFolderId = selected == '__UNASSIGNED__' ? null : selected;
      await _storageService.moveNote(note.id, targetFolderId);
      _loadData();
    }
  }

  Future<void> _deleteNote(String noteId) async {
    await _storageService.deleteNote(noteId);
    _loadData();
  }

  Future<void> _togglePin(NoteModel note) async {
    final updated = note.copyWith(isPinned: !note.isPinned);
    await _storageService.saveOrUpdateNote(updated);
    _loadData();
  }

  void _confirmBatchDelete() {
    final noteCount = _selectedNoteIds.length;
    final folderCount = _selectedFolderIds.length;
    final totalCount = _totalSelectedCount;

    if (totalCount == 0) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Hapus $totalCount Item?',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan menghapus ${[
                if (noteCount > 0) '$noteCount catatan',
                if (folderCount > 0) '$folderCount folder'
              ].join(' dan ')}.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              folderCount > 0
                  ? 'Semua catatan dan subfolder di dalam folder yang dipilih juga akan terhapus secara permanen.'
                  : 'Catatan yang dipilih akan dihapus secara permanen.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final deletedTotal = _totalSelectedCount;

              // Delete selected notes
              for (final noteId in _selectedNoteIds) {
                await _storageService.deleteNote(noteId);
              }

              // Delete selected folders (and child contents)
              for (final folderId in _selectedFolderIds) {
                await _storageService.deleteFolder(folderId, deleteNotes: true);
                if (_currentFolderId == folderId) {
                  _currentFolderId = null;
                }
              }

              _exitSelectionMode();
              await _loadData();
              _showMoveSuccessSnackBar('$deletedTotal item berhasil dihapus.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _showNoteOptions(NoteModel note) {
    final folder = _getFolderById(note.folderId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title.isEmpty ? 'Tanpa Judul' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            folder != null
                                ? 'Folder: ${folder.name}'
                                : 'Folder: Tanpa Folder (Utama)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Option 0: Multi-Select Mode
                _buildBottomSheetActionTile(
                  label: 'Pilih Banyak Item',
                  onTap: () {
                    Navigator.pop(ctx);
                    _enterSelectionModeWithNote(note.id);
                  },
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Option 1: Pin / Unpin
                _buildBottomSheetActionTile(
                  label: note.isPinned
                      ? 'Lepas Sematan (Unpin)'
                      : 'Sematkan Catatan (Pin)',
                  onTap: () {
                    Navigator.pop(ctx);
                    _togglePin(note);
                  },
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Option 2: Rename
                _buildBottomSheetActionTile(
                  label: 'Ganti Judul Catatan',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRenameNoteDialog(note);
                  },
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Option 3: Move
                _buildBottomSheetActionTile(
                  label: 'Pindahkan Folder',
                  onTap: () {
                    Navigator.pop(ctx);
                    _moveNote(note);
                  },
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Option 4: Delete
                _buildBottomSheetActionTile(
                  label: 'Hapus Catatan',
                  textColor: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteNote(note);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFolderOptions(FolderModel folder) {
    final noteCount = _allNotes.where((n) => n.folderId == folder.id).length;
    final subfolderCount =
        _folders.where((f) => f.parentId == folder.id).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(folder.colorValue).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: Color(folder.colorValue),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '$noteCount catatan • $subfolderCount subfolder',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Option 0: Multi-Select Mode
                _buildBottomSheetActionTile(
                  label: 'Pilih Banyak Item',
                  onTap: () {
                    Navigator.pop(ctx);
                    _enterSelectionModeWithFolder(folder.id);
                  },
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Option 1: Rename & Color
                _buildBottomSheetActionTile(
                  label: 'Ganti Nama & Warna Folder',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditFolderDialog(folder);
                  },
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Option 2: Move Folder
                _buildBottomSheetActionTile(
                  label: 'Pindahkan Folder Ini',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMoveFolderDialog(folder);
                  },
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Option 3: Delete Folder
                _buildBottomSheetActionTile(
                  label: 'Hapus Folder',
                  textColor: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteFolder(folder);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetActionTile({
    required String label,
    Color textColor = const Color(0xFF1E293B),
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: Color(0xFFCBD5E1),
      ),
    );
  }

  void _showRenameNoteDialog(NoteModel note) {
    final controller = TextEditingController(text: note.title);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.drive_file_rename_outline_rounded,
              color: Color(0xFF4F46E5),
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Ganti Judul Catatan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Judul Catatan...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.8),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Judul tidak boleh kosong';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                final updated = note.copyWith(
                  title: controller.text.trim(),
                  updatedAt: DateTime.now(),
                );
                _storageService.saveOrUpdateNote(updated);
                _loadData();
                Navigator.pop(ctx);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updated = note.copyWith(
                  title: controller.text.trim(),
                  updatedAt: DateTime.now(),
                );
                _storageService.saveOrUpdateNote(updated);
                _loadData();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNote(NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Catatan Ini?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan "${note.title.isEmpty ? "Tanpa Judul" : note.title}"? Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteNote(note.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditFolderDialog(FolderModel folder) {
    final nameController = TextEditingController(text: folder.name);
    final formKey = GlobalKey<FormState>();
    int selectedColor = folder.colorValue;

    final List<int> palette = [
      0xFF4F46E5, // Indigo
      0xFF3B82F6, // Blue
      0xFF06B6D4, // Cyan
      0xFF10B981, // Emerald
      0xFF84CC16, // Lime
      0xFFF59E0B, // Amber
      0xFFF97316, // Orange
      0xFFEF4444, // Red
      0xFFEC4899, // Pink
      0xFF8B5CF6, // Purple
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Ubah Folder',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nama Folder',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Nama folder...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(selectedColor),
                          width: 1.8,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama folder tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Warna Folder',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: palette.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = c;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Color(c).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final updated = folder.copyWith(
                      name: nameController.text.trim(),
                      colorValue: selectedColor,
                    );
                    await _storageService.updateFolder(updated);
                    await _loadData();
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(selectedColor),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMoveFolderDialog(FolderModel folder) {
    // Closed by default so dialog is compact
    final Set<String> expandedFolderIds = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final currentTree =
              FolderUtils.buildFolderTree(_folders, excludeFolderId: folder.id);
          final parentIds = FolderUtils.getParentFolderIds(currentTree);
          final hasNested = parentIds.isNotEmpty;
          final allExpanded =
              hasNested && expandedFolderIds.length >= parentIds.length;
          final visibleNodes =
              FolderUtils.getVisibleTreeNodes(currentTree, expandedFolderIds);

          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pindahkan Folder "${folder.name}"',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (hasNested)
                  IconButton(
                    tooltip: allExpanded
                        ? 'Tutup Semua Subfolder'
                        : 'Buka Semua Subfolder',
                    icon: Icon(
                      allExpanded
                          ? Icons.unfold_less_rounded
                          : Icons.unfold_more_rounded,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () {
                      setDialogState(() {
                        if (expandedFolderIds.length >= parentIds.length) {
                          expandedFolderIds.clear();
                        } else {
                          expandedFolderIds.addAll(parentIds);
                        }
                      });
                    },
                  ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 340),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: folder.parentId == null
                        ? const Color(0xFFEEF2FF)
                        : Colors.transparent,
                    leading: const Icon(
                      Icons.home_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                    title: const Text(
                      'Folder Utama (Root / Beranda)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    trailing: folder.parentId == null
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF4F46E5),
                            size: 18,
                          )
                        : null,
                    onTap: () async {
                      final updated = folder.copyWith(parentId: null);
                      await _storageService.updateFolder(updated);
                      await _loadData();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  const Divider(height: 10, color: Color(0xFFF1F5F9)),
                  ...visibleNodes.map((node) {
                    final itemFolder = node.folder;
                    final isSelected = folder.parentId == itemFolder.id;
                    final isExpanded = expandedFolderIds.contains(itemFolder.id);
                    final indent = node.depth * 16.0;

                    return Padding(
                      padding: EdgeInsets.only(left: indent),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isSelected
                            ? Color(itemFolder.colorValue).withValues(alpha: 0.12)
                            : Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (node.hasChildren)
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () {
                                  setDialogState(() {
                                    if (expandedFolderIds.contains(itemFolder.id)) {
                                      expandedFolderIds.remove(itemFolder.id);
                                    } else {
                                      expandedFolderIds.add(itemFolder.id);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_right_rounded,
                                    size: 18,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              )
                            else if (node.depth > 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.subdirectory_arrow_right_rounded,
                                  size: 16,
                                  color: Color(0xFFCBD5E1),
                                ),
                              )
                            else
                              const SizedBox(width: 26),
                            Icon(
                              Icons.folder_rounded,
                              size: 18,
                              color: Color(itemFolder.colorValue),
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                itemFolder.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (!isExpanded && node.hasChildren)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${node.children.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: Color(itemFolder.colorValue),
                                size: 18,
                              )
                            : null,
                        onTap: () async {
                          final updated = folder.copyWith(parentId: itemFolder.id);
                          await _storageService.updateFolder(updated);
                          await _loadData();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteFolder(FolderModel folder) {
    final allDescendants =
        FolderUtils.getDescendantFolderIds(folder.id, _folders);
    final allFolderIds = {folder.id, ...allDescendants};
    final totalNotesCount = _allNotes
        .where((n) => n.folderId != null && allFolderIds.contains(n.folderId))
        .length;
    final subfolderCount = allDescendants.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hapus Folder "${folder.name}"?',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subfolderCount > 0
                      ? 'Folder ini memiliki $subfolderCount subfolder dan total $totalNotesCount catatan di dalamnya.'
                      : (totalNotesCount > 0
                          ? 'Folder ini berisi $totalNotesCount catatan.'
                          : 'Folder ini tidak memiliki catatan.'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PILIH CARA PENGHAPUSAN:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // Opsi 1: Hapus Folder Saja (Simpan Catatan ke Beranda)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _storageService.deleteFolder(folder.id, deleteNotes: false);
                    if (_currentFolderId == folder.id || allDescendants.contains(_currentFolderId)) {
                      _currentFolderId = null;
                    }
                    await _loadData();
                    _showMoveSuccessSnackBar('Folder dihapus. Catatan dipindahkan ke Beranda.');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.drive_file_move_rounded,
                            color: Color(0xFF4F46E5),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hapus Folder Saja',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Catatan tetap disimpan dan dipindahkan ke halaman utama (Tanpa Folder).',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Opsi 2: Hapus Semua (Folder & Catatan)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _storageService.deleteFolder(folder.id, deleteNotes: true);
                    if (_currentFolderId == folder.id || allDescendants.contains(_currentFolderId)) {
                      _currentFolderId = null;
                    }
                    await _loadData();
                    _showMoveSuccessSnackBar('Folder dan seluruh isinya berhasil dihapus.');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hapus Semua (Folder & Isinya)',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Folder beserta seluruh catatan dan subfolder di dalamnya akan dihapus permanen.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF991B1B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFolder = _getFolderById(_currentFolderId);
    final breadcrumbPath = FolderUtils.getFolderPath(_currentFolderId, _folders);

    return PopScope(
      canPop: !_isSelectionMode && _currentFolderId == null && _searchQuery.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSelectionMode) {
          _exitSelectionMode();
          return;
        }
        if (_searchQuery.isNotEmpty) {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
          });
          return;
        }
        if (_currentFolderId != null) {
          _navigateUp();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _isSelectionMode
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF1E293B),
                    size: 22,
                  ),
                  tooltip: 'Batal Memilih',
                  onPressed: _exitSelectionMode,
                ),
                title: Text(
                  _totalSelectedCount == 0
                      ? 'Pilih Item'
                      : '$_totalSelectedCount Terpilih',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isAllSelected
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      color: const Color(0xFF4F46E5),
                      size: 22,
                    ),
                    tooltip: _isAllSelected
                        ? 'Batal Pilih Semua'
                        : 'Pilih Semua Item',
                    onPressed: _toggleSelectAll,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: _totalSelectedCount > 0
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFCBD5E1),
                      size: 22,
                    ),
                    tooltip: 'Hapus Item Terpilih',
                    onPressed:
                        _totalSelectedCount > 0 ? _confirmBatchDelete : null,
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
              )
            : AppBar(
                backgroundColor: const Color(0xFFF8FAFC),
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: _currentFolderId != null
                    ? IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: Color(0xFF1E293B),
                        ),
                        tooltip: 'Kembali ke folder sebelumnya',
                        onPressed: _navigateUp,
                      )
                    : null,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentFolder != null
                            ? Color(currentFolder.colorValue)
                            : const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        currentFolder != null
                            ? Icons.folder_rounded
                            : Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentFolder != null ? currentFolder.name : 'Notes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (currentFolder != null)
                            Text(
                              '${_currentNotes.length} catatan • ${_currentSubfolders.length} subfolder',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Three dots popup menu button (Point #3)
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF334155),
                        size: 20,
                      ),
                    ),
                    tooltip: 'Menu Opsi',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (val) {
                      if (val == 'manage_folders') {
                        _openManageFolders();
                      } else if (val == 'create_folder') {
                        _showCreateFolderDialog();
                      } else if (val == 'create_note') {
                        _onAddNotePressed();
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'create_folder',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.create_new_folder_outlined,
                                size: 18,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _currentFolderId != null
                                  ? 'Buat Subfolder'
                                  : 'Buat Folder Baru',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'manage_folders',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.folder_outlined,
                                size: 18,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Kelola Folder',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'create_note',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.note_add_outlined,
                                size: 18,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Catatan Baru',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
              ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4F46E5),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: _currentFolderId != null
                                  ? 'Cari di ${currentFolder?.name ?? "folder"} & semua catatan...'
                                  : 'Cari catatan...',
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Breadcrumbs / Hierarchy Navigator (Point #1 - replaces tab filters)
                      _buildBreadcrumbBar(breadcrumbPath, currentFolder),

                      const SizedBox(height: 8),

                      // Main Content View (Subfolders + Notes with Smooth Transition)
                      Expanded(
                        child: _searchQuery.isNotEmpty
                            ? _buildSearchResultsView()
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                reverseDuration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder: (currentChild, previousChildren) {
                                  return Stack(
                                    alignment: Alignment.topCenter,
                                    children: <Widget>[
                                      ...previousChildren,
                                      ?currentChild,
                                    ],
                                  );
                                },
                                transitionBuilder: (child, animation) {
                                  final isIncoming = child.key ==
                                      ValueKey(_currentFolderId ?? '__ROOT__');

                                  final double beginX = _isNavigatingForward
                                      ? (isIncoming ? 0.06 : -0.06)
                                      : (isIncoming ? -0.06 : 0.06);

                                  final slideAnimation = Tween<Offset>(
                                    begin: Offset(beginX, 0),
                                    end: Offset.zero,
                                  ).animate(animation);

                                  final scaleAnimation = Tween<double>(
                                    begin: isIncoming ? 0.97 : 1.0,
                                    end: isIncoming ? 1.0 : 0.97,
                                  ).animate(animation);

                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: slideAnimation,
                                      child: ScaleTransition(
                                        scale: scaleAnimation,
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey(_currentFolderId ?? '__ROOT__'),
                                  child: _buildFolderContentView(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton.extended(
                onPressed: _onAddNotePressed,
                backgroundColor: currentFolder != null
                    ? Color(currentFolder.colorValue)
                    : const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 4,
                highlightElevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(
                  currentFolder != null ? 'Catatan di Folder Ini' : 'Catatan Baru',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
      ),
    );
  }

  void _showMoveSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  Future<void> _handleNoteDroppedIntoFolder(
    NoteModel note,
    FolderModel targetFolder,
  ) async {
    await _storageService.moveNote(note.id, targetFolder.id);
    await _loadData();
    _showMoveSuccessSnackBar(
      'Catatan "${note.title.isEmpty ? 'Tanpa Judul' : note.title}" dipindahkan ke "${targetFolder.name}"',
    );
  }

  Future<void> _handleFolderDroppedIntoFolder(
    FolderModel draggedFolder,
    FolderModel targetFolder,
  ) async {
    final updated = draggedFolder.copyWith(parentId: targetFolder.id);
    await _storageService.updateFolder(updated);
    await _loadData();
    _showMoveSuccessSnackBar(
      'Folder "${draggedFolder.name}" dipindahkan ke "${targetFolder.name}"',
    );
  }

  bool _isValidDropTarget(String targetId) {
    final dragged = _draggedItem;
    if (dragged == null) return false;

    if (dragged is NoteModel) {
      if (targetId == '__ROOT__') {
        return dragged.folderId != null;
      }
      return dragged.folderId != targetId;
    } else if (dragged is FolderModel) {
      if (targetId == '__ROOT__') {
        return dragged.parentId != null;
      }
      if (dragged.id == targetId) return false;
      if (dragged.parentId == targetId) return false;
      final descendants = FolderUtils.getDescendantFolderIds(
        dragged.id,
        _folders,
      );
      if (descendants.contains(targetId)) return false;
      return true;
    }
    return false;
  }

  void _onDragUpdatePosition(Offset pointerPosition, {required bool isNote}) {
    if (_draggedItem == null) return;

    final double cardWidth = isNote ? 250.0 : 220.0;
    final double cardHeight = 56.0;
    final Offset anchor = Offset(cardWidth / 2, cardHeight / 2);

    final Rect floatingCardRect = Rect.fromLTWH(
      pointerPosition.dx - anchor.dx,
      pointerPosition.dy - anchor.dy,
      cardWidth,
      cardHeight,
    );

    String? bestTargetId;
    double maxOverlapArea = 0.0;

    // 1. Check Root target in Breadcrumb
    if (_isValidDropTarget('__ROOT__')) {
      final key = _targetKeys['__ROOT__'];
      final renderObject = key?.currentContext?.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize && renderObject.attached) {
        final targetRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
        if (floatingCardRect.overlaps(targetRect)) {
          final intersection = floatingCardRect.intersect(targetRect);
          final area = intersection.width * intersection.height;
          if (area > maxOverlapArea) {
            maxOverlapArea = area;
            bestTargetId = '__ROOT__';
          }
        }
      }
    }

    // 2. Check Breadcrumb folder items
    final breadcrumbPath = _currentFolderId == null
        ? <FolderModel>[]
        : FolderUtils.getFolderPath(_currentFolderId, _folders);
    for (final bf in breadcrumbPath) {
      if (_isValidDropTarget(bf.id)) {
        final key = _targetKeys['breadcrumb_${bf.id}'];
        final renderObject = key?.currentContext?.findRenderObject();
        if (renderObject is RenderBox && renderObject.hasSize && renderObject.attached) {
          final targetRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
          if (floatingCardRect.overlaps(targetRect)) {
            final intersection = floatingCardRect.intersect(targetRect);
            final area = intersection.width * intersection.height;
            if (area > maxOverlapArea) {
              maxOverlapArea = area;
              bestTargetId = bf.id;
            }
          }
        }
      }
    }

    // 3. Check Subfolders in current view
    for (final subfolder in _currentSubfolders) {
      if (_isValidDropTarget(subfolder.id)) {
        final key = _targetKeys[subfolder.id];
        final renderObject = key?.currentContext?.findRenderObject();
        if (renderObject is RenderBox && renderObject.hasSize && renderObject.attached) {
          final targetRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
          if (floatingCardRect.overlaps(targetRect)) {
            final intersection = floatingCardRect.intersect(targetRect);
            final area = intersection.width * intersection.height;
            if (area > maxOverlapArea) {
              maxOverlapArea = area;
              bestTargetId = subfolder.id;
            }
          }
        }
      }
    }

    if (_activeHoveredFolderId.value != bestTargetId) {
      _activeHoveredFolderId.value = bestTargetId;
    }
  }

  Future<void> _handleDropOnEnd() async {
    final targetId = _activeHoveredFolderId.value;
    final dragged = _draggedItem;
    _draggedItem = null;
    _activeHoveredFolderId.value = null;

    if (targetId == null || dragged == null) return;

    if (targetId == '__ROOT__') {
      if (dragged is NoteModel) {
        await _storageService.moveNote(dragged.id, null);
        await _loadData();
        _showMoveSuccessSnackBar(
          'Catatan "${dragged.title.isEmpty ? 'Tanpa Judul' : dragged.title}" dipindahkan ke Beranda',
        );
      } else if (dragged is FolderModel) {
        final updated = dragged.copyWith(clearParent: true);
        await _storageService.updateFolder(updated);
        await _loadData();
        _showMoveSuccessSnackBar(
          'Folder "${dragged.name}" dipindahkan ke Beranda',
        );
      }
    } else {
      final targetFolder = _getFolderById(targetId);
      if (targetFolder != null) {
        if (dragged is NoteModel) {
          await _handleNoteDroppedIntoFolder(dragged, targetFolder);
        } else if (dragged is FolderModel) {
          await _handleFolderDroppedIntoFolder(dragged, targetFolder);
        }
      }
    }
  }

  Widget _buildNoteDragFeedback(NoteModel note) {
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: -0.03,
        child: Container(
          width: 250,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Color(0xFF4F46E5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      note.title.isEmpty ? 'Tanpa Judul' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Geser ke folder target...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderDragFeedback(FolderModel folder) {
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: -0.03,
        child: Container(
          width: 220,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color(folder.colorValue),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(folder.colorValue).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Color(folder.colorValue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: Color(folder.colorValue),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pindahkan folder...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(folder.colorValue),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern Breadcrumbs Bar showing folder hierarchy path (e.g. pekerjaan > shift pagi > laporan penjualan)
  Widget _buildBreadcrumbBar(
    List<FolderModel> breadcrumbPath,
    FolderModel? currentFolder,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _breadcrumbScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Root / Beranda item (Drag Target for moving note/folder to root)
            KeyedSubtree(
              key: _getKeyForTarget('__ROOT__'),
              child: ValueListenableBuilder<String?>(
                valueListenable: _activeHoveredFolderId,
                builder: (context, hoveredId, child) {
                  final isHovered = hoveredId == '__ROOT__';
                  return _buildBreadcrumbItem(
                    label: 'Beranda',
                    icon: Icons.home_rounded,
                    isActive: _currentFolderId == null,
                    isDropHovered: isHovered,
                    onTap: () => _navigateToFolder(null),
                    color: const Color(0xFF4F46E5),
                  );
                },
              ),
            ),

            // Nested Folder path items
            for (int i = 0; i < breadcrumbPath.length; i++) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ),
              KeyedSubtree(
                key: _getKeyForTarget('breadcrumb_${breadcrumbPath[i].id}'),
                child: ValueListenableBuilder<String?>(
                  valueListenable: _activeHoveredFolderId,
                  builder: (context, hoveredId, child) {
                    final isHovered = hoveredId == breadcrumbPath[i].id;
                    return _buildBreadcrumbItem(
                      label: breadcrumbPath[i].name,
                      icon: Icons.folder_rounded,
                      isActive: i == breadcrumbPath.length - 1,
                      isDropHovered: isHovered,
                      onTap: () => _navigateToFolder(breadcrumbPath[i].id),
                      color: Color(breadcrumbPath[i].colorValue),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbItem({
    required String label,
    required IconData icon,
    required bool isActive,
    bool isDropHovered = false,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDropHovered
                ? color.withValues(alpha: 0.25)
                : (isActive ? color.withValues(alpha: 0.12) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: isDropHovered
                ? Border.all(color: color, width: 2)
                : (isActive
                    ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                    : null),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDropHovered ? Icons.drive_file_move_rounded : icon,
                size: 15,
                color: isDropHovered || isActive ? color : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isDropHovered || isActive
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isDropHovered || isActive ? color : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Folder Content View with Subfolders grid/list + Notes list
  Widget _buildFolderContentView() {
    final subfolders = _currentSubfolders;
    final notes = _currentNotes;

    if (subfolders.isEmpty && notes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      children: [
        // Subfolders Section (if any exists in current level)
        if (subfolders.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOLDER (${subfolders.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              InkWell(
                onTap: () => _showCreateFolderDialog(),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Color(0xFF4F46E5),
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Subfolder Baru',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSubfoldersGrid(subfolders),
          const SizedBox(height: 20),
        ],

        // Notes Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CATATAN (${notes.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            if (notes.isNotEmpty && _currentFolderId == null)
              const Text(
                'Tanpa Folder (Utama)',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (notes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(
                  Icons.note_alt_outlined,
                  size: 32,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentFolderId != null
                      ? 'Belum ada catatan di dalam folder ini'
                      : 'Belum ada catatan di luar folder',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tekan tombol Catatan di bawah untuk membuat catatan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          )
        else
          ...notes.map((note) {
            final folder = _getFolderById(note.folderId);
            final isSelected = _selectedNoteIds.contains(note.id);

            if (_isSelectionMode) {
              return NoteCard(
                note: note,
                folder: folder,
                isSelectionMode: true,
                isSelected: isSelected,
                onTap: () => _toggleNoteSelection(note.id),
                onLongPress: () => _toggleNoteSelection(note.id),
              );
            }

            return Draggable<Object>(
              data: note,
              dragAnchorStrategy: (draggable, context, point) => const Offset(125, 28),
              feedback: _buildNoteDragFeedback(note),
              onDragStarted: () {
                _draggedItem = note;
              },
              onDragUpdate: (details) {
                _onDragUpdatePosition(details.globalPosition, isNote: true);
              },
              onDragEnd: (details) {
                _handleDropOnEnd();
              },
              onDraggableCanceled: (velocity, offset) {
                _handleDropOnEnd();
              },
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: NoteCard(
                  note: note,
                  folder: folder,
                  onTap: () => _openNoteEditor(note),
                ),
              ),
              child: NoteCard(
                note: note,
                folder: folder,
                onTap: () => _openNoteEditor(note),
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  _showNoteOptions(note);
                },
              ),
            );
          }),
      ],
    );
  }

  /// Modern Grid cards for Subfolders with DragTarget & Draggable
  Widget _buildSubfoldersGrid(List<FolderModel> subfolders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 720
            ? 4
            : (constraints.maxWidth > 480 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 76,
          ),
          itemCount: subfolders.length,
          itemBuilder: (ctx, index) {
            final folder = subfolders[index];
            final noteCount =
                _allNotes.where((n) => n.folderId == folder.id).length;
            final subChildCount =
                _folders.where((f) => f.parentId == folder.id).length;
            final isSelected = _selectedFolderIds.contains(folder.id);

            if (_isSelectionMode) {
              return _buildFolderCardContent(
                folder: folder,
                noteCount: noteCount,
                subChildCount: subChildCount,
                isDropHovered: false,
                isSelectionMode: true,
                isSelected: isSelected,
                onTap: () => _toggleFolderSelection(folder.id),
                onLongPress: () => _toggleFolderSelection(folder.id),
              );
            }

            return KeyedSubtree(
              key: _getKeyForTarget(folder.id),
              child: ValueListenableBuilder<String?>(
                valueListenable: _activeHoveredFolderId,
                builder: (context, hoveredId, child) {
                  final isHovered = hoveredId == folder.id;

                  return Draggable<Object>(
                    data: folder,
                    dragAnchorStrategy: (draggable, context, point) => const Offset(110, 28),
                    feedback: _buildFolderDragFeedback(folder),
                    onDragStarted: () {
                      _draggedItem = folder;
                    },
                    onDragUpdate: (details) {
                      _onDragUpdatePosition(details.globalPosition, isNote: false);
                    },
                    onDragEnd: (details) {
                      _handleDropOnEnd();
                    },
                    onDraggableCanceled: (velocity, offset) {
                      _handleDropOnEnd();
                    },
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _buildFolderCardContent(
                        folder: folder,
                        noteCount: noteCount,
                        subChildCount: subChildCount,
                        isDropHovered: false,
                      ),
                    ),
                    child: _buildFolderCardContent(
                      folder: folder,
                      noteCount: noteCount,
                      subChildCount: subChildCount,
                      isDropHovered: isHovered,
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showFolderOptions(folder);
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFolderCardContent({
    required FolderModel folder,
    required int noteCount,
    required int subChildCount,
    required bool isDropHovered,
    bool isSelectionMode = false,
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final borderColor = isSelectionMode
        ? (isSelected
            ? Color(folder.colorValue)
            : const Color(0xFFE2E8F0))
        : (isDropHovered
            ? Color(folder.colorValue)
            : Color(folder.colorValue).withValues(alpha: 0.25));

    final cardBg = isSelectionMode && isSelected
        ? Color(folder.colorValue).withValues(alpha: 0.08)
        : (isDropHovered
            ? Color(folder.colorValue).withValues(alpha: 0.18)
            : Colors.white);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: isDropHovered
          ? Matrix4.diagonal3Values(1.03, 1.03, 1.0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: (isSelectionMode && isSelected) || isDropHovered ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDropHovered
                ? Color(folder.colorValue).withValues(alpha: 0.2)
                : (isSelectionMode && isSelected
                    ? Color(folder.colorValue).withValues(alpha: 0.12)
                    : const Color(0xFF0F172A).withValues(alpha: 0.02)),
            blurRadius: isDropHovered || (isSelectionMode && isSelected) ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _navigateToFolder(folder.id),
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                if (isSelectionMode) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(folder.colorValue)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Color(folder.colorValue)
                            : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDropHovered
                        ? Color(folder.colorValue)
                        : Color(folder.colorValue).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDropHovered
                        ? Icons.file_download_rounded
                        : Icons.folder_rounded,
                    color: isDropHovered
                        ? Colors.white
                        : Color(folder.colorValue),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDropHovered
                              ? Color(folder.colorValue)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDropHovered
                            ? 'Pindahkan ke sini'
                            : (subChildCount > 0
                                ? '$noteCount note • $subChildCount sub'
                                : '$noteCount catatan'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isDropHovered
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isDropHovered
                              ? Color(folder.colorValue)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSelectionMode)
                  Icon(
                    isDropHovered
                        ? Icons.arrow_downward_rounded
                        : Icons.chevron_right_rounded,
                    size: 16,
                    color: isDropHovered
                        ? Color(folder.colorValue)
                        : const Color(0xFFCBD5E1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Search Results View across all folders
  Widget _buildSearchResultsView() {
    final results = _currentNotes;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Catatan Tidak Ditemukan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tidak ada catatan yang cocok dengan "$_searchQuery".',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      itemCount: results.length,
      itemBuilder: (ctx, index) {
        final note = results[index];
        final folder = _getFolderById(note.folderId);
        final folderPathStr = FolderUtils.getFolderPathString(
          note.folderId,
          _folders,
          separator: ' > ',
          rootLabel: 'Utama',
        );
        final isSelected = _selectedNoteIds.contains(note.id);

        if (_isSelectionMode) {
          return NoteCard(
            note: note,
            folder: folder,
            folderPath: folderPathStr,
            isSelectionMode: true,
            isSelected: isSelected,
            onTap: () => _toggleNoteSelection(note.id),
          );
        }

        return Draggable<Object>(
          data: note,
          dragAnchorStrategy: (draggable, context, point) => const Offset(125, 28),
          feedback: _buildNoteDragFeedback(note),
          onDragStarted: () {
            _draggedItem = note;
          },
          onDragUpdate: (details) {
            _onDragUpdatePosition(details.globalPosition, isNote: true);
          },
          onDragEnd: (details) {
            _handleDropOnEnd();
          },
          onDraggableCanceled: (velocity, offset) {
            _handleDropOnEnd();
          },
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: NoteCard(
              note: note,
              folder: folder,
              folderPath: folderPathStr,
              onTap: () => _openNoteEditor(note),
            ),
          ),
          child: NoteCard(
            note: note,
            folder: folder,
            folderPath: folderPathStr,
            onTap: () => _openNoteEditor(note),
            onLongPress: () => _enterSelectionModeWithNote(note.id),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final currentFolder = _getFolderById(_currentFolderId);
    final themeColor = currentFolder != null
        ? Color(currentFolder.colorValue)
        : const Color(0xFF4F46E5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 52,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _currentFolderId != null
                  ? 'Folder Ini Masih Kosong'
                  : 'Belum Ada Catatan & Folder',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currentFolderId != null
                  ? 'Folder "${currentFolder?.name ?? ''}" belum memiliki catatan atau subfolder.'
                  : 'Mulai buat catatan atau folder baru untuk mengatur ide Anda.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
