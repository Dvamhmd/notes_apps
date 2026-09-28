import 'package:flutter/material.dart';
import '../models/iq_test_model.dart';
import '../widgets/iq_diagram_widget.dart';

class IqReviewScreen extends StatefulWidget {
  final List<IqQuestion> questions;
  final IqTestResult result;

  const IqReviewScreen({
    super.key,
    required this.questions,
    required this.result,
  });

  @override
  State<IqReviewScreen> createState() => _IqReviewScreenState();
}

class _IqReviewScreenState extends State<IqReviewScreen> {
  String _selectedFilter = 'Semua'; // 'Semua', 'Benar', 'Salah', 'Ragu'

  @override
  Widget build(BuildContext context) {
    final filteredQuestions = widget.questions.where((q) {
      final userAns = widget.result.userAnswers[q.id];
      final isCorrect = userAns != null && userAns == q.correctOptionIndex;
      final isFlagged = widget.result.flaggedQuestions[q.id] ?? false;

      if (_selectedFilter == 'Benar') return isCorrect;
      if (_selectedFilter == 'Salah') return !isCorrect;
      if (_selectedFilter == 'Ragu') return isFlagged;
      return true;
    }).toList();

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
          'Pembahasan & Kunci Jawaban',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua', '${widget.questions.length}'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Benar', '${widget.result.correctCount}', color: const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Salah', '${widget.result.wrongCount + widget.result.unansweredCount}', color: const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ragu', '${widget.result.flaggedQuestions.values.where((v) => v).length}', color: const Color(0xFFF59E0B)),
                ],
              ),
            ),
          ),

          // Question list
          Expanded(
            child: filteredQuestions.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada soal pada kategori filter ini.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    itemCount: filteredQuestions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final q = filteredQuestions[index];
                      final originalIndex = widget.questions.indexOf(q) + 1;
                      final userAns = widget.result.userAnswers[q.id];
                      final isCorrect = userAns != null && userAns == q.correctOptionIndex;
                      final isAnswered = userAns != null && userAns != -1;
                      final isFlagged = widget.result.flaggedQuestions[q.id] ?? false;

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isCorrect
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCorrect
                                            ? const Color(0xFFECFDF5)
                                            : const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isCorrect
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_rounded,
                                            size: 14,
                                            color: isCorrect
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isCorrect ? 'Jawaban Benar' : (isAnswered ? 'Jawaban Salah' : 'Tidak Dijawab'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isCorrect
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${q.category.title}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: q.category.color,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (isFlagged)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: Icon(Icons.bookmark_rounded, size: 16, color: Color(0xFFF59E0B)),
                                      ),
                                    Text(
                                      'Soal #$originalIndex',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Pertanyaan
                            Text(
                              q.questionText,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            // Diagram
                            IqDiagramWidget(
                              diagramType: q.diagramType,
                              diagramData: q.diagramData,
                            ),
                            const SizedBox(height: 12),

                            // Pilihan Jawaban
                            ...q.options.asMap().entries.map((entry) {
                              final optIdx = entry.key;
                              final optText = entry.value;
                              final isUserChoice = userAns == optIdx;
                              final isTargetCorrect = q.correctOptionIndex == optIdx;
                              final optLabel = String.fromCharCode(65 + optIdx);

                              Color bgColor = const Color(0xFFF8FAFC);
                              Color textColor = const Color(0xFF334155);
                              Color borderColor = const Color(0xFFE2E8F0);
                              IconData? stateIcon;
                              Color? iconColor;

                              if (isTargetCorrect) {
                                bgColor = const Color(0xFFECFDF5);
                                textColor = const Color(0xFF065F46);
                                borderColor = const Color(0xFF10B981);
                                stateIcon = Icons.check_circle_rounded;
                                iconColor = const Color(0xFF10B981);
                              } else if (isUserChoice && !isCorrect) {
                                bgColor = const Color(0xFFFEF2F2);
                                textColor = const Color(0xFF991B1B);
                                borderColor = const Color(0xFFEF4444);
                                stateIcon = Icons.cancel_rounded;
                                iconColor = const Color(0xFFEF4444);
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '$optLabel. ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        optText,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: (isTargetCorrect || isUserChoice)
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (isUserChoice && !isTargetCorrect)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Pilihan Anda',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    if (isTargetCorrect && isUserChoice)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Jawaban Anda (Tepat)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF059669),
                                          ),
                                        ),
                                      ),
                                    if (stateIcon != null)
                                      Icon(stateIcon, size: 18, color: iconColor),
                                  ],
                                ),
                              );
                            }),

                            // Box Pembahasan / Penjelasan
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFD97706)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Pembahasan Logika / Solusi:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    q.explanation,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String count, {Color? color}) {
    final isSelected = _selectedFilter == label;
    final activeColor = color ?? const Color(0xFF4F46E5);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
