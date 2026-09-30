import 'package:flutter/material.dart';

enum AgeGroup {
  under16,
  age16to21,
  age22to35,
  age36to50,
  above50,
}

extension AgeGroupExtension on AgeGroup {
  String get label {
    switch (this) {
      case AgeGroup.under16:
        return 'Di Bawah 16 Tahun (Remaja Awal)';
      case AgeGroup.age16to21:
        return '16 – 21 Tahun (Pelajar / Mahasiswa)';
      case AgeGroup.age22to35:
        return '22 – 35 Tahun (Dewasa Muda / Produktif)';
      case AgeGroup.age36to50:
        return '36 – 50 Tahun (Dewasa Matang)';
      case AgeGroup.above50:
        return 'Di Atas 50 Tahun (Senior)';
    }
  }

  String get shortLabel {
    switch (this) {
      case AgeGroup.under16:
        return '< 16 thn';
      case AgeGroup.age16to21:
        return '16-21 thn';
      case AgeGroup.age22to35:
        return '22-35 thn';
      case AgeGroup.age36to50:
        return '36-50 thn';
      case AgeGroup.above50:
        return '> 50 thn';
    }
  }

  // Faktor kalibrasi baseline psikometri kecepatan & penalaran sesuai kurva perkembangan kognitif
  double get normFactor {
    switch (this) {
      case AgeGroup.under16:
        return 0.95; // Sedang berkembang
      case AgeGroup.age16to21:
        return 1.00; // Puncak kecepatan belajar
      case AgeGroup.age22to35:
        return 1.02; // Puncak stabilitas nalar nalar analitis
      case AgeGroup.age36to50:
        return 1.00; // Nalar kristalisasi tinggi
      case AgeGroup.above50:
        return 0.96; // Penyesuaian waktu reaksi alami
    }
  }
}

enum IqCategory {
  fluidLogic,       // Logika Abstrak & Matriks Pola
  spatialVisual,    // Persepsi Spasial & Transformasi Bentuk
  patternSeries,    // Deret Logika & Pola Numerik
  relationalAnalogy,// Nalar Relasi Konseptual Sehari-hari
  problemDeduction, // Pemecahan Masalah & Deduksi Situasional
}

extension IqCategoryExtension on IqCategory {
  String get title {
    switch (this) {
      case IqCategory.fluidLogic:
        return 'Logika Abstrak & Matriks Pola';
      case IqCategory.spatialVisual:
        return 'Persepsi Spasial & Bentuk';
      case IqCategory.patternSeries:
        return 'Pola Deret & Urutan Logis';
      case IqCategory.relationalAnalogy:
        return 'Nalar Hubungan Konsep';
      case IqCategory.problemDeduction:
        return 'Deduksi & Pemecahan Masalah';
    }
  }

  String get shortTitle {
    switch (this) {
      case IqCategory.fluidLogic:
        return 'Logika Pola';
      case IqCategory.spatialVisual:
        return 'Spasial';
      case IqCategory.patternSeries:
        return 'Deret Pola';
      case IqCategory.relationalAnalogy:
        return 'Hubungan';
      case IqCategory.problemDeduction:
        return 'Deduksi';
    }
  }

  IconData get icon {
    switch (this) {
      case IqCategory.fluidLogic:
        return Icons.grid_view_rounded;
      case IqCategory.spatialVisual:
        return Icons.category_rounded;
      case IqCategory.patternSeries:
        return Icons.auto_graph_rounded;
      case IqCategory.relationalAnalogy:
        return Icons.compare_arrows_rounded;
      case IqCategory.problemDeduction:
        return Icons.psychology_rounded;
    }
  }

  Color get color {
    switch (this) {
      case IqCategory.fluidLogic:
        return const Color(0xFF6366F1); // Indigo
      case IqCategory.spatialVisual:
        return const Color(0xFFF59E0B); // Amber
      case IqCategory.patternSeries:
        return const Color(0xFF10B981); // Emerald
      case IqCategory.relationalAnalogy:
        return const Color(0xFF3B82F6); // Blue
      case IqCategory.problemDeduction:
        return const Color(0xFFEC4899); // Pink
    }
  }

