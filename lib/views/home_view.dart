import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../services/external_leaderboard_service.dart';
import '../services/game_services_manager.dart';
import '../services/locale_provider.dart';
import '../services/player_profile_provider.dart';
import '../l10n/app_strings.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import 'game_play_view.dart';
import 'result_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _didPromptProfile = false;
  BannerAd? _bannerAd;
  bool _bannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // 스크린샷 자동화 시 배너 숨김 + 게임 자동 진입
    const hideAds = bool.fromEnvironment('SS_HIDE_ADS', defaultValue: false);
    const startInGame =
        bool.fromEnvironment('SS_START_IN_GAME', defaultValue: false);
    const showResult =
        bool.fromEnvironment('SS_SHOW_RESULT', defaultValue: false);
    if (showResult) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        context.read<QuizViewModel>().setDemoResultState();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResultView()),
        );
      });
    } else if (startInGame) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        context.read<QuizViewModel>().startSession();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GamePlayView()),
        );
      });
    }
    if (hideAds || PurchaseService.instance.isAdFree) return;
    final ad = AdService.instance.createBannerAd();
    ad.load().then((_) {
      if (mounted) setState(() { _bannerAd = ad; _bannerAdLoaded = true; });
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showLanguagePicker(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final l10n = AppStrings.of(localeProvider.locale.languageCode);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.languageSelect,
                style: GoogleFonts.notoSans(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...LocaleProvider.supportedLocales.entries.map((entry) {
                final isSelected =
                    localeProvider.locale.languageCode == entry.key;
                return ListTile(
                  title: Text(
                    entry.value,
                    style: GoogleFonts.notoSans(
                      color: isSelected ? Colors.amber : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.amber)
                      : null,
                  onTap: () {
                    localeProvider.setLocale(entry.key);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showProfileSheet(BuildContext context, {required bool isFirstRun}) {
    final localeProvider = context.read<LocaleProvider>();
    final profileProvider = context.read<PlayerProfileProvider>();
    final copy = _profileCopy(localeProvider.locale.languageCode);
    final controller = TextEditingController(text: profileProvider.heroName);
    String selectedCountry = profileProvider.countryCode;

    if (!profileProvider.isConfigured) {
      profileProvider.setDefaultCountryForLanguage(
        localeProvider.locale.languageCode,
      );
      selectedCountry = profileProvider.countryCode;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      isDismissible: !isFirstRun,
      enableDrag: !isFirstRun,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    copy.title,
                    style: GoogleFonts.notoSans(
                      color: Colors.amber,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    maxLength: 18,
                    textInputAction: TextInputAction.done,
                    style: GoogleFonts.notoSans(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: copy.heroName,
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    copy.country,
                    style: GoogleFonts.notoSans(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: PlayerProfileProvider.countries.map((country) {
                      final isSelected = selectedCountry == country.code;
                      return ChoiceChip(
                        label: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.amber,
                        backgroundColor: Colors.white12,
                        side: BorderSide(
                          color: isSelected ? Colors.amber : Colors.white24,
                        ),
                        onSelected: (_) {
                          setSheetState(() {
                            selectedCountry = country.code;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      await profileProvider.saveProfile(
                        heroName: name,
                        countryCode: selectedCountry,
                      );
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: Text(
                      copy.save,
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    final quizVM = context.watch<QuizViewModel>();
    final localeProvider = context.watch<LocaleProvider>();
    final profileProvider = context.watch<PlayerProfileProvider>();
    final l10n = AppStrings.of(localeProvider.locale.languageCode);

    if (!quizVM.isLoading &&
        profileProvider.isLoaded &&
        !profileProvider.isConfigured &&
        !_didPromptProfile) {
      _didPromptProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showProfileSheet(context, isFirstRun: true);
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _bannerAdLoaded && _bannerAd != null
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.amber),
            tooltip: _profileCopy(localeProvider.locale.languageCode).title,
            onPressed: () => _showProfileSheet(context, isFirstRun: false),
          ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.amber),
            tooltip: l10n.languageSelect,
            onPressed: () => _showLanguagePicker(context),
          ),
          IconButton(
            icon: Icon(
              quizVM.isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.amber,
            ),
            onPressed: () => quizVM.toggleMute(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: quizVM.isLoading
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.amber),
                        const SizedBox(height: 20),
                        Text(
                          l10n.loading,
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.appTitle,
                            style: GoogleFonts.eastSeaDokdo(
                              fontSize: 75,
                              color: Colors.amber,
                              letterSpacing: 2.0,
                              shadows: const [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black87,
                                  offset: Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${l10n.bestScore}: ${quizVM.bestScore}',
                          style: GoogleFonts.notoSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amberAccent,
                          ),
                        ),
                        if (profileProvider.isConfigured) ...[
                          const SizedBox(height: 12),
                          Text(
                            '${profileProvider.country.flag} ${profileProvider.heroName}',
                            style: GoogleFonts.notoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _buildConquestPanel(quizVM, l10n),
                        const SizedBox(height: 40),
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
                            if (!profileProvider.isConfigured) {
                              _showProfileSheet(context, isFirstRun: true);
                              return;
                            }
                            quizVM.startSession();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GamePlayView(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.startGame,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.leaderboard),
                          label: Text(
                            l10n.globalRanking,
                            style: GoogleFonts.notoSans(fontSize: 16),
                          ),
                          onPressed: () async {
                            final shown =
                                await ExternalLeaderboardService.openLeaderboard() ||
                                await GameServicesManager.showLeaderboards();
                            if (!shown && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.globalRankingUnavailable,
                                    style: GoogleFonts.notoSans(),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                        ),

                        // 광고 제거 인앱 결제.
                        // 비소모성 상품이라 '구매 복원' 노출은 App Review 요구사항이다.
                        Consumer<PurchaseService>(
                          builder: (context, purchases, _) {
                            if (purchases.isAdFree) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  l10n.adFreeActive,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 13,
                                    color: Colors.white54,
                                  ),
                                ),
                              );
                            }
                            if (!purchases.isStoreAvailable) {
                              return const SizedBox.shrink();
                            }

                            final price = purchases.formattedPrice;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.block, size: 18),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                  ),
                                  label: Text(
                                    price == null
                                        ? l10n.removeAds
                                        : '${l10n.removeAds} · $price',
                                    style: GoogleFonts.notoSans(fontSize: 14),
                                  ),
                                  onPressed: purchases.isPurchasePending
                                      ? null
                                      : purchases.buyRemoveAds,
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white38,
                                  ),
                                  onPressed: purchases.restorePurchases,
                                  child: Text(
                                    l10n.restorePurchase,
                                    style: GoogleFonts.notoSans(fontSize: 12),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _conquestRankName(AppStrings l10n, int cleared) {
    if (cleared >= 3) return l10n.rankEmperor;
    if (cleared == 2) return l10n.rankLord;
    if (cleared == 1) return l10n.rankGeneral;
    return l10n.rankSoldier;
  }

  Widget _buildConquestPanel(QuizViewModel quizVM, AppStrings l10n) {
    final rankName = _conquestRankName(l10n, quizVM.clearedStageCount);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.myRank}: $rankName',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ...List.generate(QuizViewModel.stageCount, (i) {
              final mastered = quizVM.masteredCount(i);
              final required = quizVM.requiredFor(i);
              final cleared = quizVM.isStageCleared(i);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 58,
                      child: Text(
                        l10n.stageName(i + 1),
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: required > 0 ? mastered / required : 0.0,
                        backgroundColor: Colors.white12,
                        color:
                            cleared ? Colors.greenAccent : Colors.amberAccent,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 56,
                      child: Text(
                        '$mastered/$required',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 22,
                      child: cleared
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.greenAccent,
                              size: 16,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  _ProfileCopy _profileCopy(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const _ProfileCopy(
          title: 'Hero Profile',
          heroName: 'Hero name',
          country: 'Country',
          save: 'Save',
        );
      case 'zh':
        return const _ProfileCopy(
          title: '英雄资料',
          heroName: '英雄名',
          country: '国家',
          save: '保存',
        );
      case 'ja':
        return const _ProfileCopy(
          title: '英雄プロフィール',
          heroName: '英雄名',
          country: '国',
          save: '保存',
        );
      default:
        return const _ProfileCopy(
          title: '영웅 프로필',
          heroName: '영웅 이름',
          country: '국가',
          save: '저장',
        );
    }
  }
}

class _ProfileCopy {
  const _ProfileCopy({
    required this.title,
    required this.heroName,
    required this.country,
    required this.save,
  });

  final String title;
  final String heroName;
  final String country;
  final String save;
}
