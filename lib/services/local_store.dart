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
