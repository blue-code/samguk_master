import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerCountry {
  const PlayerCountry({
    required this.code,
    required this.flag,
    required this.label,
  });

  final String code;
  final String flag;
  final String label;
}

class PlayerProfileProvider extends ChangeNotifier {
  static const String _heroNameKey = 'samguk_hero_name';
  static const String _countryCodeKey = 'samguk_country_code';

  static const List<PlayerCountry> countries = [
    PlayerCountry(code: 'KR', flag: '🇰🇷', label: 'Korea'),
    PlayerCountry(code: 'CN', flag: '🇨🇳', label: 'China'),
    PlayerCountry(code: 'JP', flag: '🇯🇵', label: 'Japan'),
    PlayerCountry(code: 'US', flag: '🇺🇸', label: 'United States'),
    PlayerCountry(code: 'GB', flag: '🇬🇧', label: 'United Kingdom'),
    PlayerCountry(code: 'AU', flag: '🇦🇺', label: 'Australia'),
    PlayerCountry(code: 'CA', flag: '🇨🇦', label: 'Canada'),
  ];

  bool _isLoaded = false;
  String _heroName = '';
  String _countryCode = 'KR';

  bool get isLoaded => _isLoaded;
  bool get isConfigured => _heroName.trim().isNotEmpty;
  String get heroName => _heroName.trim();
  String get countryCode => _countryCode;

  PlayerCountry get country => countries.firstWhere(
    (country) => country.code == _countryCode,
    orElse: () => countries.first,
  );

  String get leaderboardLocale {
    switch (_countryCode) {
      case 'KR':
        return 'ko';
      case 'CN':
        return 'zh-CN';
      case 'JP':
        return 'ja';
      case 'GB':
        return 'en-GB';
      case 'AU':
        return 'en-AU';
      case 'CA':
        return 'en-CA';
      case 'US':
      default:
        return 'en-US';
    }
  }

  PlayerProfileProvider() {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _heroName = prefs.getString(_heroNameKey) ?? '';
    _countryCode = prefs.getString(_countryCodeKey) ?? 'KR';
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveProfile({
    required String heroName,
    required String countryCode,
  }) async {
    final sanitizedName = heroName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedCountry =
        countries.any((country) => country.code == countryCode)
        ? countryCode
        : 'KR';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_heroNameKey, sanitizedName);
    await prefs.setString(_countryCodeKey, normalizedCountry);

    _heroName = sanitizedName;
    _countryCode = normalizedCountry;
    _isLoaded = true;
    notifyListeners();
  }

  void setDefaultCountryForLanguage(String languageCode) {
    if (isConfigured) return;

    switch (languageCode) {
      case 'zh':
        _countryCode = 'CN';
        break;
      case 'ja':
        _countryCode = 'JP';
        break;
      case 'en':
        _countryCode = 'US';
        break;
      case 'ko':
      default:
        _countryCode = 'KR';
        break;
    }
    notifyListeners();
  }
}
