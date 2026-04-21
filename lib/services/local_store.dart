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
}