  String get description {
    switch (this) {
      case IqCategory.fluidLogic:
        return 'Kemampuan nalar murni (Fluid Intelligence) dalam membaca matriks pola visual dan keteraturan tanpa perlu hafalan.';
      case IqCategory.spatialVisual:
        return 'Kemampuan membayangkan rotasi bentuk 2D/3D, simetri, dan transformasi jaring-jaring objek di dalam pikiran.';
      case IqCategory.patternSeries:
        return 'Ketajaman mengidentifikasi pola pergantian, lompatan deret angka logis, dan ritme urutan simbolik.';
      case IqCategory.relationalAnalogy:
        return 'Kecakapan memahami korelasi fungsi sebab-akibat antar hal umum di kehidupan sehari-hari secara netral.';
      case IqCategory.problemDeduction:
        return 'Kecekatan memproses aturan kondisi, eliminasi logika, dan menemukan kesimpulan yang pasti benar.';
    }
  }
}

enum DiagramType {
  none,
  ravenMatrix3x3,
  ravenMatrix2x2,
  shapeSequenceVisual,
  gridRotationVisual,
  scaleBalanceVisual,
  diceNetVisual,
  geometricCountVisual,
  paperFoldVisual,
  gearRotationVisual,
  vennLogicVisual,
}

class IqQuestion {
  final String id;
  final IqCategory category;
  final String questionText;
  final DiagramType diagramType;
  final Map<String, dynamic>? diagramData;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final int difficulty; // 1: Easy, 2: Medium, 3: Hard

  const IqQuestion({
    required this.id,
    required this.category,
    required this.questionText,
    this.diagramType = DiagramType.none,
    this.diagramData,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.difficulty = 2,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'questionText': questionText,
        'diagramType': diagramType.name,
        'diagramData': diagramData,
        'options': options,
        'correctOptionIndex': correctOptionIndex,
        'explanation': explanation,
        'difficulty': difficulty,
      };

  factory IqQuestion.fromJson(Map<String, dynamic> json) {
    return IqQuestion(
      id: json['id'] as String,
      category: IqCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => IqCategory.fluidLogic,
      ),
      questionText: json['questionText'] as String,
      diagramType: DiagramType.values.firstWhere(
        (d) => d.name == json['diagramType'],
        orElse: () => DiagramType.none,
      ),
      diagramData: json['diagramData'] as Map<String, dynamic>?,
      options: List<String>.from(json['options'] as List),
      correctOptionIndex: json['correctOptionIndex'] as int,
      explanation: json['explanation'] as String,
      difficulty: json['difficulty'] as int? ?? 2,
    );
  }
}

class IqClassification {
  final String label;
  final String description;
  final Color color;
  final String percentileText;
  final String rankBadge;

  const IqClassification({
    required this.label,
    required this.description,
    required this.color,
    required this.percentileText,
    required this.rankBadge,
  });

