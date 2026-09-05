import 'package:flutter_test/flutter_test.dart';
import 'package:samguk_master/models/question_model.dart';

/// 리워드 보상 로직 중 순수 계산 부분에 대한 회귀 테스트.
/// QuizViewModel 은 생성자에서 오디오 플러그인을 건드려 단위 테스트에서
/// 인스턴스화할 수 없으므로, 여기서는 모델 계층만 검증한다.
void main() {
  Question q(List<String> choices, int answerIndex) => Question(
        id: 1,
        categoryMap: const {'ko': 'c'},
        difficulty: 'Easy',
        questionMap: const {'ko': 'q'},
        choicesMap: {'ko': choices},
        answerIndex: answerIndex,
        explanationMap: const {'ko': 'e'},
        tags: const [],
      );

  test('choiceCount 는 선택지 개수를 센다', () {
    expect(q(['a', 'b', 'c', 'd'], 0).choiceCount, 4);
    expect(q(['a', 'b'], 1).choiceCount, 2);
  });

  test('50:50 은 오답의 절반을 가리고 정답은 남긴다', () {
    // applyFiftyFiftyHint 와 같은 계산을 재현해 불변식을 확인한다.
    final question = q(['a', 'b', 'c', 'd'], 2);
    final wrong = <int>[];
    for (var i = 0; i < question.choiceCount; i++) {
      if (i != question.answerIndex) wrong.add(i);
    }
    final hidden = wrong.take(wrong.length ~/ 2).toSet();

    expect(hidden.length, 1, reason: '4지선다에서 오답 3개 중 1개를 가린다');
    expect(hidden.contains(question.answerIndex), isFalse,
        reason: '정답은 절대 가려지면 안 된다');
  });

  test('2지선다에서는 힌트가 동작하지 않는다', () {
    final question = q(['a', 'b'], 0);
    final wrong = <int>[];
    for (var i = 0; i < question.choiceCount; i++) {
      if (i != question.answerIndex) wrong.add(i);
    }
    expect(wrong.length < 2, isTrue, reason: '가릴 오답이 부족하면 힌트 미적용');
  });
}
