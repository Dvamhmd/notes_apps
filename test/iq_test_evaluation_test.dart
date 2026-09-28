import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/data/iq_questions_data.dart';
import 'package:notes_app/models/iq_test_model.dart';
import 'package:notes_app/services/iq_service.dart';

void main() {
  group('IqService & Psychometric Standard Tests', () {
    late IqService service;
    late List<IqQuestion> questions;

    setUp(() {
      service = IqService();
      questions = IqQuestionsData.getQuestions();
    });

    test('Harus memuat 25 soal dengan 5 kategori terdistribusi seimbang', () {
      expect(questions.length, equals(25));

      final catCounts = <IqCategory, int>{};
      for (final q in questions) {
        catCounts[q.category] = (catCounts[q.category] ?? 0) + 1;
        expect(q.options.length, greaterThanOrEqualTo(4));
        expect(q.correctOptionIndex, inInclusiveRange(0, q.options.length - 1));
        expect(q.explanation.isNotEmpty, isTrue);
      }

      for (final cat in IqCategory.values) {
        expect(catCounts[cat], equals(5),
            reason: 'Setiap kategori harus memiliki tepat 5 soal');
      }
    });

    test('Jawaban sempurna (100% benar) harus menghasilkan skor Sangat Superior (IQ >= 140)', () {
      final userAnswers = <String, int>{};
      final flagged = <String, bool>{};

      for (final q in questions) {
        userAnswers[q.id] = q.correctOptionIndex;
      }

      final result = service.calculateResult(
        questions: questions,
        userAnswers: userAnswers,
        flaggedQuestions: flagged,
        durationSeconds: 600, // 10 menit
      );

      expect(result.totalQuestions, equals(25));
      expect(result.correctCount, equals(25));
      expect(result.wrongCount, equals(0));
      expect(result.unansweredCount, equals(0));
      expect(result.accuracyPercent, equals(100.0));
      expect(result.iqScore, greaterThanOrEqualTo(140));
      expect(result.classification.rankBadge, contains('Genius'));
    });

    test('Jawaban rata-rata (50% benar) harus menghasilkan skor IQ normal (~100)', () {
      final userAnswers = <String, int>{};
      final flagged = <String, bool>{};

      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        if (i % 2 == 0) {
          userAnswers[q.id] = q.correctOptionIndex;
        } else {
          userAnswers[q.id] = (q.correctOptionIndex + 1) % q.options.length;
        }
      }

      final result = service.calculateResult(
        questions: questions,
        userAnswers: userAnswers,
        flaggedQuestions: flagged,
        durationSeconds: 900,
      );

      expect(result.iqScore, inInclusiveRange(95, 110));
      expect(result.classification.label, contains('Rata-rata'));
    });

    test('Jawaban kosong / salah semua menghasilkan skor batas bawah (IQ 70)', () {
      final userAnswers = <String, int>{};
      final flagged = <String, bool>{};

      final result = service.calculateResult(
        questions: questions,
        userAnswers: userAnswers,
        flaggedQuestions: flagged,
        durationSeconds: 1500,
      );

      expect(result.correctCount, equals(0));
      expect(result.unansweredCount, equals(25));
      expect(result.iqScore, equals(70));
    });
  });
}
