import 'package:flutter_test/flutter_test.dart';
import 'package:samguk_master/services/daily_challenge.dart';

void main() {
  final bank = List<int>.generate(474, (i) => i + 1);

  group('dayKey', () {
    test('UTC 기준 YYYY-MM-DD', () {
      expect(dayKey(DateTime.utc(2026, 9, 5, 13, 0)), '2026-09-05');
      expect(dayKey(DateTime.utc(2026, 1, 2)), '2026-01-02');
    });

    test('로컬 시각을 넣어도 UTC 로 환산된다', () {
      // KST 09:00 = 전날 UTC 00:00
      final kst = DateTime.utc(2026, 9, 5, 0, 0).add(const Duration(hours: 9));
      expect(dayKey(kst), '2026-09-05');
    });
  });

  group('dailyQuestionIds', () {
    test('같은 날짜면 항상 같은 문항', () {
      final a = dailyQuestionIds(DateTime.utc(2026, 9, 5), bank);
      final b = dailyQuestionIds(DateTime.utc(2026, 9, 5, 23, 59), bank);
      expect(a, b);
    });

    test('다른 날짜면 다른 문항', () {
      final a = dailyQuestionIds(DateTime.utc(2026, 9, 5), bank);
      final b = dailyQuestionIds(DateTime.utc(2026, 9, 6), bank);
      expect(a, isNot(b));
    });

    test('정확히 15문항, 중복 없음, 모두 은행 안에 있음', () {
      final ids = dailyQuestionIds(DateTime.utc(2026, 9, 5), bank);
      expect(ids.length, 15);
      expect(ids.toSet().length, 15);
      expect(ids.every(bank.contains), isTrue);
    });

    test('입력 순서가 달라도 결과가 같다', () {
      final shuffled = List<int>.from(bank)..shuffle();
      expect(
        dailyQuestionIds(DateTime.utc(2026, 9, 5), shuffled),
        dailyQuestionIds(DateTime.utc(2026, 9, 5), bank),
        reason: 'JSON 로딩 순서가 바뀌어도 같은 날엔 같은 문제여야 한다',
      );
    });

    test('은행이 비면 빈 목록', () {
      expect(dailyQuestionIds(DateTime.utc(2026, 9, 5), const []), isEmpty);
    });
  });

  group('nextStreak', () {
    final today = DateTime.utc(2026, 9, 5);

    test('첫 플레이는 1', () {
      expect(nextStreak(lastDay: null, currentStreak: 0, today: today), 1);
    });

    test('어제 플레이했으면 +1', () {
      expect(
        nextStreak(lastDay: '2026-09-04', currentStreak: 3, today: today),
        4,
      );
    });

    test('오늘 이미 했으면 그대로', () {
      expect(
        nextStreak(lastDay: '2026-09-05', currentStreak: 3, today: today),
        3,
      );
    });

    test('하루라도 건너뛰면 1로 초기화', () {
      expect(
        nextStreak(lastDay: '2026-09-03', currentStreak: 9, today: today),
        1,
      );
    });
  });
}
