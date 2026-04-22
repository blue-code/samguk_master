import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../services/locale_provider.dart';
import '../services/sound_manager.dart';
import '../l10n/app_strings.dart';
import 'home_view.dart';

class ResultView extends StatefulWidget {
  const ResultView({Key? key}) : super(key: key);

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  void _showWrongNotes(BuildContext context, QuizViewModel quizVM, AppStrings l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    l10n.wrongNotes,
                    style: GoogleFonts.notoSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: quizVM.wrongQuestions.length,
                      itemBuilder: (context, index) {
                        final wq = quizVM.wrongQuestions[index];
                        return Card(
                          color: Colors.white12,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              wq.question,
                              style: GoogleFonts.notoSans(color: Colors.white, fontSize: 14),
                            ),
                            iconColor: Colors.amber,
                            collapsedIconColor: Colors.white54,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      '${l10n.correctAnswer}: ${wq.choices[wq.answerIndex]}',
                                      style: GoogleFonts.notoSans(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      wq.explanation,
                                      style: GoogleFonts.notoSans(color: Colors.white70, height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareResultImage(QuizViewModel quizVM, AppStrings l10n, String rankName, String bgImage) async {
    setState(() { _isSharing = true; });
    try {
      // 캡처용 숨겨진 위젯 생성
      final imageBytes = await _screenshotController.captureFromWidget(
        Material(
          child: Container(
            width: 1080,
            height: 1080, // 1:1 정방형 비율이 인스타그램 등 SNS 공유에 좋음
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage),
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.darken),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.gameOver,
                  style: GoogleFonts.eastSeaDokdo(fontSize: 160, color: Colors.redAccent),
                ),
                Text(
                  '${l10n.myRank}: $rankName',
                  style: GoogleFonts.notoSans(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.amber, width: 3),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.finalScore,
                        style: GoogleFonts.notoSans(fontSize: 40, color: Colors.white70),
                      ),
                      Text(
                        '${quizVM.score}',
                        style: GoogleFonts.notoSans(
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                Text(
                  l10n.appTitle,
                  style: GoogleFonts.eastSeaDokdo(fontSize: 80, color: Colors.amberAccent),
                ),
              ],
            ),
          ),
        ),
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/result.png').create();
      await imagePath.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: l10n.shareText(quizVM.score, rankName),
      );
    } catch (e) {
      print('Share Error: $e');
    } finally {
      setState(() { _isSharing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppStrings.of(localeProvider.locale.languageCode);

    String bgImage;
    String rankName;
    if (quizVM.score < 1000) {
      bgImage = 'assets/images/result_level1.png';
      rankName = l10n.rankSoldier;
    } else if (quizVM.score < 5000) {
      bgImage = 'assets/images/result_level2.png';
      rankName = l10n.rankGeneral;
    } else {
      bgImage = 'assets/images/result_level3.png';
      rankName = l10n.rankLord;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _isSharing 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.ios_share, color: Colors.white, size: 28),
                onPressed: () => _shareResultImage(quizVM, l10n, rankName, bgImage),
              )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  child: Text(
                    l10n.gameOver,
                    style: GoogleFonts.eastSeaDokdo(
                      fontSize: 70,
                      color: Colors.redAccent,
                      shadows: [
                        const Shadow(
                          blurRadius: 10.0,
                          color: Colors.black,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ZoomIn(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    '${l10n.myRank}: $rankName',
                    style: GoogleFonts.notoSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ZoomIn(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.finalScore,
                          style: GoogleFonts.notoSans(fontSize: 20, color: Colors.white70),
                        ),
                        Text(
                          '${quizVM.score}',
                          style: GoogleFonts.notoSans(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (quizVM.isNewRecord)
                  Pulse(
                    infinite: true,
                    child: Text(
                      l10n.newRecord,
                      style: GoogleFonts.notoSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                    ),
                  )
                else
                  Text(
                    '${l10n.bestScore}: ${quizVM.bestScore}',
                    style: GoogleFonts.notoSans(fontSize: 18, color: Colors.white54),
                  ),
                const SizedBox(height: 40),
                
                if (quizVM.wrongQuestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amberAccent,
                        side: const BorderSide(color: Colors.amberAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book),
                      label: Text(
                        '${l10n.wrongNotes} 확인하기',
                        style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _showWrongNotes(context, quizVM, l10n),
                    ),
                  ),
                  
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    SoundManager.playLobbyBgm(); // 메인 로비 브금으로 복구
                    Navigator.pop(context); // 돌아가기
                  },
                  child: Text(
                    l10n.backToMain,
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

