import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'line_spacing_sheet.dart';

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

  void _showFontSizeDialog() {
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
                  'Ukuran Teks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
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
  }

  Widget _buildSizeOption(String label, String value, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
      ),
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
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Unified Bold / Italic / Underline Button with Hold-and-Slide Menu
                SlideMenuButton(
                  icon: Icons.format_bold_rounded,
                  label: 'Format Teks (B / I / U)',
                  tooltip: 'Tahan & geser untuk Bold, Italic, atau Underline',
                  isActive: hasAnyStyleActive,
                  items: [
                    SlideMenuItem(
                      id: 'bold',
                      label: 'Bold',
                      icon: Icons.format_bold_rounded,
                      isActive: _isBold,
                      onSelected: _toggleBold,
                    ),
                    SlideMenuItem(
                      id: 'italic',
                      label: 'Italic',
                      icon: Icons.format_italic_rounded,
                      isActive: _isItalic,
                      onSelected: _toggleItalic,
                    ),
                    SlideMenuItem(
                      id: 'underline',
                      label: 'Underline',
                      icon: Icons.format_underlined_rounded,
                      isActive: _isUnderline,
                      onSelected: _toggleUnderline,
                    ),
                  ],
                  onQuickTap: _toggleBold,
                ),
                const SizedBox(width: 8),

                _buildDivider(),
                const SizedBox(width: 8),

                // 2. Font Size Picker
                InkWell(
                  onTap: _showFontSizeDialog,
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

                // 3. Line Spacing Picker (Jarak Antar Baris)
                InkWell(
                  onTap: () {
                    if (widget.onOpenLineSpacing != null) {
                      widget.onOpenLineSpacing!();
                    } else if (widget.onLineSpacingChanged != null) {
                      LineSpacingSheet.show(
                        context: context,
                        currentSpacing: widget.lineSpacing,
                        onSpacingChanged: widget.onLineSpacingChanged!,
                      );
                    }
                  },
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
                          Icons.format_line_spacing_rounded,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.lineSpacing.toStringAsFixed(1)}x',
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

                // 4. Font Color Picker
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

                // 4. Unified List (Bullets & Numbers) with Hold-and-Slide Menu
                SlideMenuButton(
                  icon: _isNumber
                      ? Icons.format_list_numbered_rounded
                      : Icons.format_list_bulleted_rounded,
                  label: 'Daftar (Poin / Angka)',
                  tooltip: 'Tahan & geser untuk Poin atau Angka',
                  isActive: hasAnyListActive,
                  items: [
                    SlideMenuItem(
                      id: 'bullet',
                      label: 'Bullets',
                      icon: Icons.format_list_bulleted_rounded,
                      isActive: _isBullet,
                      onSelected: _toggleBullet,
                    ),
                    SlideMenuItem(
                      id: 'number',
                      label: 'Numbers',
                      icon: Icons.format_list_numbered_rounded,
                      isActive: _isNumber,
                      onSelected: _toggleNumber,
                    ),
                  ],
                  onQuickTap: () {
                    if (_isNumber) {
                      _toggleNumber();
                    } else {
                      _toggleBullet();
                    }
                  },
                ),
                const SizedBox(width: 8),

                _buildDivider(),
                const SizedBox(width: 8),

                // 5. Undo Button
                _buildToolbarButton(
                  icon: Icons.undo_rounded,
                  isActive: false,
                  tooltip: 'Batal Perubahan (Undo)',
                  onTap: () => widget.controller.undo(),
                ),
                const SizedBox(width: 4),

                // 6. Redo Button
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
                color: isActive ? const Color(0xFFC7D2FE) : Colors.transparent,
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

/// Data class representing an option in the SlideMenu
class SlideMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onSelected;

  const SlideMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onSelected,
  });
}

/// Interactive button with Hold-and-Slide Selection Gesture
class SlideMenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool isActive;
  final List<SlideMenuItem> items;
  final VoidCallback onQuickTap;

  const SlideMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.isActive,
    required this.items,
    required this.onQuickTap,
  });

  @override
  State<SlideMenuButton> createState() => _SlideMenuButtonState();
}

