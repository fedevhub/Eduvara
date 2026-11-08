import 'package:flutter_test/flutter_test.dart';
import 'package:eduvara/core/utils/quiz_score.dart';

void main() {
  group('formatQuizScore', () {
    test('formats earned and available points', () {
      expect(formatQuizScore(20, 40), '20/40');
    });

    test('does not render a zero denominator', () {
      expect(formatQuizScore(20, 0), '20');
    });

    test('returns an empty string when there is no score', () {
      expect(formatQuizScore(null, 40), '');
    });
  });

  group('effectiveQuizTotalPoints', () {
    test('prefers the total stored with the attempt', () {
      expect(effectiveQuizTotalPoints(20, 40), 20);
    });

    test('uses the quiz question points when the stored total is zero', () {
      expect(effectiveQuizTotalPoints(0, 40), 40);
    });
  });
}
