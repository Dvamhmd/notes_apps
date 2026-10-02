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
  final String? searchQuery;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isFolderLocked;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;

  const NoteCard({
    super.key,
    required this.note,
    this.folder,
    this.folderPath,
    this.searchQuery,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isFolderLocked = false,
    this.trailing,
    this.margin,
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
      margin: margin ?? const EdgeInsets.only(bottom: 12),
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
                // Header row: Checkbox (in selection mode) / Title & pin badge & trailing
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
                      child: _buildHighlightedText(
                        text: note.title.isEmpty ? 'Tanpa Judul' : note.title,
                        query: searchQuery,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        baseStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        highlightStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF312E81),
                          backgroundColor: Color(0xFFFEF08A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if ((note.isLocked || isFolderLocked) && !isSelectionMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              note.isLocked ? 'Terkunci' : 'Folder Terkunci',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
                if (note.isLocked) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Catatan ini dilindungi kata sandi',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ] else if (isFolderLocked) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: const Color(0xFFD97706).withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Folder catatan terkunci',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ] else if (note.plainText.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildHighlightedText(
                    text: note.plainText.trim(),
                    query: searchQuery,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    baseStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    highlightStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                      backgroundColor: Color(0xFFFEF08A),
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

  static Widget _buildHighlightedText({
    required String text,
    required String? query,
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    if (query == null || query.trim().isEmpty || text.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        style: baseStyle,
      );
    }

    final q = query.trim().toLowerCase();
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final index = lower.indexOf(q, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + q.length),
        style: highlightStyle,
      ));

      start = index + q.length;
    }

    if (spans.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        style: baseStyle,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
