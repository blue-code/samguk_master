import 'package:flutter_test/flutter_test.dart';
import 'package:samguk_master/services/external_leaderboard_service.dart';

/// 스크린샷 자동화 빌드에서 데모 점수(5500 'Lord')가 실서버 랭킹에
/// 등록됐던 사고의 회귀 방지.
///
/// 기본 실행: 가드가 꺼져 있어야 한다 (실제 유저 제출을 막으면 안 됨).
///   flutter test test/leaderboard_guard_test.dart
/// 자동화 빌드 실행: 가드가 켜져 제출이 차단돼야 한다.
///   flutter test test/leaderboard_guard_test.dart \
///     --dart-define=SS_SHOW_RESULT=true --dart-define=EXPECT_AUTOMATION=true
void main() {
  const expected =
      bool.fromEnvironment('EXPECT_AUTOMATION', defaultValue: false);

  test('isAutomationBuild reflects the SS_* dart-defines', () {
    expect(ExternalLeaderboardService.isAutomationBuild, expected);
  });

  test(
    'submitScore refuses to submit in an automation build',
    () async {
      expect(
        await ExternalLeaderboardService.submitScore(
          score: 5500,
          locale: 'ko',
          nickname: 'Lord',
        ),
        isNull,
      );
    },
    skip: !expected ? 'automation build로 실행할 때만 의미 있음' : null,
  );
}
