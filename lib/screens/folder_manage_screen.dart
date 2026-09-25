import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../services/storage_service.dart';
import '../utils/folder_utils.dart';
import '../widgets/create_folder_dialog.dart';
import 'home_screen.dart';

class FolderManageScreen extends StatefulWidget {
  final List<FolderModel> folders;
  final List<NoteModel> notes;
  final Function(FolderModel) onAddFolder;
  final Function(String folderId, bool deleteNotes) onDeleteFolder;
  final Function(String? folderId)? onSelectFolder;
  final Function(FolderModel folder)? onTogglePin;

  const FolderManageScreen({
    super.key,
    required this.folders,
    required this.notes,
    required this.onAddFolder,
    required this.onDeleteFolder,
    this.onSelectFolder,
    this.onTogglePin,
  });

  @override
  State<FolderManageScreen> createState() => _FolderManageScreenState();
}

class _FolderManageScreenState extends State<FolderManageScreen> {
  late List<FolderModel> _folders;
  late Set<String> _expandedFolderIds;
  late Map<String?, int> _noteCountMap;

  @override
  void initState() {
    super.initState();
    _folders = List.from(widget.folders);
    // Closed by default so hierarchy is compact
    _expandedFolderIds = <String>{};
    _buildNoteCountMap();
  }

  void _buildNoteCountMap() {
    final map = <String?, int>{};
    for (final n in widget.notes) {
      map[n.folderId] = (map[n.folderId] ?? 0) + 1;
    }
    _noteCountMap = map;
  }

  Future<void> _loadData() async {
    final storageService = StorageService();
    final folders = await storageService.getFolders();
    final notes = await storageService.getNotes();
    if (mounted) {
      setState(() {
        _folders = folders;
        widget.notes.clear();
        widget.notes.addAll(notes);
        _buildNoteCountMap();
      });
    }
  }

  void _openFolder(String? folderId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) => RepaintBoundary(
          child: HomeScreen(
            initialFolderId: folderId,
            isOpenedFromManage: true,
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
    ).then((_) {
      _loadData();
    });
  }

  int _getDirectNoteCount(String? folderId) {
    return _noteCountMap[folderId] ?? 0;
  }

  void _toggleFolder(String folderId) {
    setState(() {
      if (_expandedFolderIds.contains(folderId)) {
        _expandedFolderIds.remove(folderId);
      } else {
        _expandedFolderIds.add(folderId);
      }
    });
  }

  void _toggleExpandAll(List<FolderTreeNode> tree) {
    final parentIds = FolderUtils.getParentFolderIds(tree);
    setState(() {
      if (_expandedFolderIds.length >= parentIds.length && parentIds.isNotEmpty) {
        _expandedFolderIds.clear();
      } else {
        _expandedFolderIds = Set.from(parentIds);
      }
    });
  }

  Future<void> _createNewFolder({String? parentId}) async {
    final newFolder = await showDialog<FolderModel>(
      context: context,
      builder: (ctx) => CreateFolderDialog(
        folders: _folders,
        initialParentId: parentId,
      ),
    );
    if (newFolder != null) {
      widget.onAddFolder(newFolder);
      setState(() {
        _folders.add(newFolder);
        if (newFolder.parentId != null) {
          _expandedFolderIds.add(newFolder.parentId!);
        }
      });
    }
  }

  void _togglePin(FolderModel folder) {
    final updated = folder.copyWith(isPinned: !folder.isPinned);
    setState(() {
      final idx = _folders.indexWhere((f) => f.id == folder.id);
      if (idx >= 0) {
        _folders[idx] = updated;
      }
    });
    widget.onTogglePin?.call(folder);
  }

