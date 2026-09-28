import 'package:flutter/material.dart';
import '../models/iq_test_model.dart';

class IqDiagramWidget extends StatelessWidget {
  final DiagramType diagramType;
  final Map<String, dynamic>? diagramData;

  const IqDiagramWidget({
    super.key,
    required this.diagramType,
    this.diagramData,
  });

  @override
  Widget build(BuildContext context) {
    if (diagramType == DiagramType.none) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _buildDiagramContent(context),
      ),
    );
  }

  Widget _buildDiagramContent(BuildContext context) {
    switch (diagramType) {
      case DiagramType.ravenMatrix3x3:
        return _buildMatrix3x3();
      case DiagramType.ravenMatrix2x2:
        return _buildMatrix2x2();
      case DiagramType.shapeSequenceVisual:
        return _buildShapeSequence();
      case DiagramType.gridRotationVisual:
        return _buildGridRotation();
      case DiagramType.scaleBalanceVisual:
        return _buildScaleBalance();
      case DiagramType.diceNetVisual:
        return _buildDiceNet();
      case DiagramType.geometricCountVisual:
        return _buildGeometricPattern();
      case DiagramType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMatrix3x3() {
    final grid = (diagramData?['grid'] as List?) ?? [
      ['4', '7', '11'],
      ['8', '5', '13'],
      ['9', '12', '?'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Matriks Pola Abstrak 3 × 3',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F46E5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            children: grid.map((row) {
              final rowList = row as List;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: rowList.map((val) {
                  final isQuestionMark = val.toString() == '?';
                  return Container(
                    width: 58,
                    height: 48,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isQuestionMark
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isQuestionMark
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFE2E8F0),
                        width: isQuestionMark ? 2.0 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        val.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isQuestionMark ? 20 : 15,
                          fontWeight: FontWeight.w800,
                          color: isQuestionMark
                              ? const Color(0xFFD97706)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrix2x2() {
    final grid = (diagramData?['grid'] as List?) ?? [
      ['A', 'B'],
      ['C', '?'],
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        children: grid.map((row) {
          final rowList = row as List;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: rowList.map((val) {
              final isTarget = val.toString() == '?';
              return Container(
                width: 64,
                height: 54,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isTarget ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTarget ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                    width: isTarget ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    val.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isTarget ? const Color(0xFFD97706) : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShapeSequence() {
    final shapes = [
      {'name': 'Segitiga', 'sides': 3, 'icon': Icons.change_history_rounded},
      {'name': 'Persegi', 'sides': 4, 'icon': Icons.crop_square_rounded},
      {'name': 'Segilima', 'sides': 5, 'icon': Icons.pentagon_outlined},
      {'name': 'Segienam', 'sides': 6, 'icon': Icons.hexagon_outlined},
      {'name': '?', 'sides': '?', 'icon': Icons.help_outline_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: shapes.asMap().entries.map((entry) {
          final index = entry.key;
          final s = entry.value;
          final isTarget = index == shapes.length - 1;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isTarget ? const Color(0xFFFEF3C7) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isTarget
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFCBD5E1),
                    width: isTarget ? 1.8 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      s['icon'] as IconData,
                      size: 30,
                      color: isTarget
                          ? const Color(0xFFD97706)
                          : const Color(0xFF4F46E5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTarget
                            ? const Color(0xFFB45309)
                            : const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      '(${s['sides']} sisi)',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < shapes.length - 1) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                ),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridRotation() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniCompass(
                title: 'Posisi Awal',
                angle: 0,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.sync_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 16),
              _buildMiniRotationCard(
                steps: ['+90° (Searah Jarum)', '-180° (Berlawanan)', '+45° (Searah Jarum)'],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCompass({
    required String title,
    required double angle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 4,
                child: Text(
                  'U',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
              Icon(
                Icons.navigation_rounded,
                size: 24,
                color: Color(0xFF3B82F6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniRotationCard({required List<String> steps}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tahapan Rotasi:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        ...steps.map(
          (step) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_right_rounded,
                  size: 16,
                  color: Color(0xFF4F46E5),
                ),
                Text(
                  step,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiceNet() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.casino_outlined, color: Color(0xFF4F46E5), size: 36),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kaidah Dadu Standar 6 Sisi',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sisi Berhadapan: Jumlah Titik SELALU = 7',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScaleBalance() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.scale_rounded, color: Color(0xFFD97706), size: 28),
              SizedBox(width: 8),
              Text(
                'Keseimbangan Neraca Timbangan:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '2 🍎 Apel  =  1 🥭 Mangga',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '3 🥭 Mangga  =  1 🍈 Melon',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeometricPattern() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.view_in_ar_rounded, color: Color(0xFF4F46E5), size: 36),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kubus Berdimensi 3 × 3 × 3',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Total: 27 unit kubus kecil (1×1×1)',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
