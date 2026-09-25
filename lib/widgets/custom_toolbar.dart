import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

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

  void _showFontSizeAndSpacingDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        double currentSpacing = widget.lineSpacing;
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
                            widget.onLineSpacingChanged?.call(val);
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
                            widget.onLineSpacingChanged?.call(val);
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
                            widget.onLineSpacingChanged?.call(val);
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
                            widget.onLineSpacingChanged?.call(val);
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
                                widget.onLineSpacingChanged?.call(val);
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

  @override
  Widget build(BuildContext context) {
    final hasAnyStyleActive = _isBold || _isItalic || _isUnderline;

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
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. GABUNGAN BOLD, ITALIC, UNDERLINE DALAM 1 TOMBOL (KLIK LANGSUNG MUNCUL PILIHAN)
                FormatClickMenuButton(
                  isBold: _isBold,
                  isItalic: _isItalic,
                  isUnderline: _isUnderline,
                  hasAnyActive: hasAnyStyleActive,
                  onBoldSelected: _toggleBold,
                  onItalicSelected: _toggleItalic,
                  onUnderlineSelected: _toggleUnderline,
                ),
                const SizedBox(width: 8),

                _buildDivider(),
                const SizedBox(width: 8),

                // 2. Ukuran Teks & Jarak Baris Picker
                InkWell(
                  onTap: _showFontSizeAndSpacingDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.format_size_rounded,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentSize,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Font Color Picker
                InkWell(
                  onTap: _showColorPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _currentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Warna',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                _buildDivider(),
                const SizedBox(width: 8),

                // 4. Direct Tap Bullets List
                _buildToolbarButton(
                  icon: Icons.format_list_bulleted_rounded,
                  isActive: _isBullet,
                  tooltip: 'Daftar Poin (Bullets)',
                  onTap: _toggleBullet,
                ),
                const SizedBox(width: 4),

                // 5. Direct Tap Numbers List
                _buildToolbarButton(
                  icon: Icons.format_list_numbered_rounded,
                  isActive: _isNumber,
                  tooltip: 'Daftar Angka (Numbers)',
                  onTap: _toggleNumber,
                ),
                const SizedBox(width: 8),

                _buildDivider(),
                const SizedBox(width: 8),

                // 6. Undo Button
                _buildToolbarButton(
                  icon: Icons.undo_rounded,
                  isActive: false,
                  tooltip: 'Batal Perubahan (Undo)',
                  onTap: () => widget.controller.undo(),
                ),
                const SizedBox(width: 4),

                // 7. Redo Button
                _buildToolbarButton(
                  icon: Icons.redo_rounded,
                  isActive: false,
                  tooltip: 'Ulangi (Redo)',
                  onTap: () => widget.controller.redo(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE2E8F0),
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
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
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

/// 1-Button Click Popover Component for Bold, Italic, and Underline
class FormatClickMenuButton extends StatefulWidget {
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool hasAnyActive;
  final VoidCallback onBoldSelected;
  final VoidCallback onItalicSelected;
  final VoidCallback onUnderlineSelected;

  const FormatClickMenuButton({
    super.key,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    required this.hasAnyActive,
    required this.onBoldSelected,
    required this.onItalicSelected,
    required this.onUnderlineSelected,
  });

  @override
  State<FormatClickMenuButton> createState() => _FormatClickMenuButtonState();
}

class _FormatClickMenuButtonState extends State<FormatClickMenuButton> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _togglePopover() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showPopover();
    }
  }

  void _showPopover() {
    _removeOverlay();
    HapticFeedback.lightImpact();

    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final buttonGlobalPos = renderBox.localToGlobal(Offset.zero);

    const menuWidth = 230.0;
    const menuHeight = 78.0;

    final screenWidth = MediaQuery.of(context).size.width;
    final buttonCenterX = buttonGlobalPos.dx + (size.width / 2);
    var menuLeft = buttonCenterX - (menuWidth / 2);
    if (menuLeft < 10) menuLeft = 10;
    if (menuLeft + menuWidth > screenWidth - 10) {
      menuLeft = screenWidth - menuWidth - 10;
    }

    final menuTop = buttonGlobalPos.dy - menuHeight - 10;

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // Fullscreen barrier to close on tap outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _removeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Floating Popover Card
            Positioned(
              left: menuLeft,
              top: menuTop,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: menuWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildOptionCard(
                            label: 'Bold',
                            icon: Icons.format_bold_rounded,
                            isActive: widget.isBold,
                            onTap: () {
                              widget.onBoldSelected();
                              _removeOverlay();
                            },
                          ),
                          _buildOptionCard(
                            label: 'Italic',
                            icon: Icons.format_italic_rounded,
                            isActive: widget.isItalic,
                            onTap: () {
                              widget.onItalicSelected();
                              _removeOverlay();
                            },
                          ),
                          _buildOptionCard(
                            label: 'Underline',
                            icon: Icons.format_underlined_rounded,
                            isActive: widget.isUnderline,
                            onTap: () {
                              widget.onUnderlineSelected();
                              _removeOverlay();
                            },
                          ),
                        ],
                      ),
                    ),
                    // Downward Pointer Arrow
                    CustomPaint(
                      size: const Size(16, 8),
                      painter: _PopoverArrowPainter(
                        color: Colors.white,
                        strokeColor: const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  Widget _buildOptionCard({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
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
              size: 20,
              color: isActive ? Colors.white : const Color(0xFF334155),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
    return Tooltip(
      message: 'Format Teks (Bold, Italic, Underline)',
      child: InkWell(
        key: _buttonKey,
        onTap: _togglePopover,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.hasAnyActive ? const Color(0xFFEEF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.hasAnyActive
                  ? const Color(0xFFC7D2FE)
                  : const Color(0xFFE2E8F0),
              width: widget.hasAnyActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.format_bold_rounded,
                size: 19,
                color: widget.hasAnyActive
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF475569),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: widget.hasAnyActive
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for downward pointer triangle
class _PopoverArrowPainter extends CustomPainter {
  final Color color;
  final Color strokeColor;

  _PopoverArrowPainter({required this.color, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
