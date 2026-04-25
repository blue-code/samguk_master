import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/quiz_viewmodel.dart';
import '../services/external_leaderboard_service.dart';
import '../services/game_services_manager.dart';
import '../services/locale_provider.dart';
import '../services/player_profile_provider.dart';
import '../l10n/app_strings.dart';
import 'game_play_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _didPromptProfile = false;

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
                        const SizedBox(height: 60),
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
                            quizVM.startQuiz(questionCount: 20);
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
                      ],
                    ),
                  ),
          ),
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
