import '../models/folder_model.dart';

class FolderUtils {
  /// Returns the breadcrumb list of folders from Root to the target folder
  static List<FolderModel> getFolderPath(
    String? folderId,
    List<FolderModel> allFolders,
  ) {
    if (folderId == null) return [];

    final Map<String, FolderModel> folderMap = {
      for (var f in allFolders) f.id: f
    };

    final List<FolderModel> path = [];
    String? currentId = folderId;
    final Set<String> visited = {}; // Prevent cyclic loops

    while (currentId != null && !visited.contains(currentId)) {
      visited.add(currentId);
      final folder = folderMap[currentId];
      if (folder != null) {
        path.insert(0, folder);
        currentId = folder.parentId;
      } else {
        break;
      }
    }

    return path;
  }

  /// Returns path as string, e.g. "Pekerjaan > Shift Pagi > Laporan Penjualan"
  static String getFolderPathString(
    String? folderId,
    List<FolderModel> allFolders, {
    String separator = ' > ',
    String rootLabel = 'Utama',
  }) {
    final path = getFolderPath(folderId, allFolders);
    if (path.isEmpty) return rootLabel;
    return path.map((f) => f.name).join(separator);
  }

  /// Returns direct subfolders of the given parent (null for root)
  static List<FolderModel> getSubfolders(
    String? parentId,
    List<FolderModel> allFolders,
  ) {
    return allFolders.where((f) => f.parentId == parentId).toList();
  }

  /// Returns all descendant folder IDs (children, grandchildren, etc.)
  static Set<String> getDescendantFolderIds(
    String folderId,
    List<FolderModel> allFolders,
  ) {
    final Set<String> result = {};
    void collect(String pid) {
      for (final f in allFolders) {
        if (f.parentId == pid && !result.contains(f.id)) {
          result.add(f.id);
          collect(f.id);
        }
      }
    }

    collect(folderId);
    return result;
  }

  /// Build a flat list of folders with indentation levels for dropdowns / pickers
  static List<FolderTreeItem> getFolderTreeItems(
    List<FolderModel> allFolders, {
    String? excludeFolderId, // E.g. when picking parent for an existing folder
  }) {
    final Set<String> excludedIds = excludeFolderId != null
        ? {excludeFolderId, ...getDescendantFolderIds(excludeFolderId, allFolders)}
        : {};

    final List<FolderTreeItem> items = [];

    void traverse(String? parentId, int depth) {
      final children = allFolders
          .where((f) => f.parentId == parentId && !excludedIds.contains(f.id))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      for (final child in children) {
        items.add(FolderTreeItem(folder: child, depth: depth));
        traverse(child.id, depth + 1);
      }
    }

    traverse(null, 0);
    return items;
  }

  /// Build hierarchical tree nodes
  static List<FolderTreeNode> buildFolderTree(
    List<FolderModel> allFolders, {
    String? excludeFolderId,
  }) {
    final Set<String> excludedIds = excludeFolderId != null
        ? {excludeFolderId, ...getDescendantFolderIds(excludeFolderId, allFolders)}
        : {};

    List<FolderTreeNode> getChildren(String? parentId, int depth) {
      final subfolders = allFolders
          .where((f) => f.parentId == parentId && !excludedIds.contains(f.id))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return subfolders.map((folder) {
        return FolderTreeNode(
          folder: folder,
          depth: depth,
          children: getChildren(folder.id, depth + 1),
        );
      }).toList();
    }

    return getChildren(null, 0);
  }

  /// Flattens tree nodes into a visible list based on expanded folder IDs
  static List<FolderTreeNode> getVisibleTreeNodes(
    List<FolderTreeNode> rootNodes,
    Set<String> expandedFolderIds,
  ) {
    final List<FolderTreeNode> visible = [];

    void traverse(FolderTreeNode node) {
      visible.add(node);
      if (expandedFolderIds.contains(node.folder.id)) {
        for (final child in node.children) {
          traverse(child);
        }
      }
    }

    for (final rootNode in rootNodes) {
      traverse(rootNode);
    }

    return visible;
  }

  /// Returns all folder IDs that have child subfolders
  static Set<String> getParentFolderIds(List<FolderTreeNode> nodes) {
    final Set<String> result = {};
    void check(FolderTreeNode node) {
      if (node.hasChildren) {
        result.add(node.folder.id);
        for (final child in node.children) {
          check(child);
        }
      }
    }

    for (final node in nodes) {
      check(node);
    }
    return result;
  }

  /// Returns all folder IDs in the tree
  static Set<String> getAllFolderIds(List<FolderTreeNode> nodes) {
    final Set<String> result = {};
    void collect(FolderTreeNode node) {
      result.add(node.folder.id);
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final node in nodes) {
      collect(node);
    }
    return result;
  }
}

class FolderTreeItem {
  final FolderModel folder;
  final int depth;

  FolderTreeItem({required this.folder, required this.depth});
}

class FolderTreeNode {
  final FolderModel folder;
  final int depth;
  final List<FolderTreeNode> children;

  FolderTreeNode({
    required this.folder,
    required this.depth,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;
}
