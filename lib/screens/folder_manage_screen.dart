import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../models/sort_option.dart';
import '../services/storage_service.dart';
import '../utils/folder_utils.dart';
import '../widgets/create_folder_dialog.dart';
import '../widgets/password_dialog.dart';
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

  void _openFolder(String? folderId) async {
    if (folderId != null) {
      final folder = _folders.where((f) => f.id == folderId).firstOrNull;
      if (folder != null && folder.isLocked && folder.password != null && folder.password!.isNotEmpty) {
        final unlocked = await PasswordDialog.showUnlock(
          context,
          title: folder.name,
          itemType: 'Folder',
          correctPassword: folder.password!,
        );
        if (!unlocked || !mounted) return;
      }
    }

    if (!mounted) return;
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

  void _handleLockFolder(FolderModel folder) async {
    final storageService = StorageService();
    if (!folder.isLocked || folder.password == null || folder.password!.isEmpty) {
      final newPass = await PasswordDialog.showSetPassword(
        context,
        title: folder.name,
        itemType: 'Folder',
      );
      if (newPass != null && mounted) {
        final updated = folder.copyWith(
          isLocked: true,
          password: newPass,
        );
        await storageService.updateFolder(updated);
        await _loadData();
        _showToast(
          'Folder "${folder.name}" berhasil dikunci dengan kata sandi',
          icon: Icons.lock_rounded,
          iconColor: const Color(0xFF10B981),
        );
      }
    } else {
      final result = await PasswordDialog.showManagePassword(
        context,
        title: folder.name,
        itemType: 'Folder',
        currentPassword: folder.password!,
      );

      if (result != null && mounted) {
        if (result.action == PasswordManageAction.removed) {
          final updated = folder.copyWith(
            isLocked: false,
            clearPassword: true,
          );
          await storageService.updateFolder(updated);
          await _loadData();
          _showToast(
            'Kunci folder "${folder.name}" berhasil dihapus',
            icon: Icons.lock_open_rounded,
            iconColor: const Color(0xFF10B981),
          );
        } else if (result.action == PasswordManageAction.changed && result.newPassword != null) {
          final updated = folder.copyWith(
            isLocked: true,
            password: result.newPassword,
          );
          await storageService.updateFolder(updated);
          await _loadData();
          _showToast(
            'Kata sandi folder "${folder.name}" berhasil diubah',
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF10B981),
          );
        }
      }
    }
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

  Future<void> _onReorderFolders(
    int oldIndex,
    int newIndex,
    List<FolderTreeNode> visibleNodes,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex || oldIndex >= visibleNodes.length || newIndex >= visibleNodes.length) {
      return;
    }

    final movedNode = visibleNodes[oldIndex];
    final movedFolder = movedNode.folder;

    // Kumpulkan semua subfolder turunannya agar ikut berpindah bersama folder induknya
    final descendantIds =
        FolderUtils.getDescendantFolderIds(movedFolder.id, _folders);
    final idsToMove = {movedFolder.id, ...descendantIds};
    final itemsToMove =
        _folders.where((f) => idsToMove.contains(f.id)).toList();

    setState(() {
      _folders.removeWhere((f) => idsToMove.contains(f.id));

      if (newIndex >= visibleNodes.length - 1) {
        _folders.addAll(itemsToMove);
      } else {
        final targetFolder = visibleNodes[newIndex].folder;
        final targetIdx = _folders.indexWhere((f) => f.id == targetFolder.id);
        if (targetIdx >= 0) {
          if (oldIndex < newIndex) {
            final targetDescendants =
                FolderUtils.getDescendantFolderIds(targetFolder.id, _folders);
            final lastDescendantIdx = targetDescendants.isEmpty
                ? targetIdx
                : _folders.lastIndexWhere((f) => targetDescendants.contains(f.id));
            final insertPos = (lastDescendantIdx >= 0 ? lastDescendantIdx : targetIdx) + 1;
            _folders.insertAll(insertPos.clamp(0, _folders.length), itemsToMove);
          } else {
            _folders.insertAll(targetIdx.clamp(0, _folders.length), itemsToMove);
          }
        } else {
          _folders.addAll(itemsToMove);
        }
      }
    });

    final storageService = StorageService();
    await storageService.saveFolders(_folders);
    await storageService.saveSortOption(SortOption.manual);
    HapticFeedback.selectionClick();

    _showToast(
      'Urutan folder berhasil disimpan (Mode Manual Aktif)',
      icon: Icons.drag_indicator_rounded,
      iconColor: const Color(0xFF6366F1),
      duration: const Duration(milliseconds: 2000),
    );
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

  void _showFolderActionMenu(FolderModel folder) {
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
                // Header dengan nama folder & ikon warna folder
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(folder.colorValue).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: Color(folder.colorValue),
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
                                  folder.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              if (folder.isLocked) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 14,
                                  color: Color(0xFFD97706),
                                ),
                              ],
                              if (folder.isPinned) ...[
                                const SizedBox(width: 6),
                                Transform.rotate(
                                  angle: 0.45,
                                  child: Icon(
                                    Icons.push_pin_rounded,
                                    size: 14,
                                    color: Color(folder.colorValue),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Pilih tindakan untuk folder ini',
                            style: TextStyle(
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
                const SizedBox(height: 10),

                // 1. Kunci / Kelola Sandi
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: folder.isLocked
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      folder.isLocked
                          ? Icons.lock_rounded
                          : Icons.lock_outline_rounded,
                      color: folder.isLocked
                          ? const Color(0xFFD97706)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    folder.isLocked
                        ? 'Kelola Kata Sandi Folder'
                        : 'Kunci Folder dengan Sandi',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    folder.isLocked
                        ? 'Ubah atau hapus proteksi kata sandi'
                        : 'Proteksi catatan di folder dengan kata sandi',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleLockFolder(folder);
                  },
                ),

                // 2. Sematkan / Lepas Sematan
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: folder.isPinned
                          ? Color(folder.colorValue).withValues(alpha: 0.14)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      folder.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: folder.isPinned
                          ? Color(folder.colorValue)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    folder.isPinned ? 'Lepas Sematan' : 'Sematkan Folder',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    folder.isPinned
                        ? 'Kembalikan posisi folder ke urutan biasa'
                        : 'Posisikan folder selalu di urutan teratas',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _togglePin(folder);
                  },
                ),

                // 3. Tambah Subfolder
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.create_new_folder_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Tambah Subfolder',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: const Text(
                    'Buat folder baru di dalam folder ini',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _createNewFolder(parentId: folder.id);
                  },
                ),

                // 4. Hapus Folder
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
                    'Hapus Folder',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  subtitle: const Text(
                    'Hapus folder atau beserta seluruh isinya',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteFolder(folder);
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
                    _showToast(
                      'Folder "${folder.name}" dihapus. Catatan dipindahkan ke Beranda',
                      icon: Icons.delete_outline_rounded,
                      iconColor: const Color(0xFFEF4444),
                    );
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
                    _showToast(
                      'Folder "${folder.name}" dan isinya berhasil dihapus',
                      icon: Icons.delete_forever_rounded,
                      iconColor: const Color(0xFFEF4444),
                    );
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
        backgroundColor: Colors.white,
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
              const SizedBox(height: 8),
              if (_folders.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF4F46E5),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tahan & geser ( ⠿ ) untuk urutan manual. Klik tahan kartu folder untuk opsi lengkap.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF4338CA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: visibleNodes.length,
                  onReorder: (oldIndex, newIndex) =>
                      _onReorderFolders(oldIndex, newIndex, visibleNodes),
                  itemBuilder: (context, index) {
                    final node = visibleNodes[index];
                    final folder = node.folder;
                    final isExpanded = _expandedFolderIds.contains(folder.id);
                    final noteCount = _getDirectNoteCount(folder.id);
                    final subfolderCount = node.children.length;
                    final indentLeft = node.depth * 18.0;

                    return Container(
                      key: ValueKey('folder_${folder.id}'),
                      margin: EdgeInsets.only(bottom: 10, left: indentLeft),
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
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openFolder(folder.id),
                          onLongPress: () => _showFolderActionMenu(folder),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                // Reorder Drag Handle
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 2, right: 6, top: 4, bottom: 4),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      size: 20,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
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
                                        size: 20,
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
                                  const SizedBox(width: 2),
                                Container(
                                  padding: const EdgeInsets.all(8),
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
                                const SizedBox(width: 10),
                                Expanded(
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
                                                fontSize: 14.5,
                                                fontWeight: node.depth == 0
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                          if (folder.isLocked) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.lock_rounded,
                                              size: 13,
                                              color: Color(0xFFD97706),
                                            ),
                                          ],
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
                                              fontSize: 11.5,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                          if (subfolderCount > 0) ...[
                                            const Text(
                                              ' • ',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                '$subfolderCount subfolder${!isExpanded ? ' (ditutup)' : ''}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: !isExpanded
                                                      ? const Color(0xFF4F46E5)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // More actions button (Titik 3)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  splashRadius: 18,
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  tooltip: 'Opsi Folder (Klik tahan kartu)',
                                  onPressed: () => _showFolderActionMenu(folder),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
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
}
