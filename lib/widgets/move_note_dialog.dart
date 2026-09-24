import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../utils/folder_utils.dart';
import 'create_folder_dialog.dart';

class MoveNoteDialog extends StatefulWidget {
  final List<FolderModel> folders;
  final String? currentFolderId;
  final Function(FolderModel) onFolderCreated;

  const MoveNoteDialog({
    super.key,
    required this.folders,
    required this.currentFolderId,
    required this.onFolderCreated,
  });

  @override
  State<MoveNoteDialog> createState() => _MoveNoteDialogState();
}

class _MoveNoteDialogState extends State<MoveNoteDialog> {
  late List<FolderModel> _folders;
  late Set<String> _expandedFolderIds;

  @override
  void initState() {
    super.initState();
    _folders = List.from(widget.folders);
    // Closed by default so the list is compact when first opened
    _expandedFolderIds = <String>{};
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

  Future<void> _createNewFolder() async {
    final newFolder = await showDialog<FolderModel>(
      context: context,
      builder: (ctx) => CreateFolderDialog(
        folders: _folders,
        initialParentId: widget.currentFolderId,
      ),
    );
    if (newFolder != null) {
      widget.onFolderCreated(newFolder);
      setState(() {
        _folders.add(newFolder);
        if (newFolder.parentId != null) {
          _expandedFolderIds.add(newFolder.parentId!);
        }
      });
      if (mounted) {
        Navigator.of(context).pop(newFolder.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = FolderUtils.buildFolderTree(_folders);
    final parentIds = FolderUtils.getParentFolderIds(tree);
    final hasNestedFolders = parentIds.isNotEmpty;
    final allExpanded = hasNestedFolders && _expandedFolderIds.length >= parentIds.length;
    final visibleNodes = FolderUtils.getVisibleTreeNodes(tree, _expandedFolderIds);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.drive_file_move_rounded,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pindahkan Catatan Ke',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  if (hasNestedFolders)
                    IconButton(
                      tooltip: allExpanded ? 'Tutup Semua Subfolder' : 'Buka Semua Subfolder',
                      icon: Icon(
                        allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => _toggleExpandAll(tree),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: widget.currentFolderId == null
                          ? const Color(0xFFF1F5F9)
                          : Colors.transparent,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inbox_rounded,
                          color: Color(0xFF475569),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Tanpa Folder (Utama)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      trailing: widget.currentFolderId == null
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop('__UNASSIGNED__'),
                    ),
                    const Divider(
                      height: 12,
                      thickness: 0.8,
                      color: Color(0xFFF1F5F9),
                    ),
                    ...visibleNodes.map((node) {
                      final folder = node.folder;
                      final isSelected = widget.currentFolderId == folder.id;
                      final isExpanded = _expandedFolderIds.contains(folder.id);
                      final indentPadding = node.depth * 18.0;

                      return Padding(
                        padding: EdgeInsets.only(left: indentPadding),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tileColor: isSelected
                              ? Color(folder.colorValue).withValues(alpha: 0.1)
                              : Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
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
                                      size: 20,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                )
                              else if (node.depth > 0)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.subdirectory_arrow_right_rounded,
                                    size: 16,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                )
                              else
                                const SizedBox(width: 28),
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Color(folder.colorValue)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.folder_rounded,
                                  color: Color(folder.colorValue),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  folder.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
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
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+${node.children.length}',
                                    style: const TextStyle(
                                      fontSize: 11,
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
                                  color: Color(folder.colorValue),
                                  size: 20,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(folder.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _createNewFolder,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Buat Folder Baru'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
