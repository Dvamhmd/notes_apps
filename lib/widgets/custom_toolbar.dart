import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'divider_sheet.dart';

class CustomToolbar extends StatefulWidget {
  final QuillController controller;
  final double lineSpacing;
  final ValueChanged<double>? onLineSpacingChanged;
  final VoidCallback? onOpenLineSpacing;

  const CustomToolbar({
    super.key,
    required this.controller,
    this.lineSpacing = 1.6,
    this.onLineSpacingChanged,
    this.onOpenLineSpacing,
  });

  @override
  State<CustomToolbar> createState() => _CustomToolbarState();
}

class _CustomToolbarState extends State<CustomToolbar> {
  bool _showFormatMenu = false;
  bool _showListMenu = false;
  bool _showHistoryMenu = false;

  final List<Color> _colorPalette = [
    const Color(0xFF0F172A), // Charcoal / Default Black
    const Color(0xFF4F46E5), // Indigo
    const Color(0xFF2563EB), // Blue
    const Color(0xFF0D9488), // Teal
    const Color(0xFF16A34A), // Green
    const Color(0xFFD97706), // Amber
    const Color(0xFFEA580C), // Orange
    const Color(0xFFDC2626), // Red
    const Color(0xFF9333EA), // Purple
    const Color(0xFFDB2777), // Pink
    const Color(0xFF64748B), // Slate Grey
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isBold {
    final style = widget.controller.getSelectionStyle();
    return style.containsKey(Attribute.bold.key);
  }

  bool get _isItalic {
    final style = widget.controller.getSelectionStyle();
    return style.containsKey(Attribute.italic.key);
  }

  bool get _isUnderline {
    final style = widget.controller.getSelectionStyle();
    return style.containsKey(Attribute.underline.key);
  }

  bool get _isBullet {
    final style = widget.controller.getSelectionStyle();
    return style.containsKey(Attribute.ul.key);
  }

  bool get _isNumber {
    final style = widget.controller.getSelectionStyle();
    return style.containsKey(Attribute.ol.key);
  }

  String get _currentSize {
    final style = widget.controller.getSelectionStyle();
    final sizeAttr = style.attributes[Attribute.size.key];
    if (sizeAttr != null && sizeAttr.value != null) {
      return sizeAttr.value.toString();
    }
    // Check header
    final headerAttr = style.attributes[Attribute.header.key];
    if (headerAttr != null) {
      if (headerAttr.value == 1) return 'Judul 1';
      if (headerAttr.value == 2) return 'Judul 2';
      if (headerAttr.value == 3) return 'Judul 3';
    }
    return 'Normal';
  }

  Color get _currentColor {
    final style = widget.controller.getSelectionStyle();
    final colorAttr = style.attributes[Attribute.color.key];
    if (colorAttr != null && colorAttr.value != null) {
      final hexStr = colorAttr.value.toString().replaceAll('#', '');
      try {
        if (hexStr.length == 6) {
          return Color(int.parse('FF$hexStr', radix: 16));
        } else if (hexStr.length == 8) {
          return Color(int.parse(hexStr, radix: 16));
        }
      } catch (_) {}
    }
    return const Color(0xFF0F172A);
  }

  void _toggleBold() {
    widget.controller.formatSelection(
      _isBold ? Attribute.clone(Attribute.bold, null) : Attribute.bold,
    );
  }

  void _toggleItalic() {
    widget.controller.formatSelection(
      _isItalic ? Attribute.clone(Attribute.italic, null) : Attribute.italic,
    );
  }

  void _toggleUnderline() {
    widget.controller.formatSelection(
      _isUnderline
          ? Attribute.clone(Attribute.underline, null)
          : Attribute.underline,
    );
  }

  void _toggleBullet() {
    widget.controller.formatSelection(
      _isBullet ? Attribute.clone(Attribute.ul, null) : Attribute.ul,
    );
  }

  void _toggleNumber() {
    widget.controller.formatSelection(
      _isNumber ? Attribute.clone(Attribute.ol, null) : Attribute.ol,
    );
  }

  double get _currentLineSpacing {
    final style = widget.controller.getSelectionStyle();
    final attr = style.attributes[Attribute.lineHeight.key];
    if (attr != null && attr.value != null) {
      final val = double.tryParse(attr.value.toString());
      if (val != null) return val;
    }
    return widget.lineSpacing;
  }

  void _applyLineSpacing(double val) {
    widget.controller.formatSelection(
      Attribute.clone(Attribute.lineHeight, val),
    );
    widget.onLineSpacingChanged?.call(val);
  }

  void _showFontSizeAndSpacingDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        double currentSpacing = _currentLineSpacing;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final String spacingDesc = currentSpacing <= 1.35
                ? 'Rapat / Dekat'
                : (currentSpacing <= 1.75
                    ? 'Standar'
                    : (currentSpacing <= 2.2
                        ? 'Renggang / Jauh'
                        : 'Sangat Jauh'));

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    // ==========================================
                    // 1. OPSI PENGATURAN LINE SPACING DIATAS UKURAN TEKS
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.format_line_spacing_rounded,
                              size: 20,
                              color: Color(0xFF4F46E5),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Jarak Antar Baris',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFC7D2FE),
                            ),
                          ),
                          child: Text(
                            '${currentSpacing.toStringAsFixed(2)}x ($spacingDesc)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Preset Chips (Rapat, Standar, Renggang, Lebar)
                    Row(
                      children: [
                        _buildSpacingPreset(
                          label: 'Rapat',
                          desc: '1.25x',
                          value: 1.25,
                          current: currentSpacing,
                          onTap: (val) {
                            setSheetState(() => currentSpacing = val);
                            _applyLineSpacing(val);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSpacingPreset(
                          label: 'Standar',
                          desc: '1.60x',
                          value: 1.60,
                          current: currentSpacing,
                          onTap: (val) {
                            setSheetState(() => currentSpacing = val);
                            _applyLineSpacing(val);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSpacingPreset(
                          label: 'Renggang',
                          desc: '2.00x',
                          value: 2.00,
                          current: currentSpacing,
                          onTap: (val) {
                            setSheetState(() => currentSpacing = val);
                            _applyLineSpacing(val);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSpacingPreset(
                          label: 'Lebar',
                          desc: '2.40x',
                          value: 2.40,
                          current: currentSpacing,
                          onTap: (val) {
                            setSheetState(() => currentSpacing = val);
                            _applyLineSpacing(val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Slider Line Spacing
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dekat (1.0x)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                'Jauh (2.8x)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF4F46E5),
                              inactiveTrackColor: const Color(0xFFCBD5E1),
                              thumbColor: const Color(0xFF4F46E5),
                              trackHeight: 3.5,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                            ),
                            child: Slider(
                              value: currentSpacing,
                              min: 1.0,
                              max: 2.8,
                              divisions: 36,
                              onChanged: (val) {
                                setSheetState(() => currentSpacing = val);
                                _applyLineSpacing(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 2. OPSI-OPSI UKURAN TEKS
                    // ==========================================
                    const Row(
                      children: [
                        Icon(
                          Icons.format_size_rounded,
                          size: 20,
                          color: Color(0xFF4F46E5),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ukuran Teks & Gaya',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _buildSizeOption('Kecil (12pt)', '12', () {
                      widget.controller.formatSelection(
                        Attribute.clone(Attribute.size, '12'),
                      );
                      Navigator.pop(ctx);
                    }),
                    _buildSizeOption('Normal (16pt)', 'normal', () {
                      widget.controller.formatSelection(
                        Attribute.clone(Attribute.size, null),
                      );
                      widget.controller.formatSelection(
                        Attribute.clone(Attribute.header, null),
                      );
                      Navigator.pop(ctx);
                    }),
                    _buildSizeOption('Besar (20pt)', '20', () {
                      widget.controller.formatSelection(
                        Attribute.clone(Attribute.size, '20'),
                      );
                      Navigator.pop(ctx);
                    }),
                    _buildSizeOption('Sangat Besar (26pt)', '26', () {
                      widget.controller.formatSelection(
                        Attribute.clone(Attribute.size, '26'),
                      );
                      Navigator.pop(ctx);
                    }),
                    _buildSizeOption('Judul Utama (H1)', 'h1', () {
                      widget.controller.formatSelection(
                        Attribute.clone(Attribute.size, null),
                      );
                      widget.controller.formatSelection(Attribute.h1);
                      Navigator.pop(ctx);
                    }),
                    _buildSizeOption('Sub-Judul (H2)', 'h2', () {
                      widget.controller.formatSelection(
                        Attribute.clone(Attribute.size, null),
                      );
                      widget.controller.formatSelection(Attribute.h2);
                      Navigator.pop(ctx);
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpacingPreset({
    required String label,
    required String desc,
    required double value,
    required double current,
    required ValueChanged<double> onTap,
  }) {
    final isSelected = (current - value).abs() < 0.08;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeOption(String label, String value, VoidCallback onTap) {
    final isSelected = (_currentSize == 'Normal' && value == 'normal') ||
        (_currentSize == '12' && value == '12') ||
        (_currentSize == '20' && value == '20') ||
        (_currentSize == '26' && value == '26') ||
        (_currentSize == 'Judul 1' && value == 'h1') ||
        (_currentSize == 'Judul 2' && value == 'h2');

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF4F46E5))
          : null,
      onTap: onTap,
    );
  }

  void _showColorPicker() {
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
                const Text(
                  'Warna Teks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorPalette.map((color) {
                    final isSelected =
                        _currentColor.toARGB32() == color.toARGB32();
                    final hex =
                        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                    return GestureDetector(
                      onTap: () {
                        if (color.toARGB32() == const Color(0xFF0F172A).toARGB32()) {
                          widget.controller.formatSelection(
                            Attribute.clone(Attribute.color, null),
                          );
                        } else {
                          widget.controller.formatSelection(
                            Attribute.clone(Attribute.color, hex),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _insertDivider(String embedData) {
    final controller = widget.controller;
    final index = controller.selection.baseOffset < 0 ? 0 : controller.selection.baseOffset;
    final length = (controller.selection.extentOffset - index).clamp(0, controller.document.length);
    final plainText = controller.document.toPlainText();

    int insertPos = index;
    if (insertPos > 0 && insertPos <= plainText.length && plainText[insertPos - 1] != '\n') {
      controller.replaceText(insertPos, 0, '\n', TextSelection.collapsed(offset: insertPos + 1));
      insertPos += 1;
    }

    controller.replaceText(
      insertPos,
      length,
      BlockEmbed('divider', embedData),
      TextSelection.collapsed(offset: insertPos + 1),
    );

    final updatedPlain = controller.document.toPlainText();
    if (insertPos + 1 >= updatedPlain.length || updatedPlain[insertPos + 1] != '\n') {
      controller.replaceText(insertPos + 1, 0, '\n', TextSelection.collapsed(offset: insertPos + 2));
      controller.updateSelection(TextSelection.collapsed(offset: insertPos + 2), ChangeSource.local);
    } else {
      controller.updateSelection(TextSelection.collapsed(offset: insertPos + 2), ChangeSource.local);
    }
  }

  void _showDividerSheet() {
    setState(() {
      _showFormatMenu = false;
      _showListMenu = false;
    });
    DividerSheet.show(
      context: context,
      onInsert: _insertDivider,
    );
  }

  Widget _buildFormatFloatingBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Bold',
              icon: Icons.format_bold_rounded,
              isActive: _isBold,
              onTap: _toggleBold,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Italic',
              icon: Icons.format_italic_rounded,
              isActive: _isItalic,
              onTap: _toggleItalic,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Garis Bawah',
              icon: Icons.format_underlined_rounded,
              isActive: _isUnderline,
              onTap: _toggleUnderline,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 30,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Tutup Opsi',
            child: InkWell(
              onTap: () {
                setState(() {
                  _showFormatMenu = false;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListFloatingBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Poin',
              icon: Icons.format_list_bulleted_rounded,
              isActive: _isBullet,
              onTap: _toggleBullet,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Angka',
              icon: Icons.format_list_numbered_rounded,
              isActive: _isNumber,
              onTap: _toggleNumber,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 30,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Tutup Opsi',
            child: InkWell(
              onTap: () {
                setState(() {
                  _showListMenu = false;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryFloatingBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Batal (Undo)',
              icon: Icons.undo_rounded,
              isActive: false,
              onTap: () => widget.controller.undo(),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Ulangi (Redo)',
              icon: Icons.redo_rounded,
              isActive: false,
              onTap: () => widget.controller.redo(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 30,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Tutup Opsi',
            child: InkWell(
              onTap: () {
                setState(() {
                  _showHistoryMenu = false;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 34,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOptionCard({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isActive ? Colors.white : const Color(0xFF334155),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyStyleActive = _isBold || _isItalic || _isUnderline;
    final hasAnyListActive = _isBullet || _isNumber;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sub-bar format floating options
          if (_showFormatMenu) _buildFormatFloatingBar(),
          if (_showListMenu) _buildListFloatingBar(),
          if (_showHistoryMenu) _buildHistoryFloatingBar(),

          // Main toolbar row
          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Format: Bold, Italic, Underline button
                  Tooltip(
                    message: 'Format Teks (Bold, Italic, Garis Bawah)',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showFormatMenu = !_showFormatMenu;
                          if (_showFormatMenu) {
                            _showListMenu = false;
                            _showHistoryMenu = false;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_showFormatMenu || hasAnyStyleActive)
                              ? const Color(0xFFEEF2FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_showFormatMenu || hasAnyStyleActive)
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFFE2E8F0),
                            width: (_showFormatMenu || hasAnyStyleActive) ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.format_bold_rounded,
                              size: 19,
                              color: (_showFormatMenu || hasAnyStyleActive)
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              _showFormatMenu
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: (_showFormatMenu || hasAnyStyleActive)
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Ukuran Teks & Jarak Baris Picker
                  InkWell(
                    onTap: _showFontSizeAndSpacingDialog,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.format_size_rounded,
                            size: 16,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _currentSize,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Font Color Picker
                  InkWell(
                    onTap: _showColorPicker,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _currentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Warna',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Daftar: Bullet & Number List button
                  Tooltip(
                    message: 'Daftar (Poin / Angka)',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showListMenu = !_showListMenu;
                          if (_showListMenu) {
                            _showFormatMenu = false;
                            _showHistoryMenu = false;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_showListMenu || hasAnyListActive)
                              ? const Color(0xFFEEF2FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_showListMenu || hasAnyListActive)
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFFE2E8F0),
                            width: (_showListMenu || hasAnyListActive) ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isNumber
                                  ? Icons.format_list_numbered_rounded
                                  : Icons.format_list_bulleted_rounded,
                              size: 18,
                              color: (_showListMenu || hasAnyListActive)
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _showListMenu
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: (_showListMenu || hasAnyListActive)
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. Garis Pembatas (Divider) Button
                  _buildToolbarButton(
                    icon: Icons.horizontal_rule_rounded,
                    isActive: false,
                    tooltip: 'Garis Pembatas (Divider)',
                    onTap: () {
                      setState(() {
                        _showFormatMenu = false;
                        _showListMenu = false;
                        _showHistoryMenu = false;
                      });
                      _showDividerSheet();
                    },
                  ),

                  // 6. Riwayat (Undo & Redo Gabungan)
                  Tooltip(
                    message: 'Riwayat (Batal / Ulangi)',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showHistoryMenu = !_showHistoryMenu;
                          if (_showHistoryMenu) {
                            _showFormatMenu = false;
                            _showListMenu = false;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                        decoration: BoxDecoration(
                          color: _showHistoryMenu
                              ? const Color(0xFFEEF2FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _showHistoryMenu
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFFE2E8F0),
                            width: _showHistoryMenu ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: _showHistoryMenu
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _showHistoryMenu
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: _showHistoryMenu
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
