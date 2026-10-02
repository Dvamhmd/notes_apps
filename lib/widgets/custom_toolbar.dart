import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'custom_selection_controls.dart';
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
  bool _showAlignMenu = false;
  bool _showListMenu = false;

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
    final attr = style.attributes[Attribute.ul.key];
    return attr != null && attr.value == Attribute.ul.value;
  }

  bool get _isNumber {
    final style = widget.controller.getSelectionStyle();
    final attr = style.attributes[Attribute.ol.key];
    return attr != null && attr.value == Attribute.ol.value;
  }

  bool get _isAlignCenter {
    final style = widget.controller.getSelectionStyle();
    final attr = style.attributes[Attribute.align.key];
    return attr != null && attr.value == 'center';
  }

  bool get _isAlignRight {
    final style = widget.controller.getSelectionStyle();
    final attr = style.attributes[Attribute.align.key];
    return attr != null && attr.value == 'right';
  }

  bool get _isAlignJustify {
    final style = widget.controller.getSelectionStyle();
    final attr = style.attributes[Attribute.align.key];
    return attr != null && attr.value == 'justify';
  }

  bool get _isAlignLeft {
    final style = widget.controller.getSelectionStyle();
    final attr = style.attributes[Attribute.align.key];
    return attr == null || attr.value == 'left' || attr.value == null;
  }

  IconData get _currentAlignIcon {
    if (_isAlignCenter) return Icons.format_align_center_rounded;
    if (_isAlignRight) return Icons.format_align_right_rounded;
    if (_isAlignJustify) return Icons.format_align_justify_rounded;
    return Icons.format_align_left_rounded;
  }


  double get _currentFontSizeValue {
    final style = widget.controller.getSelectionStyle();
    final sizeAttr = style.attributes[Attribute.size.key];
    if (sizeAttr != null && sizeAttr.value != null) {
      final v = sizeAttr.value.toString().toLowerCase();
      if (v == 'small') return 12.0;
      if (v == 'normal') return 16.0;
      if (v == 'large') return 20.0;
      if (v == 'huge') return 24.0;
      final parsed = double.tryParse(v);
      if (parsed != null && parsed > 0) return parsed;
    }
    final headerAttr = style.attributes[Attribute.header.key];
    if (headerAttr != null) {
      if (headerAttr.value == 1) return 24.0;
      if (headerAttr.value == 2) return 20.0;
      if (headerAttr.value == 3) return 12.0;
    }
    return 16.0;
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
      if (val != null && val > 0) return val.clamp(1.0, 2.8);
    }
    return widget.lineSpacing.clamp(1.0, 2.8);
  }

  void _applyLineSpacing(double val) {
    final clampedVal = double.parse(val.clamp(1.0, 2.8).toStringAsFixed(2));
    final selection = widget.controller.selection;
    if (selection.isCollapsed) {
      final docLength = widget.controller.document.length;
      if (docLength > 0) {
        widget.controller.document.format(
          0,
          docLength,
          Attribute.clone(Attribute.lineHeight, clampedVal),
        );
      }
    } else {
      widget.controller.formatSelection(
        Attribute.clone(Attribute.lineHeight, clampedVal),
      );
    }
    widget.onLineSpacingChanged?.call(clampedVal);
  }

  void _showFontSizeAndSpacingDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final double initialFontSize = _currentFontSizeValue;
    double currentFontSize = initialFontSize;

    CustomTouchTextSelectionControls.showSuppressed(() {
      return showModalBottomSheet(
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

              void applyCustomSize(double size) {
                final clamped = size.clamp(6.0, 96.0);
                FocusManager.instance.primaryFocus?.unfocus();
                SystemChannels.textInput.invokeMethod('TextInput.hide');

                setSheetState(() {
                  currentFontSize = clamped;
                });

                final int rounded = clamped.round();
                final String valStr = (clamped == rounded.toDouble())
                    ? '$rounded'
                    : clamped.toString();

                widget.controller.formatSelection(
                  Attribute.clone(Attribute.header, null),
                );
                widget.controller.formatSelection(
                  Attribute.clone(Attribute.size, valStr),
                );
              }

              void applySpacing(double val) {
                final clamped = double.parse(val.clamp(1.0, 2.8).toStringAsFixed(2));
                setSheetState(() => currentSpacing = clamped);
                _applyLineSpacing(clamped);
              }

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                },
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    ),
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
                          // 1. OPSI PENGATURAN LINE SPACING
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
                                onTap: applySpacing,
                              ),
                              const SizedBox(width: 8),
                              _buildSpacingPreset(
                                label: 'Standar',
                                desc: '1.60x',
                                value: 1.60,
                                current: currentSpacing,
                                onTap: applySpacing,
                              ),
                              const SizedBox(width: 8),
                              _buildSpacingPreset(
                                label: 'Renggang',
                                desc: '2.00x',
                                value: 2.00,
                                current: currentSpacing,
                                onTap: applySpacing,
                              ),
                              const SizedBox(width: 8),
                              _buildSpacingPreset(
                                label: 'Lebar',
                                desc: '2.40x',
                                value: 2.40,
                                current: currentSpacing,
                                onTap: applySpacing,
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
                                    value: currentSpacing.clamp(1.0, 2.8),
                                    min: 1.0,
                                    max: 2.8,
                                    divisions: 36,
                                    onChanged: applySpacing,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE2E8F0), height: 1),
                          const SizedBox(height: 16),

                          // ==========================================
                          // 2. OPSI UKURAN TEKS
                          // ==========================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.format_size_rounded,
                                    size: 20,
                                    color: Color(0xFF4F46E5),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ukuran Teks',
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
                                  '${currentFontSize == currentFontSize.roundToDouble() ? currentFontSize.round() : currentFontSize.toStringAsFixed(1)} pt',
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

                          // --- Atur Manual (Hanya tombol + dan -) ---
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Atur Manual',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Gunakan tombol + / - (6 - 96 pt)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                // Stepper Decrement (-)
                                Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                                      final double newVal = (currentFontSize - 1).clamp(6.0, 96.0);
                                      applyCustomSize(newVal);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.remove_rounded,
                                        size: 18,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Tampilan Nilai Ukuran (Non-editable, tidak mentrigger keyboard)
                                Container(
                                  width: 68,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
                                  ),
                                  child: Text(
                                    '${currentFontSize == currentFontSize.roundToDouble() ? currentFontSize.round() : currentFontSize.toStringAsFixed(1)} pt',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Stepper Increment (+)
                                Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                                      final double newVal = (currentFontSize + 1).clamp(6.0, 96.0);
                                      applyCustomSize(newVal);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // --- Format Gaya Teks: Kecil, Normal, Sedang, Besar ---
                          const Text(
                            'Format Gaya Teks',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildHeadingButton(
                                  label: 'Kecil',
                                  desc: '12 pt',
                                  isActive: (currentFontSize - 12.0).abs() < 1,
                                  onTap: () {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                                    widget.controller.formatSelection(
                                      Attribute.clone(Attribute.header, null),
                                    );
                                    applyCustomSize(12.0);
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildHeadingButton(
                                  label: 'Normal',
                                  desc: '16 pt',
                                  isActive: (currentFontSize - 16.0).abs() < 1,
                                  onTap: () {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                                    widget.controller.formatSelection(
                                      Attribute.clone(Attribute.size, null),
                                    );
                                    widget.controller.formatSelection(
                                      Attribute.clone(Attribute.header, null),
                                    );
                                    applyCustomSize(16.0);
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildHeadingButton(
                                  label: 'Sedang',
                                  desc: '20 pt',
                                  isActive: (currentFontSize - 20.0).abs() < 1,
                                  onTap: () {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                                    widget.controller.formatSelection(
                                      Attribute.clone(Attribute.size, null),
                                    );
                                    widget.controller.formatSelection(Attribute.h2);
                                    applyCustomSize(20.0);
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildHeadingButton(
                                  label: 'Besar',
                                  desc: '24 pt',
                                  isActive: (currentFontSize - 24.0).abs() < 1,
                                  onTap: () {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                                    widget.controller.formatSelection(
                                      Attribute.clone(Attribute.size, null),
                                    );
                                    widget.controller.formatSelection(Attribute.h1);
                                    applyCustomSize(24.0);
                                  },
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
            },
          );
        },
      );
    });
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

  Widget _buildHeadingButton({
    required String label,
    required String desc,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    CustomTouchTextSelectionControls.showSuppressed(() {
      return showModalBottomSheet(
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
    });
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

  Widget _buildAlignFloatingBar() {
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
              label: 'Kiri',
              icon: Icons.format_align_left_rounded,
              isActive: _isAlignLeft,
              onTap: () {
                widget.controller.formatSelection(Attribute.leftAlignment);
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Tengah',
              icon: Icons.format_align_center_rounded,
              isActive: _isAlignCenter,
              onTap: () {
                widget.controller.formatSelection(Attribute.centerAlignment);
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Kanan',
              icon: Icons.format_align_right_rounded,
              isActive: _isAlignRight,
              onTap: () {
                widget.controller.formatSelection(Attribute.rightAlignment);
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFormatOptionCard(
              label: 'Justify',
              icon: Icons.format_align_justify_rounded,
              isActive: _isAlignJustify,
              onTap: () {
                widget.controller.formatSelection(Attribute.justifyAlignment);
              },
            ),
          ),
          const SizedBox(width: 6),
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
                  _showAlignMenu = false;
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

  @override
  Widget build(BuildContext context) {
    final hasAnyStyleActive = _isBold || _isItalic || _isUnderline;
    final hasAnyListActive = _isBullet || _isNumber;
    final hasAnyAlignActive = !_isAlignLeft;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
          // Sub-bar floating options
          if (_showFormatMenu) _buildFormatFloatingBar(),
          if (_showAlignMenu) _buildAlignFloatingBar(),
          if (_showListMenu) _buildListFloatingBar(),

          // Main toolbar row
          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Format Teks: Bold, Italic, Underline button
                  Tooltip(
                    message: 'Format Teks (Bold, Italic, Garis Bawah)',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showFormatMenu = !_showFormatMenu;
                          if (_showFormatMenu) {
                            _showAlignMenu = false;
                            _showListMenu = false;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_showFormatMenu || hasAnyStyleActive)
                              ? const Color(0xFFEEF2FF)
                              : Colors.white,
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
                            const SizedBox(width: 2),
                            Icon(
                              _showFormatMenu
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 15,
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
                  Tooltip(
                    message: 'Ukuran Teks & Jarak Baris',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showFormatMenu = false;
                          _showAlignMenu = false;
                          _showListMenu = false;
                        });
                        _showFontSizeAndSpacingDialog();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.format_size_rounded,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Warna Teks (Color Picker)
                  Tooltip(
                    message: 'Warna Teks',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showFormatMenu = false;
                          _showAlignMenu = false;
                          _showListMenu = false;
                        });
                        _showColorPicker();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: _currentColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. Perataan Teks: Alignment (Kiri, Tengah, Kanan, Justify)
                  Tooltip(
                    message: 'Perataan Teks (Kiri, Tengah, Kanan, Justify)',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showAlignMenu = !_showAlignMenu;
                          if (_showAlignMenu) {
                            _showFormatMenu = false;
                            _showListMenu = false;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_showAlignMenu || hasAnyAlignActive)
                              ? const Color(0xFFEEF2FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_showAlignMenu || hasAnyAlignActive)
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFFE2E8F0),
                            width: (_showAlignMenu || hasAnyAlignActive) ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentAlignIcon,
                              size: 18,
                              color: (_showAlignMenu || hasAnyAlignActive)
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _showAlignMenu
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: (_showAlignMenu || hasAnyAlignActive)
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. Bullets and Numbering (Daftar Poin / Angka)
                  Tooltip(
                    message: 'Daftar (Poin / Angka)',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showListMenu = !_showListMenu;
                          if (_showListMenu) {
                            _showFormatMenu = false;
                            _showAlignMenu = false;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_showListMenu || hasAnyListActive)
                              ? const Color(0xFFEEF2FF)
                              : Colors.white,
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

                  // 6. Garis Pembatas (Divider)
                  _buildToolbarButton(
                    icon: Icons.horizontal_rule_rounded,
                    isActive: false,
                    tooltip: 'Garis Pembatas (Divider)',
                    onTap: () {
                      setState(() {
                        _showFormatMenu = false;
                        _showAlignMenu = false;
                        _showListMenu = false;
                      });
                      _showDividerSheet();
                    },
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
        color: isActive ? const Color(0xFFEEF2FF) : Colors.white,
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
