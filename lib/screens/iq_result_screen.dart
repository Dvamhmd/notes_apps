import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../data/iq_questions_data.dart';
import '../models/iq_test_model.dart';
import 'iq_review_screen.dart';
import 'iq_test_screen.dart';

class IqResultScreen extends StatelessWidget {
  final IqTestResult result;
  final List<IqQuestion>? questions;
  final bool isNewTest;

  const IqResultScreen({
    super.key,
    required this.result,
    this.questions,
    this.isNewTest = false,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '$s detik';
    return '$m menit $s detik';
  }

  @override
  Widget build(BuildContext context) {
    final classification = result.classification;
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm').format(result.completedAt);
    final effectiveQuestions = questions ?? IqQuestionsData.getAllQuestionsPool().where((q) => result.userAnswers.containsKey(q.id)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Hasil Evaluasi Tes IQ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score Hero Card
                _buildScoreHeroCard(context, classification),
                const SizedBox(height: 18),

                // Radar Chart / Spider Chart 5 Dimensi Kognitif
                _buildRadarChartCard(),
                const SizedBox(height: 18),

                // Bell Curve / Gauss Distribution Visualization
                _buildBellCurveIndicator(classification),
                const SizedBox(height: 18),

                // Statistik Ringkasan & Kecepatan
                _buildStatsSummaryCard(dateStr),
                const SizedBox(height: 18),

                // Analisis Performa Kategori
                _buildCategoryBreakdownCard(),
                const SizedBox(height: 18),

                // Interpretasi Psikologi & Potensi Diri
                _buildPsychologicalAnalysisCard(classification),
                const SizedBox(height: 24),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () {
                    final qList = effectiveQuestions.isNotEmpty
                        ? effectiveQuestions
                        : IqQuestionsData.getQuestions();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => IqReviewScreen(
                          questions: qList,
                          result: result,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 20),
                  label: const Text('Lihat Pembahasan & Kunci Jawaban'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (ctx) => IqTestScreen(ageGroup: result.ageGroup),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Ulangi Tes IQ (Soal Diacak Baru)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeroCard(
    BuildContext context,
    IqClassification classification,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            classification.color,
            classification.color.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: classification.color.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  classification.rankBadge,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result.ageGroup.shortLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'SKOR ESTIMASI IQ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.iqScore}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            classification.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Persentil: ${classification.percentileText}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFF1F5F9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChartCard() {
    final values = IqCategory.values.map((cat) {
      return (result.categoryPercentages[cat.name] ?? 0.0) / 100.0;
    }).toList();

    final labels = IqCategory.values.map((cat) => cat.shortTitle).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar_rounded, color: Color(0xFF4F46E5), size: 22),
              SizedBox(width: 8),
              Text(
                'Grafik Radar Keseimbangan Otak',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Memetakan profil kekuatan kognitif Anda pada 5 dimensi nalar.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 280,
              height: 240,
              child: CustomPaint(
                painter: _CognitiveRadarPainter(
                  values: values,
                  labels: labels,
                  fillColor: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                  strokeColor: const Color(0xFF4F46E5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBellCurveIndicator(IqClassification classification) {
    final double normalizedPosition =
        ((result.iqScore - 70) / 80.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart_rounded, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text(
                'Posisi Kurva Distribusi Normal (Gauss)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Meter Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final pinOffset = (barWidth - 24) * normalizedPosition;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEF4444), // Rendah
                          Color(0xFFF59E0B), // Low Average
                          Color(0xFF3B82F6), // Rata-rata 100
                          Color(0xFF10B981), // Superior
                          Color(0xFF8B5CF6), // Genius
                        ],
                      ),
                    ),
                  ),
                  // Pointer pin
                  Positioned(
                    left: pinOffset,
                    top: -6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: classification.color, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: classification.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '70\n(Bawah)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
              Text(
                '85\n(Low Avg)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
              Text(
                '100\n(Rata-rata)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '115\n(High Avg)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
              Text(
                '130+\n(Mensa)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummaryCard(String dateStr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                'Ringkasan Akurasi & Waktu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatBox(
                  label: 'Jawaban Benar',
                  value: '${result.correctCount}/${result.totalQuestions}',
                  subvalue: '${result.accuracyPercent.toStringAsFixed(1)}%',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStatBox(
                  label: 'Jawaban Salah',
                  value: '${result.wrongCount}',
                  subvalue: '${result.unansweredCount} kosong',
                  color: const Color(0xFFEF4444),
                  icon: Icons.highlight_off_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStatBox(
                  label: 'Durasi Tes',
                  value: _formatDuration(result.durationSeconds),
                  subvalue: 'Indeks ${result.speedAccuracyIndex.toStringAsFixed(0)}/100',
                  color: const Color(0xFF3B82F6),
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatBox({
    required String label,
    required String value,
    required String subvalue,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          Text(
            subvalue,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text(
                'Performa Per Kategori Kognitif',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...IqCategory.values.map((cat) {
            final percent = result.categoryPercentages[cat.name] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 8),
                          Text(
                            cat.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cat.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent / 100.0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPsychologicalAnalysisCard(IqClassification classification) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_alt_rounded, color: Color(0xFF4F46E5), size: 22),
              SizedBox(width: 8),
              Text(
                'Analisis Kognitif & Rekomendasi Potensi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF312E81),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            classification.description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _CognitiveRadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color fillColor;
  final Color strokeColor;

  _CognitiveRadarPainter({
    required this.values,
    required this.labels,
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = values.length;
    if (count < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 32;

    final gridPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dataFillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final dataStrokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Gambar grid cincin konsentris (25%, 50%, 75%, 100%)
    for (int step = 1; step <= 4; step++) {
      final r = radius * (step / 4);
      final path = Path();
      for (int i = 0; i < count; i++) {
        final angle = (i * 2 * pi / count) - (pi / 2);
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Gambar sumbu jari-jari dari pusat ke sudut
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * pi / count) - (pi / 2);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);

      // Gambar label teks di ujung
      final labelX = center.dx + (radius + 20) * cos(angle);
      final labelY = center.dy + (radius + 16) * sin(angle);

      final textSpan = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(labelX - tp.width / 2, labelY - tp.height / 2));
    }

    // Gambar poligon data skor pengguna
    final dataPath = Path();
    for (int i = 0; i < count; i++) {
      final val = values[i].clamp(0.1, 1.0);
      final r = radius * val;
      final angle = (i * 2 * pi / count) - (pi / 2);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, dataFillPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    // Titik-titik vertex
    final dotPaint = Paint()..color = strokeColor;
    for (int i = 0; i < count; i++) {
      final val = values[i].clamp(0.1, 1.0);
      final r = radius * val;
      final angle = (i * 2 * pi / count) - (pi / 2);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      canvas.drawCircle(Offset(x, y), 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CognitiveRadarPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
