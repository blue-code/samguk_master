import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../services/locale_provider.dart';
import '../l10n/app_strings.dart';
import 'result_view.dart';

class GamePlayView extends StatelessWidget {
  const GamePlayView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();
    final question = quizVM.currentQuestion;

    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppStrings.of(localeProvider.locale.languageCode);

    if (quizVM.isGameOver) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResultView()),
        );
      });
      return const Scaffold(backgroundColor: Color(0xFF1E1E1E));
    }

    if (question == null)
      return const Scaffold(backgroundColor: Color(0xFF1E1E1E));

    String bgImage = 'assets/images/story_bg.png';
    if (question.category.contains('전투')) {
      bgImage = 'assets/images/battle_bg.png';
    } else if (question.category.contains('인물')) {
      bgImage = 'assets/images/character_bg.png';
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(
              Colors.black87, // 블렌딩 모드로 텍스트 가독성 확보
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${quizVM.currentIndex + 1}/${quizVM.currentQuizQuestions.length}',
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: List.generate(3, (index) {
                        return Icon(
                          index < quizVM.lives
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.redAccent,
                          size: 24,
                        );
                      }),
                    ),
                  ],
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 점수 및 콤보 표시
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Text(
                                '${l10n.score}: ${quizVM.score}',
                                style: GoogleFonts.notoSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (quizVM.combo > 1)
                                Pulse(
                                  infinite: true,
                                  child: Text(
                                    '${quizVM.combo} ${l10n.combo} 🔥',
                                    style: GoogleFonts.notoSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 타이머 게이지바
                          LinearProgressIndicator(
                            value: quizVM.timeLeft / 15.0,
                            backgroundColor: Colors.white24,
                            color: quizVM.timeLeft > 5
                                ? Colors.amber
                                : Colors.redAccent,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 30),

                          Expanded(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 문제 뱃지
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white12,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Text(
                                          question.category,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${l10n.difficulty}: ${question.difficulty}',
                                        style: const TextStyle(
                                          color: Colors.amberAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // 질문
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      question.question,
                                      style: GoogleFonts.notoSans(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // 보기
                                  ...List.generate(question.choices.length, (
                                    index,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white12,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 20,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          minimumSize: const Size.fromHeight(
                                            56,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            side: const BorderSide(
                                              color: Colors.white24,
                                            ),
                                          ),
                                        ),
                                        onPressed: quizVM.showFeedback
                                            ? null
                                            : () {
                                                context
                                                    .read<QuizViewModel>()
                                                    .submitAnswer(index);
                                              },
                                        child: Text(
                                          '${index + 1}. ${question.choices[index]}',
                                          style: GoogleFonts.notoSans(
                                            fontSize: 18,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 피드백 오버레이 (자극적인 애니메이션)
                    if (quizVM.showFeedback)
                      Container(
                        color: Colors
                            .transparent, // Background container handled outer layer
                        alignment: Alignment.center,
                        child: quizVM.isLastAnswerCorrect
                            ? ZoomIn(
                                duration: const Duration(milliseconds: 400),
                                child: Image.asset(
                                  'assets/images/correct.png',
                                  width: 300,
                                  height: 300,
                                ),
                              )
                            : ShakeY(
                                duration: const Duration(milliseconds: 400),
                                child: FadeIn(
                                  child: Image.asset(
                                    'assets/images/wrong.png',
                                    width: 300,
                                    height: 300,
                                  ),
                                ),
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
