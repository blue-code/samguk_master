import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../services/locale_provider.dart';
import '../services/ad_service.dart';
import '../l10n/app_strings.dart';
import 'result_view.dart';
import 'stage_clear_overlay.dart';

class GamePlayView extends StatefulWidget {
  const GamePlayView({Key? key}) : super(key: key);

  @override
  State<GamePlayView> createState() => _GamePlayViewState();
}

class _GamePlayViewState extends State<GamePlayView> {
  bool _navigating = false;

  void _goToResult() {
    if (_navigating) return;
    _navigating = true;
    AdService.instance.showInterstitial(onClosed: () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResultView()),
        );
      }
    });
  }

  /// 리워드 광고를 보여주고, 끝까지 본 경우에만 [onEarned] 를 실행한다.
  void _watchAdThen(VoidCallback onEarned) {
    AdService.instance.showRewarded(
      onEarned: () {
        if (mounted) onEarned();
      },
      onClosed: () {},
    );
  }

  Widget _rewardChip({
    required IconData icon,
    required String label,
    required String adLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.amber,
          side: const BorderSide(color: Colors.amber),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          '$label · $adLabel',
          style: GoogleFonts.notoSans(fontSize: 13),
        ),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();
    final question = quizVM.currentQuestion;

    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppStrings.of(localeProvider.locale.languageCode);

    if (quizVM.isGameOver) {
      Future.microtask(_goToResult);
      return const Scaffold(backgroundColor: Color(0xFF1E1E1E));
    }

    if (question == null) {
      return const Scaffold(backgroundColor: Color(0xFF1E1E1E));
    }

    final lang = localeProvider.locale.languageCode;
    final categoryText = question.getCategory(lang);
    final questionText = question.getQuestion(lang);
    final choices = question.getChoices(lang);
    final stage = quizVM.currentStage;
    final mastered = quizVM.masteredCount(stage);
    final required = quizVM.requiredFor(stage);

    String bgImage = 'assets/images/story_bg.png';
    final koCategory = question.categoryMap['ko'] ?? '';
    if (koCategory.contains('전투')) {
      bgImage = 'assets/images/battle_bg.png';
    } else if (koCategory.contains('인물')) {
      bgImage = 'assets/images/character_bg.png';
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(
              Colors.black87,
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
                      '${quizVM.sessionServed}/${QuizViewModel.sessionLength}',
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: Text(
                        '${l10n.stageName(quizVM.currentStage + 1)} · ${l10n.difficultyName(question.difficulty)}',
                        style: GoogleFonts.notoSans(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                                    '${quizVM.combo} ${l10n.combo}',
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
                          LinearProgressIndicator(
                            value: quizVM.timeLeft / 15.0,
                            backgroundColor: Colors.white24,
                            color: quizVM.timeLeft > 5
                                ? Colors.amber
                                : Colors.redAccent,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 12),
                          // 현재 단계 정복도
                          Row(
                            children: [
                              Text(
                                '${l10n.conquestProgress} ',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: required > 0 ? mastered / required : 0.0,
                                  backgroundColor: Colors.white12,
                                  color: Colors.amberAccent,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$mastered/$required',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) {
                                final offsetAnimation =
                                    Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    );

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                              child: SingleChildScrollView(
                                key: ValueKey<int>(quizVM.sessionServed),
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
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
                                            categoryText,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${l10n.difficulty}: ${l10n.difficultyName(question.difficulty)}',
                                          style: const TextStyle(
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        questionText,
                                        style: GoogleFonts.notoSans(
                                          fontSize: 24,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // 리워드 광고 ① 50:50 힌트 (문항당 1회)
                                    if (quizVM.canUseHint &&
                                        AdService.instance.isRewardedReady)
                                      _rewardChip(
                                        icon: Icons.lightbulb_outline,
                                        label: l10n.hintFiftyFifty,
                                        adLabel: l10n.watchAdSuffix,
                                        onTap: () => _watchAdThen(
                                          context
                                              .read<QuizViewModel>()
                                              .applyFiftyFiftyHint,
                                        ),
                                      ),
                                    ...List.generate(choices.length, (
                                      index,
                                    ) {
                                      // 50:50 힌트로 가려진 오답은 비활성 표시
                                      final hidden =
                                          quizVM.hiddenChoices.contains(index);
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
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              side: const BorderSide(
                                                color: Colors.white24,
                                              ),
                                            ),
                                          ),
                                          onPressed:
                                              quizVM.showFeedback || hidden
                                              ? null
                                              : () {
                                                  context
                                                      .read<QuizViewModel>()
                                                      .submitAnswer(index);
                                                },
                                          child: Opacity(
                                            opacity: hidden ? 0.25 : 1.0,
                                            child: Text(
                                              '${index + 1}. ${choices[index]}',
                                              style: GoogleFonts.notoSans(
                                                fontSize: 18,
                                                height: 1.3,
                                                decoration: hidden
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (quizVM.showFeedback)
                      Container(
                        color: Colors.transparent,
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
                    // 리워드 광고 ② 콤보 부활 — 오답 직후, 판당 1회.
                    // 광고가 준비된 경우에만 awaitingRevive 가 켜진다.
                    if (quizVM.awaitingRevive)
                      Container(
                        color: Colors.black87,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${l10n.combo} ${quizVM.comboBeforeWrong}',
                              style: GoogleFonts.notoSans(
                                fontSize: 28,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.play_circle_outline),
                              label: Text(
                                '${l10n.reviveCombo} · ${l10n.watchAdSuffix}',
                                style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                final vm = context.read<QuizViewModel>();
                                AdService.instance.showRewarded(
                                  onEarned: () =>
                                      vm.resolveRevive(revived: true),
                                  onClosed: () {
                                    // 도중에 닫았으면 보상 없이 진행
                                    vm.resolveRevive(revived: false);
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context
                                  .read<QuizViewModel>()
                                  .resolveRevive(revived: false),
                              child: Text(
                                l10n.noThanks,
                                style: GoogleFonts.notoSans(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (quizVM.showStageClear)
                      StageClearOverlay(
                        clearedStageIndex: quizVM.clearedStageIndex,
                        isFullConquest: quizVM.isFullConquest,
                        l10n: l10n,
                        onContinue: () => context
                            .read<QuizViewModel>()
                            .continueAfterStageClear(),
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
