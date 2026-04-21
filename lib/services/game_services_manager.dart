import 'package:games_services/games_services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class GameServicesManager {
  static const String androidLeaderboardId = "CgkI_ANDROID_LEADERBOARD_ID"; // 추후 Google Play 발급
  static const String iosLeaderboardId = "com.kent.quiz.leaderboard"; // 추후 AppStore 발급

  /// 게임 센터 / 플레이 게임즈 로그인
  static Future<bool> signIn() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false; // 모바일 네이티브 환경이 아니면 스킵
    }
    
    try {
      final result = await GamesServices.signIn();
      print("Game Services Login Status: $result");
      return true;
    } catch (e) {
      print("Failed to sign in to Game Services: $e");
      return false;
    }
  }

  /// 랭킹 점수 등록
  static Future<void> submitScore(int score) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      final isSignedin = await GamesServices.isSignedIn;
      if (!isSignedin) {
        // 로그인이 안되어 있으면 재시도
        final success = await signIn();
        if (!success) return;
      }

      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: androidLeaderboardId,
          iOSLeaderboardID: iosLeaderboardId,
          value: score,
        ),
      );
      print("Score $score submitted successfully!");
    } catch (e) {
      print("Failed to submit score: $e");
    }
  }

  /// 리더보드 화면 띄우기
  static Future<void> showLeaderboards() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      await GamesServices.showLeaderboards(
        iOSLeaderboardID: iosLeaderboardId,
        androidLeaderboardID: androidLeaderboardId,
      );
    } catch (e) {
      print("Failed to show leaderboards: $e");
    }
  }
}
