import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/iq_test_model.dart';
import '../services/iq_service.dart';
import 'iq_test_screen.dart';
import 'iq_result_screen.dart';

class IqIntroScreen extends StatefulWidget {
  const IqIntroScreen({super.key});

  @override
  State<IqIntroScreen> createState() => _IqIntroScreenState();
}

class _IqIntroScreenState extends State<IqIntroScreen> {
  final IqService _iqService = IqService();
  List<IqTestResult> _history = [];
  bool _isLoading = true;
  AgeGroup _selectedAgeGroup = AgeGroup.age22to35;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _iqService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  void _showAgeSelectionAndStart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: Color(0xFF4F46E5), size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Pilih Kelompok Usia Anda',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Diperlukan untuk mengkalibrasi kurva norma psikometri agar penilaian skor IQ 100% presisi dan adil sesuai tahap perkembangan nalar.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...AgeGroup.values.map((age) {
                      final isSelected = _selectedAgeGroup == age;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              _selectedAgeGroup = age;
                            });
                            setState(() {
                              _selectedAgeGroup = age;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: isSelected
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    age.label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _launchTestScreen();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Lanjutkan & Mulai Tes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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

  void _launchTestScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IqTestScreen(ageGroup: _selectedAgeGroup),
      ),
    ).then((_) => _loadHistory());
  }

  void _openResult(IqTestResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IqResultScreen(result: result, isNewTest: false),
      ),
    ).then((_) => _loadHistory());
  }

  Future<void> _confirmDeleteSingleHistory(IqTestResult item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Sesi Tes Ini?'),
        content: Text(
          'Hasil tes IQ ${item.iqScore} (${item.classification.label}) ini akan dihapus dari riwayat perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _iqService.deleteResult(item.id);
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi tes berhasil dihapus dari riwayat'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semua Riwayat Tes?'),
        content: const Text(
          'Semua riwayat hasil tes IQ yang tersimpan akan dihapus secara permanen dari perangkat ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _iqService.clearHistory();
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seluruh riwayat tes berhasil dibersihkan'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Tes IQ Standar Kognitif',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              tooltip: 'Hapus Riwayat',
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF64748B)),
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner Hero
                      _buildHeroCard(),
                      const SizedBox(height: 20),

                      // Standar & Aturan Pengerjaan
                      _buildRulesCard(),
                      const SizedBox(height: 20),

                      // 5 Dimensi Kognitif Netral
                      _buildCategoriesCard(),
                      const SizedBox(height: 24),

                      // Tombol Mulai Tes
                      ElevatedButton(
                        onPressed: _showAgeSelectionAndStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology_rounded, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Mulai Tes IQ Sekarang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Riwayat Tes Sebelumnya
                      if (_history.isNotEmpty) ...[
                        _buildHistorySection(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    final bestScore = _history.isNotEmpty
        ? _history.map((e) => e.iqScore).reduce((a, b) => a > b ? a : b)
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uji Nalar & Kecerdasan Cair',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Netral Budaya & 100% Bebas Hafalan Wawasan',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFE0E7FF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Tes ini dirancang menguji nalar logis murni (Fluid Intelligence) dan pemecahan masalah secara objektif tanpa terpengaruh latar belakang pendidikan, hafalan kata sulit, maupun wawasan khusus. Bahasa yang digunakan sangat umum, jelas, dan mudah dipahami semua kalangan.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFFF1F5F9),
            ),
          ),
          if (bestScore != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.military_tech_rounded, color: Color(0xFFFDE047), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Skor IQ Tertinggi Anda: $bestScore',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
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
              Icon(Icons.rule_rounded, color: Color(0xFF4F46E5), size: 22),
              SizedBox(width: 10),
              Text(
                'Petunjuk & Format Penilaian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRuleItem(
            icon: Icons.shuffle_rounded,
            title: 'Bank Soal Dinamis',
            value: '25 Soal Acak Seimbang dari 75+ Bank Soal (Bebas efek hafalan saat tes ulang)',
          ),
          _buildRuleItem(
            icon: Icons.timer_outlined,
            title: 'Waktu Pengerjaan',
            value: '25 Menit (Kecepatan & ketepatan diperhitungkan)',
          ),
          _buildRuleItem(
            icon: Icons.verified_outlined,
            title: 'Kurva Distribusi Normal',
            value: 'Skala Gauss Baku (Mean = 100, Standar Deviasi = 15)',
          ),
          _buildRuleItem(
            icon: Icons.public_rounded,
            title: 'Netral & Culture-Fair',
            value: 'Hanya menguji nalar logika, matriks bentuk, dan deret pola',
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
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
              Icon(Icons.dashboard_customize_outlined, color: Color(0xFF4F46E5), size: 22),
              SizedBox(width: 10),
              Text(
                '5 Dimensi Kognitif yang Diuji',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...IqCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon, size: 18, color: cat.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: cat.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cat.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
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

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Hasil Tes Anda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              '${_history.length} sesi tersimpan',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _history[index];
            final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(item.completedAt);
            final classification = item.classification;

            return InkWell(
              onTap: () => _openResult(item),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: classification.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: classification.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'IQ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: classification.color,
                            ),
                          ),
                          Text(
                            '${item.iqScore}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: classification.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classification.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dateStr • Benar ${item.correctCount}/${item.totalQuestions} • ${item.ageGroup.shortLabel}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      tooltip: 'Hapus Sesi Ini',
                      onPressed: () => _confirmDeleteSingleHistory(item),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
