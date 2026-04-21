import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../services/game_services_manager.dart';
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
                      quizVM.startQuiz(questionCount: 20); // 20문제 모드
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GamePlayView()),
                      );
                    },
                    child: Text(
                      '서바이벌 모드 (무료)',
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.leaderboard),
                    label: Text(
                      '글로벌 랭킹 보기',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      GameServicesManager.showLeaderboards();
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
