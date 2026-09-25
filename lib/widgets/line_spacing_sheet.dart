import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LineSpacingSheet extends StatefulWidget {
  final double currentSpacing;
  final ValueChanged<double> onSpacingChanged;
  final VoidCallback? onReset;

  const LineSpacingSheet({
    super.key,
    required this.currentSpacing,
    required this.onSpacingChanged,
    this.onReset,
  });

  static Future<void> show({
    required BuildContext context,
    required double currentSpacing,
    required ValueChanged<double> onSpacingChanged,
    VoidCallback? onReset,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => LineSpacingSheet(
        currentSpacing: currentSpacing,
        onSpacingChanged: onSpacingChanged,
        onReset: onReset,
      ),
    );
  }

  @override
  State<LineSpacingSheet> createState() => _LineSpacingSheetState();
}

class _LineSpacingSheetState extends State<LineSpacingSheet> {
  late double _spacing;

  // Preset Spacings
  static const List<Map<String, dynamic>> _presets = [
    {'label': 'Rapat', 'desc': 'Dekat', 'value': 1.25, 'icon': Icons.density_small_rounded},
    {'label': 'Standar', 'desc': 'Normal', 'value': 1.6, 'icon': Icons.density_medium_rounded},
    {'label': 'Renggang', 'desc': 'Jauh', 'value': 2.0, 'icon': Icons.density_large_rounded},
    {'label': 'Lebar', 'desc': 'Sangat Jauh', 'value': 2.4, 'icon': Icons.space_bar_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _spacing = widget.currentSpacing.clamp(1.0, 2.8);
  }

  String _getSpacingDescription(double val) {
    if (val <= 1.35) return 'Rapat / Dekat';
    if (val <= 1.75) return 'Standar / Sedang';
    if (val <= 2.2) return 'Renggang / Jauh';
    return 'Sangat Jauh';
  }

  @override
  Widget build(BuildContext context) {
    final activeDesc = _getSpacingDescription(_spacing);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.format_line_spacing_rounded,
                    color: Color(0xFF4F46E5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jarak Antar Baris',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Sesuaikan kerapatan teks (dekat / jauh)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Current Value Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '${_spacing.toStringAsFixed(2)}x',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Preset Options
            Row(
              children: _presets.map((preset) {
                final double val = preset['value'] as double;
                final bool isSelected = (_spacing - val).abs() < 0.08;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _spacing = val;
                        });
                        widget.onSpacingChanged(_spacing);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              preset['icon'] as IconData,
                              size: 18,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              preset['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              preset['desc'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Live Slider with Min/Max Indicators
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.format_line_spacing_rounded, size: 14, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text(
                            'Dekat (1.0x)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activeDesc,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const Row(
                        children: [
                          Text(
                            'Jauh (2.8x)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.format_line_spacing_rounded, size: 14, color: Color(0xFF64748B)),
                        ],
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF4F46E5),
                      inactiveTrackColor: const Color(0xFFCBD5E1),
                      thumbColor: const Color(0xFF4F46E5),
                      overlayColor: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                    ),
                    child: Slider(
                      value: _spacing,
                      min: 1.0,
                      max: 2.8,
                      divisions: 36,
                      onChanged: (val) {
                        setState(() {
                          _spacing = val;
                        });
                        widget.onSpacingChanged(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Text Preview Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pratinjau Teks (Live Preview)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (widget.onReset != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _spacing = 1.6;
                            });
                            widget.onReset?.call();
                          },
                          child: const Text(
                            'Reset ke Default',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 100),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: _spacing,
                      color: const Color(0xFF1E293B),
                    ),
                    child: const Text(
                      'Ini adalah contoh jarak antar baris catatan Anda.\n'
                      'Teks dapat diatur lebih rapat (dekat) atau renggang (jauh) sesuai kebutuhan.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Selesai Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
