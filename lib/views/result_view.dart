import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../services/locale_provider.dart';
import '../services/player_profile_provider.dart';
import '../services/sound_manager.dart';
import '../l10n/app_strings.dart';

class ResultView extends StatefulWidget {
  const ResultView({Key? key}) : super(key: key);

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final quizVM = context.read<QuizViewModel>();
      final profile = context.read<PlayerProfileProvider>();
      quizVM.submitExternalLeaderboardRank(
        nickname: profile.isConfigured ? profile.heroName : null,
        locale: profile.leaderboardLocale,
      );
    });
  }

  void _showWrongNotes(
    BuildContext context,
    QuizViewModel quizVM,
    AppStrings l10n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    l10n.wrongNotes,
                    style: GoogleFonts.notoSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: quizVM.wrongQuestions.length,
                      itemBuilder: (context, index) {
                        final wq = quizVM.wrongQuestions[index];
                        final lang = context.read<LocaleProvider>().locale.languageCode;
                        final qText = wq.getQuestion(lang);
                        final choices = wq.getChoices(lang);
                        final explText = wq.getExplanation(lang);
                        return Card(
                          color: Colors.white12,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              qText,
                              style: GoogleFonts.notoSans(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            iconColor: Colors.amber,
                            collapsedIconColor: Colors.white54,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      '${l10n.correctAnswer}: ${choices[wq.answerIndex]}',
                                      style: GoogleFonts.notoSans(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      explText,
                                      style: GoogleFonts.notoSans(
                                        color: Colors.white70,
                                        height: 1.5,
                                      ),
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
            );
          },
        );
      },
    );
  }

  Future<void> _shareResultImage(
    QuizViewModel quizVM,
    AppStrings l10n,
    String rankName,
    String bgImage,
  ) async {
    setState(() {
      _isSharing = true;
    });
    try {
      // 캡처용 숨겨진 위젯 생성
      final imageBytes = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: SizedBox.square(
            dimension: 1080,
            child: Container(
              width: 1080,
              height: 1080,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(bgImage),
                  fit: BoxFit.cover,
                  colorFilter: const ColorFilter.mode(
                    Colors.black54,
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.72),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(86, 92, 86, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.appTitle,
                            style: GoogleFonts.eastSeaDokdo(
                              fontSize: 132,
                              color: Colors.amberAccent,
                              letterSpacing: 2,
                              shadows: const [
                                Shadow(
                                  blurRadius: 18,
                                  color: Colors.black,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 52),
                        Text(
                          l10n.myRank,
                          style: GoogleFonts.notoSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            rankName,
                            style: GoogleFonts.eastSeaDokdo(
                              fontSize: 118,
                              color: Colors.amber,
                              letterSpacing: 1.5,
                              shadows: const [
                                Shadow(
                                  blurRadius: 16,
                                  color: Colors.black,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 54,
                            vertical: 34,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.62),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.92),
                              width: 3,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.finalScore,
                                style: GoogleFonts.notoSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${quizVM.score}',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 138,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 16,
                                        color: Colors.black,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (quizVM.leaderboardSubmission?.rank !=
                                  null) ...[
                                const SizedBox(height: 18),
                                Text(
                                  _rankText(
                                    l10n,
                                    quizVM.leaderboardSubmission!.rank!,
                                  ),
                                  style: GoogleFonts.notoSans(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amberAccent,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 44),
                        Text(
                          l10n
                              .shareText(quizVM.score, rankName)
                              .split('\n')
                              .first,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSans(
                            fontSize: 31,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.88),
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 1,
        targetSize: const Size.square(1080),
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File(
        '${directory.path}/samguk_result_square.png',
      ).create();
      await imagePath.writeAsBytes(imageBytes);

      await Share.shareXFiles([
        XFile(
          imagePath.path,
          name: 'samguk_result_square.png',
          mimeType: 'image/png',
        ),
      ], text: _shareText(quizVM, l10n, rankName));
    } catch (e) {
      print('Share Error: $e');
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  String _shareText(QuizViewModel quizVM, AppStrings l10n, String rankName) {
    final baseText = l10n.shareText(quizVM.score, rankName);
    final submission = quizVM.leaderboardSubmission;
    final leaderboardUrl = submission?.leaderboardUrl;

    if (submission?.rank == null || leaderboardUrl == null) {
      return baseText;
    }

    return [
      baseText,
      '',
      _rankText(l10n, submission!.rank!),
      leaderboardUrl,
    ].join('\n');
  }

  String _rankText(AppStrings l10n, int rank) {
    switch (l10n.appTitle) {
      case 'Three Kingdoms Quiz':
        return 'Global Ranking #$rank';
      case '三国英雄试炼':
        return '全球排名第 $rank 名';
      case '三国志英雄検定':
        return 'グローバルランキング $rank 位';
      default:
        return '글로벌 랭킹 ${rank}등';
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppStrings.of(localeProvider.locale.languageCode);

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
          _isSharing
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.amber,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.ios_share,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () =>
                      _shareResultImage(quizVM, l10n, rankName, bgImage),
                ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            colorFilter: const ColorFilter.mode(
              Colors.black54,
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.finalScore,
                          style: GoogleFonts.notoSans(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '${quizVM.score}',
                          style: GoogleFonts.notoSans(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (quizVM.leaderboardSubmission?.rank != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _rankText(
                              l10n,
                              quizVM.leaderboardSubmission!.rank!,
                            ),
                            style: GoogleFonts.notoSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ],
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
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      color: Colors.white54,
                    ),
                  ),
                const SizedBox(height: 40),

                if (quizVM.wrongQuestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amberAccent,
                        side: const BorderSide(color: Colors.amberAccent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book),
                      label: Text(
                        '${l10n.wrongNotes} 확인하기',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _showWrongNotes(context, quizVM, l10n),
                    ),
                  ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
