import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/iq_questions_data.dart';
import '../models/iq_test_model.dart';
import '../services/iq_service.dart';
import '../widgets/iq_diagram_widget.dart';
import 'iq_result_screen.dart';

class IqTestScreen extends StatefulWidget {
  final AgeGroup ageGroup;

  const IqTestScreen({
    super.key,
    this.ageGroup = AgeGroup.age22to35,
  });

  @override
  State<IqTestScreen> createState() => _IqTestScreenState();
}

class _IqTestScreenState extends State<IqTestScreen> {
  final IqService _iqService = IqService();
  late final List<IqQuestion> _questions;

  int _currentIndex = 0;
  final Map<String, int> _userAnswers = {}; // questionId -> selectedOptionIndex
  final Map<String, bool> _flaggedQuestions = {}; // questionId -> isFlagged

  static const int _totalDurationSeconds = 25 * 60; // 25 Menit
  int _secondsRemaining = _totalDurationSeconds;
  Timer? _timer;
  final DateTime _startTime = DateTime.now();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _questions = IqQuestionsData.getRandomizedTestSet(ageGroup: widget.ageGroup);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _autoSubmitOnTimeUp();
      }
    });
  }

  void _autoSubmitOnTimeUp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.timer_off_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Waktu Habis!'),
          ],
        ),
        content: const Text(
          'Waktu 25 menit pengerjaan tes IQ telah berakhir. Jawaban Anda akan otomatis dikumpulkan dan dinilai.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _processSubmission();
            },
            child: const Text('Lihat Hasil Tes'),
          ),
        ],
      ),
    );
  }

  void _selectOption(int optionIndex) {
    HapticFeedback.selectionClick();
    final q = _questions[_currentIndex];
    setState(() {
      if (_userAnswers[q.id] == optionIndex) {
        // Toggle unselect if tapped again
        _userAnswers.remove(q.id);
      } else {
        _userAnswers[q.id] = optionIndex;
      }
    });
  }

  void _toggleFlag() {
    HapticFeedback.mediumImpact();
    final q = _questions[_currentIndex];
    setState(() {
      _flaggedQuestions[q.id] = !(_flaggedQuestions[q.id] ?? false);
    });
  }

  void _goToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      setState(() {
        _currentIndex = index;
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _goToQuestion(_currentIndex + 1);
    } else {
      _confirmFinishTest();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      _goToQuestion(_currentIndex - 1);
    }
  }

  void _confirmFinishTest() {
    final answeredCount = _userAnswers.length;
    final unansweredCount = _questions.length - answeredCount;
    final flaggedCount = _flaggedQuestions.values.where((f) => f).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 18),
                const Text(
                  'Konfirmasi Selesai Tes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat(
                        'Terjawab',
                        '$answeredCount',
                        const Color(0xFF10B981),
                        Icons.check_circle_rounded,
                      ),
                      _buildSummaryStat(
                        'Kosong',
                        '$unansweredCount',
                        const Color(0xFFEF4444),
                        Icons.cancel_rounded,
                      ),
                      _buildSummaryStat(
                        'Ragu-ragu',
                        '$flaggedCount',
                        const Color(0xFFF59E0B),
                        Icons.bookmark_rounded,
                      ),
                    ],
                  ),
                ),
                if (unansweredCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '⚠️ Masih ada $unansweredCount soal yang belum Anda jawab. Yakin ingin mengakhiri sekarang?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text(
                          'Periksa Lagi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _processSubmission();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Kumpulkan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  void _processSubmission() async {
    _timer?.cancel();
    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;

    final result = _iqService.calculateResult(
      questions: _questions,
      userAnswers: _userAnswers,
      flaggedQuestions: _flaggedQuestions,
      durationSeconds: durationSeconds,
      ageGroup: widget.ageGroup,
    );

    // Simpan ke storage lokal
    await _iqService.saveResult(result);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => IqResultScreen(
            result: result,
            questions: _questions,
            isNewTest: true,
          ),
        ),
      );
    }
  }

  void _openQuestionGridSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kisi-kisi Soal',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '${_userAnswers.length} dari ${_questions.length} Terisi',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem('Terjawab', const Color(0xFF4F46E5)),
                        _buildLegendItem('Ragu-ragu', const Color(0xFFF59E0B)),
                        _buildLegendItem('Kosong', const Color(0xFFE2E8F0)),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: GridView.builder(
                        itemCount: _questions.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                        itemBuilder: (context, idx) {
                          final q = _questions[idx];
                          final isAnswered = _userAnswers.containsKey(q.id);
                          final isFlagged = _flaggedQuestions[q.id] ?? false;
                          final isCurrent = idx == _currentIndex;

                          Color bgColor;
                          Color textColor;
                          Color borderColor;

                          if (isCurrent) {
                            borderColor = const Color(0xFF4F46E5);
                          } else {
                            borderColor = Colors.transparent;
                          }

                          if (isFlagged) {
                            bgColor = const Color(0xFFFEF3C7);
                            textColor = const Color(0xFFB45309);
                          } else if (isAnswered) {
                            bgColor = const Color(0xFFEEF2FF);
                            textColor = const Color(0xFF4F46E5);
                          } else {
                            bgColor = const Color(0xFFF1F5F9);
                            textColor = const Color(0xFF64748B);
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _goToQuestion(idx);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? const Color(0xFF4F46E5)
                                      : borderColor,
                                  width: isCurrent ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  if (isFlagged)
                                    const Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Icon(
                                        Icons.bookmark_rounded,
                                        size: 12,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _confirmFinishTest();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Selesaikan & Kumpulkan Tes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<bool> _onWillPop() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Tes IQ?'),
        content: const Text(
          'Progres pengerjaan tes ini belum disimpan. Jika keluar sekarang, tes akan dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Lanjutkan Tes'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    final selectedOption = _userAnswers[q.id];
    final isFlagged = _flaggedQuestions[q.id] ?? false;
    final progress = (_currentIndex + 1) / _questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldLeave = await _onWillPop();
        if (shouldLeave && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF1E293B)),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final leave = await _onWillPop();
              if (leave && mounted) {
                navigator.pop();
              }
            },
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _secondsRemaining < 300
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 16,
                  color: _secondsRemaining < 300
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF4F46E5),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTimer(_secondsRemaining),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _secondsRemaining < 300
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Tandai Ragu-ragu',
              icon: Icon(
                isFlagged ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isFlagged ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
              ),
              onPressed: _toggleFlag,
            ),
            IconButton(
              tooltip: 'Daftar Soal',
              icon: const Icon(Icons.grid_view_rounded, color: Color(0xFF475569)),
              onPressed: _openQuestionGridSheet,
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              minHeight: 4,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Kategori & No Soal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: q.category.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      q.category.icon,
                                      size: 14,
                                      color: q.category.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      q.category.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: q.category.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Soal ${_currentIndex + 1} dari ${_questions.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Kartu Soal
                          Container(
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
                                Text(
                                  q.questionText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.6,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                // Diagram jika ada
                                IqDiagramWidget(
                                  diagramType: q.diagramType,
                                  diagramData: q.diagramData,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Pilihan Ganda (A - E)
                          ...q.options.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final optionText = entry.value;
                            final isSelected = selectedOption == idx;
                            final optionLabel = String.fromCharCode(65 + idx); // A, B, C, D, E

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => _selectOption(idx),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEEF2FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF4F46E5)
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                                            : const Color(0xFF0F172A).withValues(alpha: 0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF4F46E5)
                                              : const Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF4F46E5)
                                                : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            optionLabel,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          optionText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF312E81)
                                                : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF4F46E5),
                                          size: 20,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Navigation Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _currentIndex > 0 ? _prevQuestion : null,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Sebelumnya'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _nextQuestion,
                          icon: Icon(
                            _currentIndex == _questions.length - 1
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _currentIndex == _questions.length - 1
                                ? 'Selesaikan'
                                : 'Berikutnya',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
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
    );
  }
}
