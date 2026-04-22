import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../services/locale_provider.dart';
import '../l10n/app_strings.dart';
import 'home_view.dart';

class ResultView extends StatelessWidget {
  const ResultView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppStrings.of(localeProvider.locale.languageCode);

    // 점수에 따른 랭크 및 배경이미지 판별
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
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white, size: 28),
            onPressed: () {
              Share.share(l10n.shareText(quizVM.score, rankName));
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(
              Colors.black54, // 점수와 텍스트 가독성을 위한 필터
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
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
              // 당신의 랭크 표시
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
              const SizedBox(height: 30),
              
              // 오답 노트 영역
              if (quizVM.wrongQuestions.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.wrongNotes,
                        style: GoogleFonts.notoSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: quizVM.wrongQuestions.length,
                          itemBuilder: (context, index) {
                            final wq = quizVM.wrongQuestions[index];
                            return Card(
                              color: Colors.white12,
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
                                          style: GoogleFonts.notoSans(color: Colors.white70),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}

