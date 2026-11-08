String formatQuizScore(Object? score, Object? totalPoints) {
  if (score is! num) return '';

  final points = totalPoints is num ? totalPoints.round() : 0;
  final earned = score.round();
  return points > 0 ? '$earned/$points' : '$earned';
}

int effectiveQuizTotalPoints(Object? storedPoints, Object? questionPoints) {
  if (storedPoints is num && storedPoints > 0) return storedPoints.round();
  if (questionPoints is num && questionPoints > 0) {
    return questionPoints.round();
  }
  return 0;
}
