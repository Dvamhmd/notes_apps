import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _monthFormat = DateFormat('d MMM', 'id_ID');
  static final DateFormat _yearFormat = DateFormat('d MMM yyyy', 'id_ID');

  final NoteModel note;
  final FolderModel? folder;
  final String? folderPath;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const NoteCard({
    super.key,
    required this.note,
    this.folder,
    this.folderPath,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);

    if (today == noteDate) {
      return 'Hari ini, ${_timeFormat.format(date)}';
    } else if (today.difference(noteDate).inDays == 1) {
      return 'Kemarin, ${_timeFormat.format(date)}';
    } else if (today.year == date.year) {
      return _monthFormat.format(date);
    } else {
      return _yearFormat.format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _buildCardContent(),
    );
  }

  Widget _buildCardContent() {
    final borderColor = isSelectionMode
        ? (isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0))
        : (note.isPinned ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0));

    final cardBgColor = isSelectionMode && isSelected
        ? const Color(0xFFF5F7FF)
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: (isSelectionMode && isSelected) || note.isPinned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelectionMode && isSelected
                ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Checkbox (in selection mode) / Title & pin badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isSelectionMode) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Tanpa Judul' : note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (note.isPinned && !isSelectionMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.push_pin_rounded,
                          size: 15,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ],
                ),
                if (note.plainText.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    note.plainText.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Footer row: Date only (Folder indicator removed)
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(note.updatedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
