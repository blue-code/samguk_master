import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'home_view.dart';

class ResultView extends StatelessWidget {
  const ResultView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              quizVM.lives <= 0 ? 'GAME OVER' : '도전 완료!',
              style: GoogleFonts.notoSans(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: quizVM.lives <= 0 ? Colors.redAccent : Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (quizVM.isNewRecord)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🎉 NEW RECORD 🎉',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            Text(
              '최종 점수: ${quizVM.score}점',
              style: GoogleFonts.notoSans(
                fontSize: 28,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '현재 랭킹(최고점): ${quizVM.bestScore}점',
              style: GoogleFonts.notoSans(
                fontSize: 18,
                color: Colors.white70,
              ),
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
    );
  }
}
