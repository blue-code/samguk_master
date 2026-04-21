import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/quiz_viewmodel.dart';
import 'game_play_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: quizVM.isLoading
            ? const CircularProgressIndicator(color: Colors.amber)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '삼국지 덕력고사',
                    style: GoogleFonts.notoSans(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '당신의 삼국지 지식을 증명하세요',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'BEST SCORE: ${quizVM.bestScore}',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                  const SizedBox(height: 60),
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
                      quizVM.startQuiz(questionCount: 2); // 샘플이라 2개만
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GamePlayView()),
                      );
                    },
                    child: Text(
                      '일반 모드 (무료)',
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
