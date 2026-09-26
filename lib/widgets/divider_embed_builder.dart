import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Embed builder for rendering custom horizontal divider lines inside QuillEditor.
class DividerEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'divider';

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    Color color = const Color(0xFFCBD5E1);
    double thickness = 2.0;
    String style = 'solid';

    final data = embedContext.node.value.data;
    if (data is String) {
      if (data.startsWith('{')) {
        try {
          final decoded = json.decode(data);
          if (decoded is Map) {
            if (decoded['color'] != null) {
              color = _parseColor(decoded['color'].toString());
            }
            if (decoded['thickness'] != null) {
              thickness = (decoded['thickness'] as num).toDouble();
            }
            if (decoded['style'] != null) {
              style = decoded['style'].toString();
            }
          }
        } catch (_) {}
      } else {
        color = _parseColor(data);
      }
    } else if (data is Map) {
      if (data['color'] != null) {
        color = _parseColor(data['color'].toString());
      }
      if (data['thickness'] != null) {
        thickness = (data['thickness'] as num).toDouble();
      }
      if (data['style'] != null) {
        style = data['style'].toString();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      alignment: Alignment.center,
      child: _buildDividerWidget(color, thickness, style),
    );
  }

  static Color _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceAll('#', '').trim();
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFCBD5E1);
  }

  Widget _buildDividerWidget(Color color, double thickness, String style) {
    if (style == 'dashed') {
      return SizedBox(
        height: thickness.clamp(1.0, 10.0),
        width: double.infinity,
        child: CustomPaint(
          painter: _DashedLinePainter(
            color: color,
            thickness: thickness,
            dashWidth: 6,
            dashSpace: 4,
          ),
        ),
      );
    } else if (style == 'dotted') {
      return SizedBox(
        height: thickness.clamp(1.0, 10.0),
        width: double.infinity,
        child: CustomPaint(
          painter: _DottedLinePainter(
            color: color,
            dotRadius: thickness / 2,
            spacing: 5,
          ),
        ),
      );
    } else if (style == 'gradient') {
      return Container(
        height: thickness,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(thickness / 2),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.05),
              color,
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      );
    }

    // Default: Solid line
    return Container(
      height: thickness,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(thickness / 2),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double dashWidth;
  final double dashSpace;

  _DashedLinePainter({
    required this.color,
    required this.thickness,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      final endX = (startX + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  _DottedLinePainter({
    required this.color,
    required this.dotRadius,
    this.spacing = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final y = size.height / 2;
    final double step = (dotRadius * 2) + spacing;
    double startX = dotRadius;

    while (startX <= size.width - dotRadius) {
      canvas.drawCircle(Offset(startX, y), dotRadius, paint);
      startX += step;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.spacing != spacing;
  }
}
