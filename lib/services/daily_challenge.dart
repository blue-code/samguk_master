/// 데일리 챌린지 — 모든 사용자가 같은 날 같은 문제를 푼다.
///
/// 날짜 경계는 **UTC 고정**이다. 앱과 Cloudflare 워커가 서로 다른 기준을
/// 쓰면 플레이어의 '오늘' 점수가 어제 순위표에 들어간다.
/// 워커의 dayKey 와 반드시 같은 규칙을 유지할 것.
library;

import 'dart:math';

/// 한 판에 출제할 문항 수. QuizViewModel.sessionLength 와 같게 유지한다.
const int dailyQuestionCount = 15;

/// 순위표 파티션 키 — 'YYYY-MM-DD' (UTC).
String dayKey(DateTime date) {
  final utc = date.toUtc();
  final m = utc.month.toString().padLeft(2, '0');
  final d = utc.day.toString().padLeft(2, '0');
  return '${utc.year}-$m-$d';
}

/// 그날의 문항 ID 목록. 같은 날짜 = 같은 결과(기기·언어와 무관).
///
/// [allIds] 의 원본 순서에 의존하지 않도록 정렬 후 섞는다. 정렬을 빼면
/// JSON 로딩 순서가 바뀔 때 같은 날인데 다른 문제가 나온다.
List<int> dailyQuestionIds(
  DateTime date,
  List<int> allIds, {
  int count = dailyQuestionCount,
}) {
  final ids = List<int>.from(allIds)..sort();
  if (ids.isEmpty) return const [];

  final utc = date.toUtc();
  final seed = DateTime.utc(utc.year, utc.month, utc.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  final rng = Random(seed);

  for (var i = ids.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = ids[i];
    ids[i] = ids[j];
    ids[j] = tmp;
  }

  return ids.take(count).toList();
}

/// 연속 출석 계산. [lastDay] 는 마지막으로 완료한 날의 dayKey.
/// 어제면 이어지고, 오늘이면 그대로, 그보다 벌어지면 1부터 다시 센다.
int nextStreak({
  required String? lastDay,
  required int currentStreak,
  required DateTime today,
}) {
  if (lastDay == null || lastDay.isEmpty) return 1;

  final todayKey = dayKey(today);
  if (lastDay == todayKey) return currentStreak;

  final yesterdayKey = dayKey(today.toUtc().subtract(const Duration(days: 1)));
  if (lastDay == yesterdayKey) return currentStreak + 1;

  return 1;
}
