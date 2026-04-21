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
                backgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeView()),
                  (route) => false,
                );
              },
              child: const Text('처음으로'),
            ),
          ],
        ),
      ),
    );
  }
}