class _SlideMenuButtonState extends State<SlideMenuButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  int? _highlightedIndex;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _holdTimer;
  bool _isOverlayOpen = false;

  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _removeOverlay();
    HapticFeedback.mediumImpact();

    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final globalPosition = renderBox.localToGlobal(Offset.zero);

    _highlightedIndex = 0; // Default hover first item or initial
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final itemCount = widget.items.length;
            const itemWidth = 56.0;
            const itemSpacing = 6.0;
            final totalMenuWidth =
                (itemCount * itemWidth) + ((itemCount - 1) * itemSpacing) + 20;

            // Align menu centered above the button
            final buttonCenterX = globalPosition.dx + (size.width / 2);
            var menuLeft = buttonCenterX - (totalMenuWidth / 2);

            // Screen boundaries check
            final screenWidth = MediaQuery.of(context).size.width;
            if (menuLeft < 10) menuLeft = 10;
            if (menuLeft + totalMenuWidth > screenWidth - 10) {
              menuLeft = screenWidth - totalMenuWidth - 10;
            }

            final menuTop = globalPosition.dy - 82;

            return Positioned(
              left: menuLeft,
              top: menuTop,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Floating Tooltip / Instruction Bubble
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.16),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(widget.items.length, (index) {
                              final item = widget.items[index];
                              final isHovered = _highlightedIndex == index;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                margin: EdgeInsets.only(
                                  right: index < widget.items.length - 1
                                      ? itemSpacing
                                      : 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isHovered
                                      ? const Color(0xFF4F46E5)
                                      : (item.isActive
                                          ? const Color(0xFFEEF2FF)
                                          : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isHovered
                                        ? const Color(0xFF4F46E5)
                                        : (item.isActive
                                            ? const Color(0xFFC7D2FE)
                                            : const Color(0xFFE2E8F0)),
                                    width: isHovered ? 2 : 1,
                                  ),
                                  boxShadow: isHovered
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF4F46E5)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: isHovered ? 22 : 20,
                                      color: isHovered
                                          ? Colors.white
                                          : (item.isActive
                                              ? const Color(0xFF4F46E5)
                                              : const Color(0xFF334155)),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isHovered || item.isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isHovered
                                            ? Colors.white
                                            : (item.isActive
                                                ? const Color(0xFF4F46E5)
                                                : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        // Downward Indicator Arrow
                        CustomPaint(
                          size: const Size(14, 7),
                          painter: _ArrowPainter(
                            color: Colors.white,
                            strokeColor: const Color(0xFFCBD5E1),
                          ),
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

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
  }

  void _updateHoveredIndex(Offset globalPosition) {
    if (_overlayEntry == null) return;

    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final buttonGlobalPos = renderBox.localToGlobal(Offset.zero);

    final itemCount = widget.items.length;
    const itemWidth = 56.0;
    const itemSpacing = 6.0;
    final totalMenuWidth =
        (itemCount * itemWidth) + ((itemCount - 1) * itemSpacing) + 20;

    final buttonCenterX = buttonGlobalPos.dx + (size.width / 2);
    var menuLeft = buttonCenterX - (totalMenuWidth / 2);

    final screenWidth = MediaQuery.of(context).size.width;
    if (menuLeft < 10) menuLeft = 10;
    if (menuLeft + totalMenuWidth > screenWidth - 10) {
      menuLeft = screenWidth - totalMenuWidth - 10;
    }

    // Determine hover based on X coordinate
    final relativeX = globalPosition.dx - menuLeft - 10;
    final slotWidth = itemWidth + itemSpacing;
    int calculatedIndex = (relativeX / slotWidth).floor();

    if (calculatedIndex < 0) calculatedIndex = 0;
    if (calculatedIndex >= itemCount) calculatedIndex = itemCount - 1;

    if (_highlightedIndex != calculatedIndex) {
      _highlightedIndex = calculatedIndex;
      HapticFeedback.selectionClick();
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _selectHighlighted() {
    if (_highlightedIndex != null &&
        _highlightedIndex! >= 0 &&
        _highlightedIndex! < widget.items.length) {
      widget.items[_highlightedIndex!].onSelected();
      HapticFeedback.lightImpact();
    }
    _removeOverlay();
  }

  void _removeOverlay() {
    _isOverlayOpen = false;
    if (_overlayEntry != null) {
      _animController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _highlightedIndex = null;
      });
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _holdTimer?.cancel();
    _isOverlayOpen = false;
    // Fast response timer: 150ms instead of standard 500ms
    _holdTimer = Timer(const Duration(milliseconds: 150), () {
      _isOverlayOpen = true;
      _showOverlay();
      _updateHoveredIndex(event.position);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isOverlayOpen) {
      _updateHoveredIndex(event.position);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_holdTimer != null && _holdTimer!.isActive) {
      _holdTimer?.cancel();
      _holdTimer = null;
      widget.onQuickTap();
    } else if (_isOverlayOpen) {
      _selectHighlighted();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _holdTimer?.cancel();
    _holdTimer = null;
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Listener(
        key: _buttonKey,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: Material(
          color: widget.isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isActive
                    ? const Color(0xFFC7D2FE)
                    : const Color(0xFFE2E8F0),
                width: widget.isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 19,
                  color: widget.isActive
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF475569),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 16,
                  color: widget.isActive
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the downward pointer arrow of the overlay menu
class _ArrowPainter extends CustomPainter {
  final Color color;
  final Color strokeColor;

  _ArrowPainter({required this.color, required this.strokeColor});

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
