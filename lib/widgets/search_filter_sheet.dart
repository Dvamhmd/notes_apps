import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../models/search_filter_model.dart';

class SearchFilterSheet extends StatefulWidget {
  final SearchFilterConfig initialConfig;
  final FolderModel? currentFolder;
  final ValueChanged<SearchFilterConfig> onApply;

  const SearchFilterSheet({
    super.key,
    required this.initialConfig,
    this.currentFolder,
    required this.onApply,
  });

  static Future<SearchFilterConfig?> show(
    BuildContext context, {
    required SearchFilterConfig currentConfig,
    FolderModel? currentFolder,
    required ValueChanged<SearchFilterConfig> onApply,
  }) {
    return showModalBottomSheet<SearchFilterConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchFilterSheet(
        initialConfig: currentConfig,
        currentFolder: currentFolder,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchTarget _selectedTarget;
  late SearchItemType _selectedItemType;
  late SearchScope _selectedScope;

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.initialConfig.target;
    _selectedItemType = widget.initialConfig.itemType;
    _selectedScope = widget.initialConfig.scope;
  }

  void _resetToDefault() {
    setState(() {
      _selectedTarget = SearchTarget.all;
      _selectedItemType = SearchItemType.all;
      _selectedScope = SearchScope.global;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentFolderName = widget.currentFolder?.name ?? 'Beranda (Folder Utama)';
    final hasChanges = _selectedTarget != SearchTarget.all ||
        _selectedItemType != SearchItemType.all ||
        _selectedScope != SearchScope.global;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
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

              // Title and Reset Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Pencarian',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sesuaikan target, jenis, dan cakupan hasil',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasChanges)
                    TextButton.icon(
                      onPressed: _resetToDefault,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // SECTION 1: Cakupan Pencarian (Scope)
              _buildSectionHeader(
                icon: Icons.travel_explore_rounded,
                title: 'Cakupan Pencarian',
                badge: _selectedScope == SearchScope.global ? 'Menyeluruh' : 'Folder Ini',
              ),
              const SizedBox(height: 10),
              _buildScopeOptions(currentFolderName),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // SECTION 2: Jenis Item (Type)
              _buildSectionHeader(
                icon: Icons.category_rounded,
                title: 'Jenis Item yang Dicari',
                badge: _selectedItemType.shortLabel,
              ),
              const SizedBox(height: 10),
              _buildItemTypeOptions(),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // SECTION 3: Target Pencarian (Target Field)
              _buildSectionHeader(
                icon: Icons.find_in_page_rounded,
                title: 'Cari Berdasarkan',
                badge: _selectedTarget.shortLabel,
              ),
              const SizedBox(height: 10),
              _buildTargetOptions(),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final newConfig = SearchFilterConfig(
                          target: _selectedTarget,
                          itemType: _selectedItemType,
                          scope: _selectedScope,
                        );
                        widget.onApply(newConfig);
                        Navigator.pop(context, newConfig);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Terapkan Filter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String badge,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F46E5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScopeOptions(String currentFolderName) {
    return Column(
      children: [
        _buildRadioOptionCard(
          isSelected: _selectedScope == SearchScope.global,
          icon: SearchScope.global.icon,
          title: SearchScope.global.label,
          subtitle: SearchScope.global.description,
          onTap: () {
            setState(() {
              _selectedScope = SearchScope.global;
            });
          },
        ),
        const SizedBox(height: 8),
        _buildRadioOptionCard(
          isSelected: _selectedScope == SearchScope.currentFolder,
          icon: SearchScope.currentFolder.icon,
          title: 'Hanya Folder: "$currentFolderName"',
          subtitle: 'Hanya mencari catatan & subfolder di dalam folder ini',
          onTap: () {
            setState(() {
              _selectedScope = SearchScope.currentFolder;
            });
          },
        ),
      ],
    );
  }

  Widget _buildItemTypeOptions() {
    return Row(
      children: SearchItemType.values.map((type) {
        final isSelected = _selectedItemType == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedItemType = type;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      type.icon,
                      size: 22,
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type.shortLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetOptions() {
    return Column(
      children: SearchTarget.values.map((target) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildRadioOptionCard(
            isSelected: _selectedTarget == target,
            icon: target.icon,
            title: target.label,
            subtitle: target.description,
            onTap: () {
              setState(() {
                _selectedTarget = target;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadioOptionCard({
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5).withValues(alpha: 0.06)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFFCBD5E1),
                  width: isSelected ? 5.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