  void _confirmDeleteFolder(FolderModel folder) {
    final allDescendants =
        FolderUtils.getDescendantFolderIds(folder.id, _folders);
    final allFolderIds = {folder.id, ...allDescendants};
    final totalNotesCount = widget.notes
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
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onDeleteFolder(folder.id, false);
                    setState(() {
                      _folders.removeWhere((f) => allFolderIds.contains(f.id));
                      _expandedFolderIds.removeWhere((id) => allFolderIds.contains(id));
                      for (var i = 0; i < widget.notes.length; i++) {
                        if (widget.notes[i].folderId != null &&
                            allFolderIds.contains(widget.notes[i].folderId)) {
                          widget.notes[i] = widget.notes[i].copyWith(folderId: null);
                        }
                      }
                    });
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
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onDeleteFolder(folder.id, true);
                    setState(() {
                      _folders.removeWhere((f) => allFolderIds.contains(f.id));
                      _expandedFolderIds.removeWhere((id) => allFolderIds.contains(id));
                      widget.notes.removeWhere((n) =>
                          n.folderId != null && allFolderIds.contains(n.folderId));
                    });
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
    final tree = FolderUtils.buildFolderTree(_folders);
    final parentIds = FolderUtils.getParentFolderIds(tree);
    final hasNestedFolders = parentIds.isNotEmpty;
    final allExpanded = hasNestedFolders && _expandedFolderIds.length >= parentIds.length;
    final visibleNodes = FolderUtils.getVisibleTreeNodes(tree, _expandedFolderIds);

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
          'Semua Folder',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (hasNestedFolders)
            IconButton(
              icon: Icon(
                allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                color: const Color(0xFF64748B),
                size: 22,
              ),
              tooltip: allExpanded ? 'Tutup Semua Subfolder' : 'Buka Semua Subfolder',
              onPressed: () => _toggleExpandAll(tree),
            ),
          IconButton(
            icon: const Icon(
              Icons.create_new_folder_rounded,
              color: Color(0xFF4F46E5),
              size: 24,
            ),
            tooltip: 'Tambah Folder Induk',
            onPressed: () => _createNewFolder(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Unassigned Folder item
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openFolder(null),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inbox_rounded,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tanpa Folder (Utama)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${_getDirectNoteCount(null)} catatan',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onSelectFolder != null)
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Color(0xFFCBD5E1),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STRUKTUR & HIRARKI FOLDER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (hasNestedFolders)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _toggleExpandAll(tree),
                      icon: Icon(
                        allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                        size: 16,
                        color: const Color(0xFF4F46E5),
                      ),
                      label: Text(
                        allExpanded ? 'Tutup Semua' : 'Buka Semua',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_folders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  child: const Text(
                    'Belum ada folder kustom.\nTekan (+) untuk membuat folder baru.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                  ),
                )
              else
                ...visibleNodes.map((node) {
                  final folder = node.folder;
                  final isExpanded = _expandedFolderIds.contains(folder.id);
                  final noteCount = _getDirectNoteCount(folder.id);
                  final subfolderCount = node.children.length;
                  final indentLeft = node.depth * 18.0;

                  return Container(
                    margin: EdgeInsets.only(bottom: 10, left: indentLeft),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: folder.isPinned
                            ? Color(folder.colorValue).withValues(alpha: 0.4)
                            : (node.depth > 0
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFFCBD5E1)),
                        width: folder.isPinned ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (node.hasChildren)
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _toggleFolder(folder.id),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_right_rounded,
                                size: 22,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          )
                        else if (node.depth > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 18,
                              color: Color(0xFFCBD5E1),
                            ),
                          )
                        else
                          const SizedBox(width: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openFolder(folder.id),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Color(folder.colorValue).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              color: Color(folder.colorValue),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _openFolder(folder.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          folder.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: node.depth == 0
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      if (folder.isPinned) ...[
                                        const SizedBox(width: 6),
                                        Transform.rotate(
                                          angle: 0.45,
                                          child: Icon(
                                            Icons.push_pin_rounded,
                                            size: 13,
                                            color: Color(folder.colorValue),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '$noteCount catatan',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      if (subfolderCount > 0) ...[
                                        const Text(
                                          ' • ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        Text(
                                          '$subfolderCount subfolder${!isExpanded ? ' (ditutup)' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: !isExpanded
                                                ? const Color(0xFF4F46E5)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Pin / Unpin button
                        IconButton(
                          icon: Icon(
                            folder.isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            color: folder.isPinned
                                ? Color(folder.colorValue)
                                : const Color(0xFF94A3B8),
                            size: 19,
                          ),
                          tooltip: folder.isPinned ? 'Lepas Sematan' : 'Sematkan Folder',
                          onPressed: () => _togglePin(folder),
                        ),
                        // Quick add subfolder button
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: Color(0xFF4F46E5),
                            size: 19,
                          ),
                          tooltip: 'Tambah Subfolder di sini',
                          onPressed: () => _createNewFolder(parentId: folder.id),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 19,
                          ),
                          tooltip: 'Hapus Folder',
                          onPressed: () => _confirmDeleteFolder(folder),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