  static IqClassification fromScore(int iq) {
    if (iq >= 130) {
      return const IqClassification(
        label: 'Sangat Superior (Mensa Level)',
        description: 'Tingkat kecerdasan istimewa dengan kemampuan logika analitis, pemecahan masalah kompleks, dan abstraksi di tingkat teratas (Top 2.2% populasi).',
        color: Color(0xFF7C3AED), // Deep Violet
        percentileText: 'Top 2.2% Populasi Dunia',
        rankBadge: '🌟 Sangat Superior',
      );
    } else if (iq >= 120) {
      return const IqClassification(
        label: 'Superior',
        description: 'Kecerdasan sangat tinggi. Sangat cakap dalam memproses pola abstrak baru, deduksi logis, dan menemukan solusi efisien dengan cepat.',
        color: Color(0xFF2563EB), // Indigo Blue
        percentileText: 'Top 9% Populasi Dunia',
        rankBadge: '💎 Superior',
      );
    } else if (iq >= 110) {
      return const IqClassification(
        label: 'Di Atas Rata-rata (High Average)',
        description: 'Kemampuan kognitif di atas rata-rata populasi. Cepat memahami pola relasional baru dan andal menyelesaikan tantangan logis.',
        color: Color(0xFF059669), // Emerald Green
        percentileText: 'Top 25% Populasi Dunia',
        rankBadge: '✨ Di Atas Rata-rata',
      );
    } else if (iq >= 90) {
      return const IqClassification(
        label: 'Rata-rata Normal (Average)',
        description: 'Tingkat kecerdasan umum standar mayoritas populasi dunia (IQ 90-109). Berfungsi sangat baik dalam pemecahan masalah logis sehari-hari.',
        color: Color(0xFF0284C7), // Sky Blue
        percentileText: 'Rentang Normal 50% Populasi',
        rankBadge: '🎯 Rata-rata Normal',
      );
    } else if (iq >= 80) {
      return const IqClassification(
        label: 'Di Bawah Rata-rata (Low Average)',
        description: 'Kemampuan kognitif cukup baik, namun membutuhkan waktu dan latihan tambahan dalam mengurai pola yang berlapis atau kompleks.',
        color: Color(0xFFD97706), // Amber
        percentileText: 'Rentang Bawah Normal',
        rankBadge: '⚡ Cukup / Low Average',
      );
    } else {
      return const IqClassification(
        label: 'Perlu Latihan & Stimulasi',
        description: 'Disarankan untuk lebih sering melatih otak dengan teka-teki logika visual, deret angka bertahap, dan membaca terarah.',
        color: Color(0xFFDC2626), // Red
        percentileText: 'Perlu Stimulasi Kognitif',
        rankBadge: '🌱 Perlu Peningkatan',
      );
    }
  }
}

class IqTestResult {
  final String id;
  final DateTime completedAt;
  final AgeGroup ageGroup;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final int iqScore;
  final int durationSeconds;
  final Map<String, int> userAnswers; // questionId -> optionIndex (-1 for unanswered)
  final Map<String, bool> flaggedQuestions;
  final Map<String, double> categoryPercentages; // category.name -> 0.0 to 100.0
  final double speedAccuracyIndex; // 0.0 - 100.0

  const IqTestResult({
    required this.id,
    required this.completedAt,
    this.ageGroup = AgeGroup.age22to35,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.iqScore,
    required this.durationSeconds,
    required this.userAnswers,
    required this.flaggedQuestions,
    required this.categoryPercentages,
    this.speedAccuracyIndex = 75.0,
  });

  IqClassification get classification => IqClassification.fromScore(iqScore);

  double get accuracyPercent =>
      totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'completedAt': completedAt.toIso8601String(),
        'ageGroup': ageGroup.name,
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'unansweredCount': unansweredCount,
        'iqScore': iqScore,
        'durationSeconds': durationSeconds,
        'userAnswers': userAnswers,
        'flaggedQuestions': flaggedQuestions,
        'categoryPercentages': categoryPercentages,
        'speedAccuracyIndex': speedAccuracyIndex,
      };

  factory IqTestResult.fromJson(Map<String, dynamic> json) {
    return IqTestResult(
      id: json['id'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      ageGroup: AgeGroup.values.firstWhere(
        (a) => a.name == json['ageGroup'],
        orElse: () => AgeGroup.age22to35,
      ),
      totalQuestions: json['totalQuestions'] as int,
      correctCount: json['correctCount'] as int,
      wrongCount: json['wrongCount'] as int,
      unansweredCount: json['unansweredCount'] as int,
      iqScore: json['iqScore'] as int,
      durationSeconds: json['durationSeconds'] as int,
      userAnswers: Map<String, int>.from(json['userAnswers'] as Map),
      flaggedQuestions: Map<String, bool>.from(json['flaggedQuestions'] as Map),
      categoryPercentages: Map<String, double>.from(
        (json['categoryPercentages'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      speedAccuracyIndex: (json['speedAccuracyIndex'] as num?)?.toDouble() ?? 75.0,
    );
  }
}
