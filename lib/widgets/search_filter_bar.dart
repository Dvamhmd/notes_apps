import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../models/search_filter_model.dart';

class SearchFilterChipsBar extends StatelessWidget {
  final SearchFilterConfig config;
  final FolderModel? currentFolder;
  final ValueChanged<SearchFilterConfig> onChanged;
  final VoidCallback onOpenFullFilter;

  const SearchFilterChipsBar({
    super.key,
    required this.config,
    this.currentFolder,
    required this.onChanged,
    required this.onOpenFullFilter,
  });

  @override
  Widget build(BuildContext context) {
    final currentFolderName = currentFolder?.name ?? 'Beranda';
    final hasActiveCustom = !config.isDefault;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          // Filter Button Chip
          InkWell(
            onTap: onOpenFullFilter,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasActiveCustom
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasActiveCustom
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: hasActiveCustom ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasActiveCustom ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  if (hasActiveCustom) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${config.activeFiltersCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 1. Scope Filter Chip with PopupMenu
          PopupMenuButton<SearchScope>(
            tooltip: 'Pilih Cakupan Pencarian',
            onSelected: (scope) {
              onChanged(config.copyWith(scope: scope));
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: SearchScope.global,
                child: Row(
                  children: [
                    Icon(
                      SearchScope.global.icon,
                      size: 18,
                      color: config.scope == SearchScope.global
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        SearchScope.global.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: config.scope == SearchScope.global
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (config.scope == SearchScope.global)
                      const Icon(Icons.check_rounded, size: 16, color: Color(0xFF4F46E5)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SearchScope.currentFolder,
                child: Row(
                  children: [
                    Icon(
                      SearchScope.currentFolder.icon,
                      size: 18,
                      color: config.scope == SearchScope.currentFolder
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Folder Ini ("$currentFolderName")',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: config.scope == SearchScope.currentFolder
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (config.scope == SearchScope.currentFolder)
                      const Icon(Icons.check_rounded, size: 16, color: Color(0xFF4F46E5)),
                  ],
                ),
              ),
            ],
            child: _buildChip(
              isActive: config.scope != SearchScope.global,
              icon: config.scope.icon,
              label: config.scope == SearchScope.global
                  ? 'Semua Folder'
                  : 'Folder: $currentFolderName',
            ),
          ),
          const SizedBox(width: 8),

          // 2. Item Type Filter Chip with PopupMenu
          PopupMenuButton<SearchItemType>(
            tooltip: 'Pilih Jenis Item',
            onSelected: (type) {
              onChanged(config.copyWith(itemType: type));
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (ctx) => SearchItemType.values.map((type) {
              final isSelected = config.itemType == type;
              return PopupMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      type.icon,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_rounded, size: 16, color: Color(0xFF4F46E5)),
                  ],
                ),
              );
            }).toList(),
            child: _buildChip(
              isActive: config.itemType != SearchItemType.all,
              icon: config.itemType.icon,
              label: 'Tipe: ${config.itemType.shortLabel}',
            ),
          ),
          const SizedBox(width: 8),

          // 3. Search Target Field Filter Chip with PopupMenu
          PopupMenuButton<SearchTarget>(
            tooltip: 'Pilih Target Pencarian',
            onSelected: (target) {
              onChanged(config.copyWith(target: target));
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (ctx) => SearchTarget.values.map((target) {
              final isSelected = config.target == target;
              return PopupMenuItem(
                value: target,
                child: Row(
                  children: [
                    Icon(
                      target.icon,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        target.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_rounded, size: 16, color: Color(0xFF4F46E5)),
                  ],
                ),
              );
            }).toList(),
            child: _buildChip(
              isActive: config.target != SearchTarget.all,
              icon: config.target.icon,
              label: 'Cari di: ${config.target.shortLabel}',
            ),
          ),

          // 4. Quick Reset Chip if any filter active
          if (hasActiveCustom) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                onChanged(const SearchFilterConfig());
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Color(0xFFEF4444),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip({
    required bool isActive,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFF4F46E5).withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
          width: isActive ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}
