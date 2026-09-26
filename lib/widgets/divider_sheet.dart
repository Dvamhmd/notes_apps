import 'dart:convert';
import 'package:flutter/material.dart';

class DividerSheet extends StatefulWidget {
  final Function(String embedData) onInsert;

  const DividerSheet({
    super.key,
    required this.onInsert,
  });

  static Future<void> show({
    required BuildContext context,
    required Function(String embedData) onInsert,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DividerSheet(onInsert: onInsert),
    );
  }

  @override
  State<DividerSheet> createState() => _DividerSheetState();
}

class _DividerSheetState extends State<DividerSheet> {
  Color _selectedColor = const Color(0xFF4F46E5); // Default: Indigo
  double _thickness = 2.5;
  String _style = 'solid'; // 'solid', 'dashed', 'dotted', 'gradient'
  bool _showCustomColorPicker = false;

  // Curated color palette
  static const List<Map<String, dynamic>> _palette = [
    {'name': 'Indigo', 'color': Color(0xFF4F46E5)},
    {'name': 'Biru', 'color': Color(0xFF2563EB)},
    {'name': 'Sian', 'color': Color(0xFF06B6D4)},
    {'name': 'Teal', 'color': Color(0xFF0D9488)},
    {'name': 'Hijau', 'color': Color(0xFF16A34A)},
    {'name': 'Amber', 'color': Color(0xFFF59E0B)},
    {'name': 'Oranye', 'color': Color(0xFFEA580C)},
    {'name': 'Merah', 'color': Color(0xFFEF4444)},
    {'name': 'Ungu', 'color': Color(0xFF9333EA)},
    {'name': 'Pink', 'color': Color(0xFFEC4899)},
    {'name': 'Abu Lembut', 'color': Color(0xFFCBD5E1)},
    {'name': 'Abu Tua', 'color': Color(0xFF64748B)},
    {'name': 'Gelap', 'color': Color(0xFF0F172A)},
  ];

  // Thickness options
  static const List<Map<String, dynamic>> _thicknessOptions = [
    {'label': 'Tipis', 'val': 1.5},
    {'label': 'Standar', 'val': 2.5},
    {'label': 'Tebal', 'val': 4.0},
    {'label': 'Ekstra', 'val': 6.0},
  ];

