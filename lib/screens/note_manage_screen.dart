import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../models/sort_option.dart';
import '../services/storage_service.dart';
import '../widgets/create_note_dialog.dart';
import '../widgets/move_note_dialog.dart';
import '../widgets/note_card.dart';
import '../widgets/sort_bottom_sheet.dart';
import 'note_editor_screen.dart';

class NoteManageScreen extends StatefulWidget {
  final List<NoteModel> notes;
  final List<FolderModel> folders;
  final String? initialFolderId;
  final Function(NoteModel)? onNoteSaved;
  final Function(String noteId)? onNoteDeleted;

  const NoteManageScreen({
    super.key,
    required this.notes,
    required this.folders,
    this.initialFolderId,
    this.onNoteSaved,
    this.onNoteDeleted,
  });

  @override
  State<NoteManageScreen> createState() => _NoteManageScreenState();
}

class _NoteManageScreenState extends State<NoteManageScreen> {
  final StorageService _storageService = StorageService();
  late List<NoteModel> _allNotes;
  late List<FolderModel> _folders;
  late Map<String, FolderModel> _folderMap;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  SortOption _sortOption = SortOption.lastAccessed;

  @override
  void initState() {
    super.initState();
    _allNotes = List.from(widget.notes);
    _folders = List.from(widget.folders);
    _buildFolderMap();
    _loadInitialSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _buildFolderMap() {
    _folderMap = {for (final f in _folders) f.id: f};
  }

  Future<void> _loadInitialSettings() async {
    final sort = await _storageService.getSortOption();
    if (mounted) {
      setState(() {
        _sortOption = sort;
      });
    }
  }

  Future<void> _loadData() async {
    final notes = await _storageService.getNotes();
    final folders = await _storageService.getFolders();
    final sort = await _storageService.getSortOption();
    if (mounted) {
      setState(() {
        _allNotes = notes;
        _folders = folders;
        _sortOption = sort;
        _buildFolderMap();
      });
    }
  }

  FolderModel? _getFolderById(String? id) {
    if (id == null) return null;
    return _folderMap[id];
  }

  List<NoteModel> get _filteredAndSortedNotes {
    var result = List<NoteModel>.from(_allNotes);

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((n) {
        final title = n.title.toLowerCase();
        final body = n.plainText.toLowerCase();
        return title.contains(q) || body.contains(q);
      }).toList();
    }

    // 3. Sorting
    switch (_sortOption) {
      case SortOption.manual:
        // Keep order as stored in list, but pinned notes still at the top
        final pinned = result.where((n) => n.isPinned).toList();
        final unpinned = result.where((n) => !n.isPinned).toList();
        return [...pinned, ...unpinned];

      case SortOption.lastAccessed:
        final pinned = result.where((n) => n.isPinned).toList()
          ..sort((a, b) {
            final aTime = a.lastAccessedAt ?? a.updatedAt;
            final bTime = b.lastAccessedAt ?? b.updatedAt;
            return bTime.compareTo(aTime);
          });
        final unpinned = result.where((n) => !n.isPinned).toList()
          ..sort((a, b) {
            final aTime = a.lastAccessedAt ?? a.updatedAt;
            final bTime = b.lastAccessedAt ?? b.updatedAt;
            return bTime.compareTo(aTime);
          });
        return [...pinned, ...unpinned];

      case SortOption.title:
        final pinned = result.where((n) => n.isPinned).toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        final unpinned = result.where((n) => !n.isPinned).toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        return [...pinned, ...unpinned];

      case SortOption.mostAccessed:
        final pinned = result.where((n) => n.isPinned).toList()
          ..sort((a, b) => b.accessCount.compareTo(a.accessCount));
        final unpinned = result.where((n) => !n.isPinned).toList()
          ..sort((a, b) => b.accessCount.compareTo(a.accessCount));
        return [...pinned, ...unpinned];
    }
  }

