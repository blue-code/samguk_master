import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'samguk_locale';

  Locale _locale = const Locale('ko');
  Locale get locale => _locale;

  // 지원 언어 목록 및 이름 매핑
  static const Map<String, String> supportedLocales = {
    'ko': '한국어 🇰🇷',
    'en': 'English 🇺🇸',
    'zh': '中文 🇨🇳',
    'ja': '日本語 🇯🇵',
  };

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_localeKey) ?? 'ko';
    _locale = Locale(saved);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    notifyListeners();
  }
}
