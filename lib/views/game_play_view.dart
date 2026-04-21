import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'result_view.dart';

class GamePlayView extends StatelessWidget {
  const GamePlayView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();
    final question = quizVM.currentQuestion;

    if (quizVM.isGameOver) {
      // 렌더링 프레임 이후 화면 전환을 위해 Future.microtask 사용
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResultView()),
        );
      });
      return const Scaffold(backgroundColor: Color(0xFF1E1E1E));
    }

    if (question == null) return const Scaffold(backgroundColor: Color(0xFF1E1E1E));

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(
          '문제 ${quizVM.currentIndex + 1} / ${quizVM.currentQuizQuestions.length}',
          style: GoogleFonts.notoSans(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 타이머 게이지바
            LinearProgressIndicator(
              value: quizVM.timeLeft / 15.0,
              backgroundColor: Colors.white24,
              color: quizVM.timeLeft > 5 ? Colors.amber : Colors.redAccent,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 30),
            
            // 문제 카테고리/난이도 뱃지
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    question.category,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '난이도: ${question.difficulty}',
                  style: const TextStyle(color: Colors.amberAccent),
                )
              ],
            ),
            const SizedBox(height: 20),
            
            // 질문 내용
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  question.question,
                  style: GoogleFonts.notoSans(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // 보기 목록
            Expanded(
              flex: 3,
              child: ListView.builder(
                itemCount: question.choices.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                      onPressed: () {
                        context.read<QuizViewModel>().submitAnswer(index);
                      },
                      child: Text(
                        '${index + 1}. ${question.choices[index]}',
                        style: GoogleFonts.notoSans(fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
