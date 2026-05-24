import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../l10n/app_strings.dart';

/// 단계 정복 / 천하통일 전체화면 성취 연출
class StageClearOverlay extends StatelessWidget {
  final int clearedStageIndex; // 0..2 (방금 정복한 단계)
  final bool isFullConquest;
  final AppStrings l10n;
  final VoidCallback onContinue;

  const StageClearOverlay({
    Key? key,
    required this.clearedStageIndex,
    required this.isFullConquest,
    required this.l10n,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final level = (clearedStageIndex + 1).clamp(1, 3);
    final emblem = 'assets/images/result_level$level.png';
    final title = isFullConquest ? l10n.fullConquest : l10n.stageClear;
    final accent = isFullConquest ? Colors.amberAccent : Colors.amber;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.88),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 정복한 단계 라벨
                  FadeInDown(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      isFullConquest
                          ? l10n.stageName(3)
                          : l10n.stageName(clearedStageIndex + 1),
                      style: GoogleFonts.notoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // 계급 엠블럼
                  ZoomIn(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.55),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          emblem,
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 타이틀
                  ZoomIn(
                    delay: const Duration(milliseconds: 250),
                    duration: const Duration(milliseconds: 500),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: GoogleFonts.eastSeaDokdo(
                          fontSize: 88,
                          color: accent,
                          letterSpacing: 2,
                          shadows: const [
                            Shadow(
                              blurRadius: 16,
                              color: Colors.black,
                              offset: Offset(2, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // 계속 버튼
                  Pulse(
                    infinite: true,
                    duration: const Duration(milliseconds: 1400),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 44,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: onContinue,
                      child: Text(
                        isFullConquest ? l10n.viewResult : l10n.nextStage,
                        style: GoogleFonts.notoSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
