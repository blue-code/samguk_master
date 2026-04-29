// Game Center / Google Play Games 통합은 1.0.0 출시 단계에서 제외됨.
// 외부 글로벌 랭킹은 ExternalLeaderboardService (Cloudflare Workers) 가 담당.
// 추후 재도입 시 games_services 패키지를 다시 추가하면 된다.

class GameServicesManager {
  static Future<bool> signIn() async => false;

  static Future<void> submitScore(int score) async {}

  static Future<bool> showLeaderboards() async => false;

  static Future<void> unlockAchievement({
    required String androidId,
    required String iosId,
    double percentComplete = 100,
  }) async {}
}
