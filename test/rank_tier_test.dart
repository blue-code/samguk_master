import 'package:flutter_test/flutter_test.dart';
import 'package:samguk_master/viewmodels/quiz_viewmodel.dart';

/// 한 판 최대 점수는 3000 — (10 + 15) * (1+2+...+15).
/// 이전 임계값(1000/5000)에서는 최상위 계급이 도달 불가였다.
void main() {
  const maxReachable = 3000;

  test('모든 계급이 도달 가능한 점수 구간에 있다', () {
    final reachable = <String>{};
    for (var s = 0; s <= maxReachable; s++) {
      reachable.add(QuizViewModel.rankNameForScore(s));
    }
    expect(
      reachable,
      {'Soldier', 'General', 'Lord', 'Emperor'},
      reason: '3000점 이하에서 네 계급이 모두 나와야 한다',
    );
  });

  test('경계값', () {
    expect(QuizViewModel.rankNameForScore(0), 'Soldier');
    expect(QuizViewModel.rankNameForScore(799), 'Soldier');
    expect(QuizViewModel.rankNameForScore(800), 'General');
    expect(QuizViewModel.rankNameForScore(1599), 'General');
    expect(QuizViewModel.rankNameForScore(1600), 'Lord');
    expect(QuizViewModel.rankNameForScore(2399), 'Lord');
    expect(QuizViewModel.rankNameForScore(2400), 'Emperor');
    expect(QuizViewModel.rankNameForScore(maxReachable), 'Emperor');
  });

  test('최상위 업적 임계값이 도달 가능하다', () {
    expect(QuizViewModel.topRankScore, lessThanOrEqualTo(maxReachable));
  });

  test('정복 비율에 100%가 없다 (모르는 문항 하나가 영구 차단하지 않도록)', () {
    expect(QuizViewModel.stageRatios.every((r) => r < 1.0), isTrue);
  });
}
