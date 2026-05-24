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
