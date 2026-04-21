import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'home_view.dart';

class ResultView extends StatelessWidget {
  const ResultView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();

    // 점수에 따른 랭크 및 배경이미지 판별
    String bgImage;
    String rankName;
    if (quizVM.score < 1000) {
      bgImage = 'assets/images/result_level1.png';
      rankName = '일개 보병';
    } else if (quizVM.score < 5000) {
      bgImage = 'assets/images/result_level2.png';
      rankName = '천하 맹장';
    } else {
      bgImage = 'assets/images/result_level3.png';
      rankName = '위대한 군주';
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
              Share.share(
                '나의 삼국지 덕력 점수는 ${quizVM.score}점!\n나의 계급은 [$rankName]! 과연 당신은 나를 넘을 수 있을까?\n\n#삼국지덕력고사 #삼국지퀴즈 #모바일게임'
              );
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
                  'GAME OVER',
                  style: GoogleFonts.notoSans(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 당신의 랭크 표시
              ZoomIn(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  '당신의 계급: $rankName',
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
                        '최종 점수',
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
                    '🎉 신기록 달성! 🎉',
                    style: GoogleFonts.notoSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                )
              else
                Text(
                  '최고 점수: ${quizVM.bestScore}',
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
                  Navigator.pop(context); // 돌아가기
                },
                child: Text(
                  '메인으로 돌아가기',
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
                        '📝 오답 노트',
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
                                          '정답: ${wq.choices[wq.answerIndex]}',
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
