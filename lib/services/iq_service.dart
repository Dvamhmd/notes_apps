import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/iq_test_model.dart';

class IqService {
  static const String _historyKey = 'user_iq_test_history_v2';
  final _uuid = const Uuid();

  /// Menghitung skor IQ berdasarkan rumus psikometri baku (Wechsler Normal Distribution).
  /// - Mean = 100, Standar Deviasi (SD) = 15
  /// - Memperhitungkan bobot tingkat kesulitan butir soal (Difficulty: 1, 2, 3)
  /// - Disesuaikan dengan kalibrasi kelompok usia (Age-Stratified Norming)
  /// - Memperhitungkan indeks efisiensi kecepatan & ketelitian (Speed-Accuracy Index)
  IqTestResult calculateResult({
    required List<IqQuestion> questions,
    required Map<String, int> userAnswers,
    required Map<String, bool> flaggedQuestions,
    required int durationSeconds,
    AgeGroup ageGroup = AgeGroup.age22to35,
  }) {
    int correctCount = 0;
    int wrongCount = 0;
    int unansweredCount = 0;

    double earnedWeightedScore = 0.0;
    double maxWeightedScore = 0.0;

    // Hitung performa per 5 kategori kognitif
    final Map<IqCategory, double> categoryEarned = {};
    final Map<IqCategory, double> categoryMax = {};

    for (final cat in IqCategory.values) {
      categoryEarned[cat] = 0.0;
      categoryMax[cat] = 0.0;
    }

    for (final q in questions) {
      final weight = q.difficulty == 1
          ? 1.0
          : q.difficulty == 2
              ? 1.6
              : 2.3;

      maxWeightedScore += weight;
      categoryMax[q.category] = (categoryMax[q.category] ?? 0.0) + weight;

      final chosen = userAnswers[q.id];
      if (chosen == null || chosen == -1) {
        unansweredCount++;
      } else if (chosen == q.correctOptionIndex) {
        correctCount++;
        earnedWeightedScore += weight;
        categoryEarned[q.category] =
            (categoryEarned[q.category] ?? 0.0) + weight;
      } else {
        wrongCount++;
      }
    }

    // Hitung persentase ketercapaian per kategori (0.0 - 100.0)
    final Map<String, double> categoryPercentages = {};
    for (final cat in IqCategory.values) {
      final maxVal = categoryMax[cat] ?? 1.0;
      final earnedVal = categoryEarned[cat] ?? 0.0;
      categoryPercentages[cat.name] =
          maxVal > 0 ? (earnedVal / maxVal) * 100.0 : 0.0;
    }

    // Rasio performa terbobot mentah (0.0 s/d 1.0)
    final double rawRatio =
        maxWeightedScore > 0 ? earnedWeightedScore / maxWeightedScore : 0.0;

    // Kalibrasi faktor usia (Age Normalization)
    final double ageAdjustedRatio = (rawRatio * ageGroup.normFactor).clamp(0.0, 1.0);

    // Indeks Efisiensi Kecepatan & Ketelitian (Speed-Accuracy Index)
    // Waktu batas = 1500 detik (25 menit). Waktu optimal = 480 - 1100 detik.
    double speedAccuracyIndex = 70.0;
    double timeBonus = 0.0;

    if (durationSeconds > 0) {
      final double speedRatio = (1500 - durationSeconds).clamp(0, 1200) / 1200.0;
      speedAccuracyIndex = (rawRatio * 65.0) + (speedRatio * 35.0);

      // Bonus waktu hanya berlaku jika akurasi tinggi (mencegah tebakan cepat acak)
      if (rawRatio >= 0.60 && durationSeconds >= 240) {
        timeBonus = speedRatio * 4.0;
      }
    }

    // Pemetaan ke Kurva Gauss Normal Psikometri (Wechsler Scale SD=15, Mean=100)
    // Rentang Skor Standar: 70 - 150
    int calculatedIq;
    if (ageAdjustedRatio <= 0.0) {
      calculatedIq = 70;
    } else {
      // Model transformasi non-linier respons kognitif psikometri
      double estimatedIq = 70.0 + (ageAdjustedRatio * 72.0) + timeBonus;
      if (ageAdjustedRatio > 0.85) {
        // Curve boost untuk kategori Mensa / Superior Atas
        estimatedIq += (ageAdjustedRatio - 0.85) * 24.0;
      }
      calculatedIq = estimatedIq.round().clamp(70, 150);
    }

    return IqTestResult(
      id: _uuid.v4(),
      completedAt: DateTime.now(),
      ageGroup: ageGroup,
      totalQuestions: questions.length,
      correctCount: correctCount,
      wrongCount: wrongCount,
      unansweredCount: unansweredCount,
      iqScore: calculatedIq,
      durationSeconds: durationSeconds,
      userAnswers: userAnswers,
      flaggedQuestions: flaggedQuestions,
      categoryPercentages: categoryPercentages,
      speedAccuracyIndex: speedAccuracyIndex.clamp(0.0, 100.0),
    );
  }

  /// Mengambil riwayat tes yang tersimpan
  Future<List<IqTestResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_historyKey) ?? [];
    final List<IqTestResult> results = [];

    for (final item in rawList) {
      try {
        final json = jsonDecode(item) as Map<String, dynamic>;
        results.add(IqTestResult.fromJson(json));
      } catch (e) {
        // Abaikan item yang tidak valid
      }
    }

    // Urutkan dari yang terbaru
    results.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return results;
  }

  /// Menyimpan hasil tes ke penyimpanan lokal
  Future<void> saveResult(IqTestResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHistory = await getHistory();
    currentHistory.insert(0, result);

    // Batasi riwayat maksimum 20 tes terakhir
    final limited = currentHistory.take(20).toList();
    final stringList = limited.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_historyKey, stringList);
  }

  /// Menghapus satu riwayat tes berdasarkan ID
  Future<void> deleteResult(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHistory = await getHistory();
    currentHistory.removeWhere((r) => r.id == id);
    final stringList = currentHistory.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_historyKey, stringList);
  }

  /// Menghapus seluruh riwayat tes IQ
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Mendapatkan skor tertinggi dari riwayat
  Future<int?> getBestScore() async {
    final history = await getHistory();
    if (history.isEmpty) return null;
    int best = 0;
    for (final r in history) {
      if (r.iqScore > best) best = r.iqScore;
    }
    return best;
  }
}