  // Style options
  static const List<Map<String, dynamic>> _styleOptions = [
    {'id': 'solid', 'label': 'Lurus', 'icon': Icons.horizontal_rule_rounded},
    {'id': 'dashed', 'label': 'Putus-putus', 'icon': Icons.more_horiz_rounded},
    {'id': 'dotted', 'label': 'Titik-titik', 'icon': Icons.grain_rounded},
    {'id': 'gradient', 'label': 'Gradasi', 'icon': Icons.linear_scale_rounded},
  ];

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  void _handleInsert() {
    final hex = _colorToHex(_selectedColor);
    final data = json.encode({
      'color': hex,
      'thickness': _thickness,
      'style': _style,
    });
    widget.onInsert(data);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.horizontal_rule_rounded,
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
                          'Sisipkan Garis Pembatas',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Kustomisasi warna, ketebalan, & gaya garis',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live Preview Box
              _buildLivePreview(),
              const SizedBox(height: 20),

              // Section 1: Pilihan Warna
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilihan Warna',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showCustomColorPicker = !_showCustomColorPicker;
                      });
                    },
                    icon: Icon(
                      _showCustomColorPicker
                          ? Icons.palette_rounded
                          : Icons.tune_rounded,
                      size: 15,
                      color: const Color(0xFF4F46E5),
                    ),
                    label: Text(
                      _showCustomColorPicker ? 'Tutup Kustom' : 'Warna Kustom',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Preset Palette
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _palette.map((item) {
                  final Color c = item['color'] as Color;
                  final String name = item['name'] as String;
                  final bool isSelected = _selectedColor.toARGB32() == c.toARGB32();

                  return Tooltip(
                    message: name,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = c;
                        });
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.withValues(alpha: isSelected ? 0.4 : 0.15),
                              blurRadius: isSelected ? 6 : 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: (c.computeLuminance() > 0.6) ? Colors.black87 : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Custom Color Sliders
              if (_showCustomColorPicker) ...[
                const SizedBox(height: 14),
                _buildCustomColorSliders(),
              ],

              const SizedBox(height: 20),

              // Section 2: Ketebalan Garis
              const Text(
                'Ketebalan Garis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _thicknessOptions.map((opt) {
                  final double val = opt['val'] as double;
                  final String label = opt['label'] as String;
                  final bool isSelected = (_thickness - val).abs() < 0.1;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _thickness = val;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 32,
                                height: val,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                                  borderRadius: BorderRadius.circular(val / 2),
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

              // Section 3: Gaya Garis
              const Text(
                'Gaya Garis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _styleOptions.map((opt) {
                  final String id = opt['id'] as String;
                  final String label = opt['label'] as String;
                  final IconData icon = opt['icon'] as IconData;
                  final bool isSelected = _style == id;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _style = id;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
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

              const SizedBox(height: 24),

              // Insert Button
              ElevatedButton.icon(
                onPressed: _handleInsert,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Sisipkan Garis Pembatas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
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

  Widget _buildLivePreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pratinjau Garis (Live Preview)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  _colorToHex(_selectedColor),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Catatan bagian atas...',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          _renderPreviewDivider(),
          const SizedBox(height: 8),
          const Text(
            'Catatan bagian bawah...',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderPreviewDivider() {
    if (_style == 'dashed') {
      return SizedBox(
        height: _thickness,
        width: double.infinity,
        child: CustomPaint(
          painter: _PreviewDashedPainter(
            color: _selectedColor,
            thickness: _thickness,
          ),
        ),
      );
    } else if (_style == 'dotted') {
      return SizedBox(
        height: _thickness,
        width: double.infinity,
        child: CustomPaint(
          painter: _PreviewDottedPainter(
            color: _selectedColor,
            dotRadius: _thickness / 2,
          ),
        ),
      );
    } else if (_style == 'gradient') {
      return Container(
        height: _thickness,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_thickness / 2),
          gradient: LinearGradient(
            colors: [
              _selectedColor.withValues(alpha: 0.05),
              _selectedColor,
              _selectedColor.withValues(alpha: 0.05),
            ],
          ),
        ),
      );
    }

    return Container(
      height: _thickness,
      decoration: BoxDecoration(
        color: _selectedColor,
        borderRadius: BorderRadius.circular(_thickness / 2),
      ),
    );
  }

  Widget _buildCustomColorSliders() {
    final argb = _selectedColor.toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sesuaikan Warna RGB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildRgbSlider('R', r, const Color(0xFFEF4444), (val) {
            setState(() {
              _selectedColor = Color.fromARGB(255, val.toInt(), g, b);
            });
          }),
          _buildRgbSlider('G', g, const Color(0xFF10B981), (val) {
            setState(() {
              _selectedColor = Color.fromARGB(255, r, val.toInt(), b);
            });
          }),
          _buildRgbSlider('B', b, const Color(0xFF3B82F6), (val) {
            setState(() {
              _selectedColor = Color.fromARGB(255, r, g, val.toInt());
            });
          }),
        ],
      ),
    );
  }

  Widget _buildRgbSlider(
    String label,
    int value,
    Color activeColor,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: activeColor,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: const Color(0xFFCBD5E1),
              thumbColor: activeColor,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewDashedPainter extends CustomPainter {
  final Color color;
  final double thickness;

  _PreviewDashedPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    while (startX < size.width) {
      final endX = (startX + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewDashedPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.thickness != thickness;
  }
}

class _PreviewDottedPainter extends CustomPainter {
  final Color color;
  final double dotRadius;

  _PreviewDottedPainter({required this.color, required this.dotRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final y = size.height / 2;
    const spacing = 5.0;
    final double step = (dotRadius * 2) + spacing;
    double startX = dotRadius;

    while (startX <= size.width - dotRadius) {
      canvas.drawCircle(Offset(startX, y), dotRadius, paint);
      startX += step;
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewDottedPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.dotRadius != dotRadius;
  }
}
