import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'viewmodels/quiz_viewmodel.dart';
import 'services/sound_manager.dart';
import 'services/locale_provider.dart';
import 'services/player_profile_provider.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundManager.init();

  // 디버그 빌드 한정: dart-define으로 받은 locale·hero_name 을
  // SharedPreferences 에 미리 주입 (스크린샷 자동화용)
  if (kDebugMode) {
    const sLocale = String.fromEnvironment('SS_LOCALE');
    const sHero = String.fromEnvironment('SS_HERO');
    const sCountry = String.fromEnvironment('SS_COUNTRY');
    if (sLocale.isNotEmpty || sHero.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      if (sLocale.isNotEmpty) await prefs.setString('samguk_locale', sLocale);
      if (sHero.isNotEmpty) await prefs.setString('samguk_hero_name', sHero);
      if (sCountry.isNotEmpty) {
        await prefs.setString('samguk_country_code', sCountry);
      }
    }
  }

  // 광고 제거 권한을 먼저 읽어야 AdService 가 전면광고 프리로드 여부를
  // 올바르게 판단한다.
  await PurchaseService.instance.initialize();
  await AdService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizViewModel()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProfileProvider()),
        ChangeNotifierProvider.value(value: PurchaseService.instance),
      ],
      child: const SamgukQuizApp(),
    ),
  );
}

class SamgukQuizApp extends StatelessWidget {
  const SamgukQuizApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: '삼국지 덕력고사',
      debugShowCheckedModeBanner: false,

      // 다국어 지원 설정
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('zh'),
        Locale('ja'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        textTheme: GoogleFonts.notoSansTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const HomeView(),
    );
  }
}
