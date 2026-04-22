import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'viewmodels/quiz_viewmodel.dart';
import 'services/sound_manager.dart';
import 'services/locale_provider.dart';
import 'services/player_profile_provider.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundManager.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizViewModel()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProfileProvider()),
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
