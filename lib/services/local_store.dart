import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const String _bestScoreKey = 'samguk_best_score';

  // 최고 점수 불러오기
  static Future<int> getBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestScoreKey) ?? 0;
  }

  // 최고 점수 업데이트 (기존보다 높을 때만 true 반환)
  static Future<bool> updateBestScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    int currentBest = prefs.getInt(_bestScoreKey) ?? 0;
    
    if (newScore > currentBest) {
      await prefs.setInt(_bestScoreKey, newScore);
      return true; // 신기록 갱신됨
    }
    return false; // 갱신 실패 (기록 미달)
  }

  // [NEW] 정복 진행도 — 난이도별로 "맞힌 고유 문항 ID" 집합을 영구 저장
  // 키: samguk_mastered_Easy / _Medium / _Hard (난이도 문자열 그대로 사용)
  static String _masteredKey(String difficulty) => 'samguk_mastered_$difficulty';

  static Future<Set<int>> getMasteredIds(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_masteredKey(difficulty)) ?? const [];
    return list.map(int.tryParse).whereType<int>().toSet();
  }

  static Future<void> saveMasteredIds(String difficulty, Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _masteredKey(difficulty),
      ids.map((e) => e.toString()).toList(),
    );
  }

  // 정복 진행도 전체 초기화 (디버그/재도전용)
  static Future<void> resetConquest(List<String> difficulties) async {
    final prefs = await SharedPreferences.getInstance();
    for (final d in difficulties) {
      await prefs.remove(_masteredKey(d));
    }
    await prefs.remove(_wrongKey);
  }

  // 복습 대기열 — 이전 판에서 틀린 문항 ID.
  // 같은 판 안에서는 이미 큐 끝으로 재투입되지만, 판이 끝나면 사라졌다.
  // 다음 판에서 우선 출제하기 위해 세션 간에 이월한다.
  static const String _wrongKey = 'samguk_wrong_ids';

  static Future<Set<int>> getWrongIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_wrongKey) ?? const [];
    return list.map(int.tryParse).whereType<int>().toSet();
  }

  static Future<void> saveWrongIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _wrongKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  // 광고 제거 인앱 결제 권한.
  // 스토어 영수증이 진실의 원천이고 이 값은 캐시다 —
  // 앱 시작 직후 및 오프라인에서 광고를 띄우지 않기 위해 저장한다.
  static const String _adFreeKey = 'samguk_ad_free';

  static Future<bool> getAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adFreeKey) ?? false;
  }

  static Future<void> setAdFree(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adFreeKey, value);
  }

  // [NEW] 오디오 음소거 상태 가져오기
  static const String _isMutedKey = 'samguk_is_muted';
  static Future<bool> getIsMuted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isMutedKey) ?? false;
  }

  // [NEW] 오디오 음소거 상태 저장하기
  static Future<void> saveIsMuted(bool isMuted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isMutedKey, isMuted);
  }
}