  void _showToast(
    String message, {
    IconData icon = Icons.check_rounded,
    Color iconColor = const Color(0xFF10B981),
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF1E293B),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        elevation: 6,
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        duration: duration,
      ),
    );
  }

  Future<void> _openNoteEditor(NoteModel note) async {
    _storageService.recordNoteAccess(note.id);
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) => RepaintBoundary(
          child: NoteEditorScreen(
            note: note,
            folders: _folders,
            onSave: (updated) async {
              await _storageService.saveOrUpdateNote(updated);
              widget.onNoteSaved?.call(updated);
              await _loadData();
            },
            onDelete: (id) async {
              await _storageService.deleteNote(id);
              widget.onNoteDeleted?.call(id);
              await _loadData();
              final noteTitle = note.title.isEmpty ? 'Catatan' : 'Catatan "${note.title}"';
              _showToast(
                '$noteTitle berhasil dihapus',
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFEF4444),
              );
            },
            onFolderCreated: (newFolder) async {
              await _storageService.addFolder(newFolder);
              await _loadData();
            },
          ),
        ),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 180),
      ),
    );
    _loadData();
  }

  Future<void> _createNewNote() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => CreateNoteDialog(
        folders: _folders,
        initialFolderId: widget.initialFolderId,
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
      widget.onNoteSaved?.call(newNote);
      await _loadData();

      if (mounted) {
        _openNoteEditor(newNote);
      }
    }
  }

  void _showSortBottomSheet() {
    SortBottomSheet.show(
      context,
      currentSortOption: _sortOption,
      onSelect: (newOption) async {
        setState(() {
          _sortOption = newOption;
        });
        await _storageService.saveSortOption(newOption);
        _showToast(
          'Urutan diubah: ${newOption.label}',
          icon: newOption.icon,
          iconColor: const Color(0xFF4F46E5),
        );
      },
    );
  }

  Future<void> _togglePinNote(NoteModel note) async {
    final updated = note.copyWith(isPinned: !note.isPinned);
    await _storageService.saveOrUpdateNote(updated);
    widget.onNoteSaved?.call(updated);
    await _loadData();
    _showToast(
      updated.isPinned
          ? 'Catatan "${note.title.isEmpty ? 'Tanpa Judul' : note.title}" disematkan ke atas'
          : 'Sematan catatan "${note.title.isEmpty ? 'Tanpa Judul' : note.title}" dilepas',
      icon: updated.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
      iconColor: const Color(0xFF4F46E5),
    );
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

    if (selected != null && mounted) {
      final targetFolderId = (selected == '__NONE__' || selected == '__UNASSIGNED__') ? null : selected;
      await _storageService.moveNote(note.id, targetFolderId);
      await _loadData();

      final targetName = targetFolderId == null
          ? 'Tanpa Folder'
          : (_getFolderById(targetFolderId)?.name ?? 'Folder');
      _showToast(
        'Catatan dipindahkan ke "$targetName"',
        icon: Icons.drive_file_move_rounded,
        iconColor: const Color(0xFF10B981),
      );
    }
  }

  Future<void> _confirmDeleteNote(NoteModel note) async {
    final confirm = await showDialog<bool>(
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
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hapus Catatan?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          'Catatan "${note.title.isEmpty ? 'Tanpa Judul' : note.title}" akan dihapus permanen.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _storageService.deleteNote(note.id);
      widget.onNoteDeleted?.call(note.id);
      await _loadData();
      _showToast(
        'Catatan berhasil dihapus',
        icon: Icons.delete_outline_rounded,
        iconColor: const Color(0xFFEF4444),
      );
    }
  }

  void _showNoteActionMenu(NoteModel note) {
    final folder = _getFolderById(note.folderId);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                const SizedBox(height: 16),
                // Header dengan judul catatan & folder
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: folder != null
                            ? Color(folder.colorValue).withValues(alpha: 0.12)
                            : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: folder != null ? Color(folder.colorValue) : const Color(0xFF4F46E5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  note.title.isEmpty ? 'Tanpa Judul' : note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              if (note.isPinned) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.push_pin_rounded,
                                  size: 14,
                                  color: Color(0xFF4F46E5),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            folder != null ? 'Folder: ${folder.name}' : 'Tanpa Folder',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),

                // 1. Edit / Buka Catatan
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Buka & Edit Catatan',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: const Text(
                    'Edit isi teks atau format catatan ini',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openNoteEditor(note);
                  },
                ),

                // 2. Sematkan / Lepas Sematan
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: note.isPinned
                          ? const Color(0xFFEEF2FF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      note.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: note.isPinned
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    note.isPinned ? 'Lepas Sematan' : 'Sematkan Catatan',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    note.isPinned
                        ? 'Kembalikan posisi catatan ke urutan biasa'
                        : 'Posisikan catatan selalu di urutan teratas',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _togglePinNote(note);
                  },
                ),

                // 3. Pindah Folder
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.drive_file_move_outlined,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Pindahkan ke Folder Lain',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: const Text(
                    'Atur lokasi folder penyimpanan catatan',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _moveNote(note);
                  },
                ),

                // 4. Hapus Catatan
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Hapus Catatan',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  subtitle: const Text(
                    'Hapus catatan ini secara permanen',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteNote(note);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onReorderNotes(int oldIndex, int newIndex, List<NoteModel> visibleList) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex || oldIndex >= visibleList.length || newIndex >= visibleList.length) {
      return;
    }

    final movedNote = visibleList[oldIndex];
    final targetNote = visibleList[newIndex];

    setState(() {
      final realOldIdx = _allNotes.indexWhere((n) => n.id == movedNote.id);
      if (realOldIdx >= 0) {
        _allNotes.removeAt(realOldIdx);
      }
      final realTargetIdx = _allNotes.indexWhere((n) => n.id == targetNote.id);
      if (realTargetIdx >= 0) {
        final insertPos = oldIndex < newIndex ? realTargetIdx + 1 : realTargetIdx;
        _allNotes.insert(insertPos.clamp(0, _allNotes.length), movedNote);
      } else {
        _allNotes.add(movedNote);
      }
      _sortOption = SortOption.manual;
    });

    await _storageService.saveNotes(_allNotes);
    await _storageService.saveSortOption(SortOption.manual);
    HapticFeedback.selectionClick();

    _showToast(
      'Urutan catatan disimpan (Mode Manual Aktif)',
      icon: Icons.drag_indicator_rounded,
      iconColor: const Color(0xFF4F46E5),
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _filteredAndSortedNotes;
    final isManualSort = _sortOption == SortOption.manual;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Semua Catatan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          // Sort Button
          IconButton(
            tooltip: 'Urutkan Catatan: ${_sortOption.label}',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  size: 22,
                  color: _sortOption.isActive ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                ),
                if (_sortOption.isActive)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showSortBottomSheet,
          ),
          // Add Note Button
          IconButton(
            icon: const Icon(
              Icons.note_add_rounded,
              color: Color(0xFF4F46E5),
              size: 24,
            ),
            tooltip: 'Tambah Catatan',
            onPressed: _createNewNote,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _searchQuery.isNotEmpty
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.6)
                          : const Color(0xFFE2E8F0),
                      width: _searchQuery.isNotEmpty ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                            hintText: 'Cari catatan di semua folder...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
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
                      // Filter by sort quick action
                      IconButton(
                        tooltip: 'Opsi Urutan',
                        icon: Icon(
                          _sortOption.icon,
                          size: 20,
                          color: _sortOption.isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                        ),
                        onPressed: _showSortBottomSheet,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),

              // Reorder info badge / sorting header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAFTAR CATATAN (${notes.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    InkWell(
                      onTap: _showSortBottomSheet,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortOption.icon,
                              size: 13,
                              color: const Color(0xFF4F46E5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sortOption.label,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Color(0xFF4F46E5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notes List View
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.note_alt_outlined,
                                  size: 40,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Tidak ada catatan yang sesuai pencarian'
                                    : 'Belum ada catatan',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Coba kata kunci pencarian yang lain'
                                    : 'Tekan tombol (+) untuk membuat catatan baru',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : isManualSort && _searchQuery.isEmpty
                        ? ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 2, 20, 80),
                            buildDefaultDragHandles: false,
                            itemCount: notes.length,
                            onReorder: (oldIdx, newIdx) =>
                                _onReorderNotes(oldIdx, newIdx, notes),
                            itemBuilder: (ctx, index) {
                              final note = notes[index];
                              final folder = _getFolderById(note.folderId);
                              return NoteCard(
                                key: ValueKey(note.id),
                                note: note,
                                folder: folder,
                                margin: const EdgeInsets.only(bottom: 6),
                                trailing: ReorderableDragStartListener(
                                  index: index,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.grab,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFC7D2FE),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.drag_indicator_rounded,
                                            size: 16,
                                            color: Color(0xFF4F46E5),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Urutkan',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () => _openNoteEditor(note),
                                onLongPress: () => _showNoteActionMenu(note),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                            itemCount: notes.length,
                            itemBuilder: (ctx, index) {
                              final note = notes[index];
                              final folder = _getFolderById(note.folderId);
                              return NoteCard(
                                note: note,
                                folder: folder,
                                margin: const EdgeInsets.only(bottom: 10),
                                onTap: () => _openNoteEditor(note),
                                onLongPress: () => _showNoteActionMenu(note),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewNote,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Catatan Baru',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
