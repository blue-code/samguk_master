import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLeaderboardService {
  static const String _baseUrl = String.fromEnvironment(
    'LEADERBOARD_BASE_URL',
    defaultValue: 'https://samguk-master-leaderboard.samguk-master.workers.dev',
  );

  static const String _playerIdKey = 'leaderboard_player_id';

  static bool get isConfigured => _baseUrl.trim().isNotEmpty;

  static Uri? get leaderboardUri {
    if (!isConfigured) return null;
    return Uri.parse(_baseUrl).replace(path: '/');
  }

  static Future<bool> openLeaderboard() async {
    final uri = leaderboardUri;
    if (uri == null) return false;

    try {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to open leaderboard: $e');
      return false;
    }
  }

  static Future<LeaderboardSubmission?> submitScore({
    required int score,
    required String locale,
    String? nickname,
  }) async {
    if (!isConfigured || score < 0) return null;

    try {
      final playerId = await _playerId();
      final endpoint = Uri.parse(_baseUrl).replace(path: '/api/scores');
      final response = await http
          .post(
            endpoint,
            headers: const {
              'content-type': 'application/json; charset=utf-8',
              'accept': 'application/json',
            },
            body: jsonEncode({
              'playerId': playerId,
              'nickname': nickname ?? _nicknameFromPlayerId(playerId),
              'score': score,
              'locale': locale,
              'platform': defaultTargetPlatform.name,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      return LeaderboardSubmission(
        rank: decoded['rank'] is int ? decoded['rank'] as int : null,
        score: decoded['score'] is int ? decoded['score'] as int : score,
        leaderboardUrl: leaderboardUri.toString(),
      );
    } catch (e) {
      debugPrint('Failed to submit external leaderboard score: $e');
      return null;
    }
  }

  static String fallbackNickname() {
    return _nicknameFromPlayerId('hero');
  }

  static Future<String> _playerId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_playerIdKey);
    if (saved != null && saved.isNotEmpty) return saved;

    final generated = _generatePlayerId();
    await prefs.setString(_playerIdKey, generated);
    return generated;
  }

  static String _generatePlayerId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _nicknameFromPlayerId(String playerId) {
    final suffix = playerId.length >= 6
        ? playerId.substring(playerId.length - 6).toUpperCase()
        : playerId.toUpperCase();
    return 'Hero $suffix';
  }
}

class LeaderboardSubmission {
  const LeaderboardSubmission({
    required this.rank,
    required this.score,
    required this.leaderboardUrl,
  });

  final int? rank;
  final int score;
  final String leaderboardUrl;
}
