import 'package:games_services/games_services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class GameServicesManager {
  static const String androidLeaderboardId =
      "CgkI_ANDROID_LEADERBOARD_ID"; // Google Play leaderboard ID
  static const String iosLeaderboardId =
      "com.kent.quiz.leaderboard"; // App Store leaderboard ID

  static Future<bool> signIn() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    try {
      final result = await GamesServices.signIn();
      print("Game Services Login Status: $result");
      return await GamesServices.isSignedIn;
    } catch (e) {
      print("Failed to sign in to Game Services: $e");
      return false;
    }
  }

  static Future<void> submitScore(int score) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      final isSignedin = await GamesServices.isSignedIn;
      if (!isSignedin) {
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

  static Future<bool> showLeaderboards() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return false;

    try {
      final isSignedin = await GamesServices.isSignedIn;
      if (!isSignedin) {
        final success = await signIn();
        if (!success) return false;
      }

      await GamesServices.showLeaderboards(
        iOSLeaderboardID: iosLeaderboardId,
        androidLeaderboardID: androidLeaderboardId,
      );
      return true;
    } catch (e) {
      print("Failed to show leaderboards: $e");
      return false;
    }
  }

  static Future<void> unlockAchievement({
    required String androidId,
    required String iosId,
    double percentComplete = 100,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      final isSignedin = await GamesServices.isSignedIn;
      if (!isSignedin) {
        final success = await signIn();
        if (!success) return;
      }

      await GamesServices.unlock(
        achievement: Achievement(
          androidID: androidId,
          iOSID: iosId,
          percentComplete: percentComplete,
        ),
      );
      print("Achievement unlocked: $androidId / $iosId");
    } catch (e) {
      print("Failed to unlock achievement: $e");
    }
  }
}
