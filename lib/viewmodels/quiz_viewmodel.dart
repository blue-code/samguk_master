import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/local_store.dart';
import '../services/ad_service.dart';
import '../services/game_services_manager.dart';
import '../services/external_leaderboard_service.dart';
import '../services/sound_manager.dart';
import 'dart:async';

/// 난이도 단계 정복(Conquest) 모델
/// - 1단계 Easy: 은행의 80%, 2단계 Medium: 90%, 3단계 Hard: 100%를 "맞힌 고유 문항"으로 정복
/// - 맞힌 문항 ID는 기기에 영구 저장되어 여러 판에 걸쳐 누적
/// - 오답/시간초과는 실패가 아니라 풀에 재투입되어 다시 출제
/// - 단계 정복 순간 화면 연출, Hard 100% 달성 = 천하통일(1등)
class QuizViewModel extends ChangeNotifier {
  // ─── 단계 정의 ──────────────────────────────────
  static const List<String> stageDifficulties = ['Easy', 'Medium', 'Hard'];
  /// 각 단계를 정복한 것으로 인정하는 문제은행 소화 비율.
  /// Hard 가 1.0 이면 모르는 문항 하나가 정복을 영구 차단하므로 낮췄다.
  static const List<double> stageRatios = [0.7, 0.75, 0.85];

  /// 최상위 계급/업적 임계 점수(한 판 최대 3000 기준).
  static const int topRankScore = 2400;
  static const int stageCount = 3;

  // 한 판(세션)에 출제하는 문항 수 — 결과/광고/리더보드 비트 유지용
  static const int sessionLength = 15;
  static const int questionSeconds = 15;

  // ─── 데이터 ──────────────────────────────────
  final List<Question> _allQuestions = [];
  final Map<String, List<Question>> _byDifficulty = {
    'Easy': [],
    'Medium': [],
    'Hard': [],
  };

  // 정복 진행도(영구): 난이도별 맞힌 고유 문항 ID
  final Map<String, Set<int>> _mastered = {
    'Easy': <int>{},
    'Medium': <int>{},
    'Hard': <int>{},
  };

  // ─── 세션 상태 ──────────────────────────────────
  List<Question> _sessionQueue = [];
  Question? _currentQuestion;
  int _sessionServed = 0; // 이번 판에서 출제한 문항 수
  int _sessionCorrect = 0;

  int _score = 0;
  int _combo = 0;
  int _timeLeft = questionSeconds;
  Timer? _timer;
  bool _isGameOver = false;
  bool _isLoading = true;
  bool _isDemoResult = false; // 스크린샷용 데모 점수 → 랭킹 제출 금지
  bool _showFeedback = false;
  bool _isLastAnswerCorrect = false;

  // 단계 정복 연출
  bool _showStageClear = false;
  int _clearedStageIndex = -1; // 방금 정복한 단계(0..2)
  bool _isFullConquest = false; // 이번 판에서 Hard까지 완전 정복

  // 기록
  int _bestScore = 0;
  bool _isNewRecord = false;
  LeaderboardSubmission? _leaderboardSubmission;
  final List<Question> _wrongQuestions = [];

  /// 이전 판에서 틀려 다음 판에 우선 출제할 문항 ID (세션 간 이월).
  Set<int> _reviewIds = <int>{};

  /// 이번 판에서 리워드 광고로 콤보를 살린 횟수 — 판당 1회로 제한.
  bool _comboRevivedThisSession = false;

  /// 50:50 힌트로 가려진 선택지 인덱스. 문항이 바뀌면 비워진다.
  Set<int> _hiddenChoices = <int>{};
  bool _hintUsedThisQuestion = false;

  /// 결과 화면에서 리워드 광고로 점수를 2배로 만들었는지.
  bool _scoreDoubled = false;

  /// 직전 오답 시점의 콤보 — 부활 시 되돌려 놓기 위해 보관한다.
  int _comboBeforeWrong = 0;

  /// 콤보 부활 제안을 띄우고 사용자의 결정을 기다리는 중.
  /// 이 동안에는 다음 문항으로 자동 진행하지 않는다.
  bool _awaitingRevive = false;

  // ─── 게터 ──────────────────────────────────
  Question? get currentQuestion => _currentQuestion;
  int get score => _score;
  int get combo => _combo;
  int get timeLeft => _timeLeft;
  bool get isGameOver => _isGameOver;
  bool get isLoading => _isLoading;
  bool get showFeedback => _showFeedback;
  bool get isLastAnswerCorrect => _isLastAnswerCorrect;

  int get sessionServed => _sessionServed;
  int get sessionCorrect => _sessionCorrect;

  bool get showStageClear => _showStageClear;
  int get clearedStageIndex => _clearedStageIndex;
  bool get isFullConquest => _isFullConquest;

  int get bestScore => _bestScore;
  bool get isNewRecord => _isNewRecord;
  LeaderboardSubmission? get leaderboardSubmission => _leaderboardSubmission;
  List<Question> get wrongQuestions => _wrongQuestions;
  Set<int> get hiddenChoices => _hiddenChoices;
  bool get scoreDoubled => _scoreDoubled;
  int get reviewCount => _reviewIds.length;

  /// 힌트 버튼을 띄울 수 있는 상태인가 (문항당 1회, 2지선다 이상일 때만).
  bool get canUseHint => !_hintUsedThisQuestion && !_showFeedback;

  /// 콤보 부활 제안을 띄울 수 있는가 (판당 1회, 콤보가 쌓여 있었을 때만).
  bool get canReviveCombo => !_comboRevivedThisSession && _comboBeforeWrong >= 3;
  int get comboBeforeWrong => _comboBeforeWrong;
  bool get awaitingRevive => _awaitingRevive;

  bool get isMuted => SoundManager.isMuted;

  // ─── 정복 진행 계산 ──────────────────────────────────
  int bankSize(int stage) => _byDifficulty[stageDifficulties[stage]]!.length;
  int requiredFor(int stage) => (bankSize(stage) * stageRatios[stage]).ceil();
  int masteredCount(int stage) =>
      _mastered[stageDifficulties[stage]]!.length.clamp(0, requiredFor(stage));
  int masteredRaw(int stage) => _mastered[stageDifficulties[stage]]!.length;
  bool isStageCleared(int stage) => masteredRaw(stage) >= requiredFor(stage);

  /// 아직 정복하지 못한 가장 낮은 단계(전부 정복 시 마지막 단계 반환)
  int get activeStage {
    for (int i = 0; i < stageCount; i++) {
      if (!isStageCleared(i)) return i;
    }
    return stageCount - 1;
  }

  int get clearedStageCount {
    int c = 0;
    for (int i = 0; i < stageCount; i++) {
      if (isStageCleared(i)) c++;
    }
    return c;
  }

  bool get isAllConquered => clearedStageCount >= stageCount;

  /// 현재 진행 중인 단계(연출/헤더 표시용)
  int get currentStage => _currentQuestion != null
      ? stageDifficulties.indexOf(_currentQuestion!.difficulty)
      : activeStage;

  Future<void> toggleMute() async {
    await SoundManager.toggleMute();
    notifyListeners();
  }

  QuizViewModel() {
    loadInitData();
  }

  Future<void> loadInitData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final String response =
          await rootBundle.loadString('assets/data/questions.json');
      final data = await json.decode(response);
      _allQuestions
        ..clear()
        ..addAll((data as List).map((i) => Question.fromJson(i)));

      for (final list in _byDifficulty.values) {
        list.clear();
      }
      for (final q in _allQuestions) {
        (_byDifficulty[q.difficulty] ?? _byDifficulty['Easy']!).add(q);
      }

      _bestScore = await LocalStore.getBestScore();
      for (final d in stageDifficulties) {
        _mastered[d] = await LocalStore.getMasteredIds(d);
      }
      _reviewIds = await LocalStore.getWrongIds();

      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
    _isLoading = false;
    SoundManager.playLobbyBgm();
    notifyListeners();
  }

  // 스크린샷 자동화용: 결과 화면 진입을 위한 데모 상태 주입
  void setDemoResultState({int score = 5500, int combo = 8}) {
    _score = score;
    _combo = combo;
    _isDemoResult = true;
    _sessionCorrect = 12;
    _sessionServed = sessionLength;
    _isGameOver = true;
    _isLoading = false;
    _bestScore = score;
    _isNewRecord = true;
    notifyListeners();
  }

  /// 한 판 시작 (기존 startQuiz 대체)
  void startSession() {
    _score = 0;
    _combo = 0;
    _isDemoResult = false;
    _comboRevivedThisSession = false;
    _scoreDoubled = false;
    _comboBeforeWrong = 0;
    _sessionServed = 0;
    _sessionCorrect = 0;
    _isNewRecord = false;
    _leaderboardSubmission = null;
    _isGameOver = false;
    _showFeedback = false;
    _showStageClear = false;
    _clearedStageIndex = -1;
    _isFullConquest = false;
    _wrongQuestions.clear();

    _buildSessionQueue(activeStage);
    SoundManager.playInGameBgm();
    _presentNext();
    notifyListeners();
  }

  void _buildSessionQueue(int stage) {
    if (isAllConquered) {
      // 완전 정복 후 자유 도전(점수 전용) — 전 난이도 무작위
      _sessionQueue = List<Question>.from(_allQuestions)..shuffle();
      return;
    }
    final diff = stageDifficulties[stage];
    final mastered = _mastered[diff]!;
    final pool = _byDifficulty[diff]!
        .where((q) => !mastered.contains(q.id))
        .toList()
      ..shuffle();

    // 이전 판에서 틀린 문항을 앞으로 — 간이 복습(spaced repetition) 효과.
    final review = pool.where((q) => _reviewIds.contains(q.id)).toList();
    final rest = pool.where((q) => !_reviewIds.contains(q.id)).toList();
    _sessionQueue = [...review, ...rest];
  }

  void _presentNext() {
    if (_sessionQueue.isEmpty) {
      _buildSessionQueue(activeStage);
    }
    if (_sessionQueue.isEmpty) {
      // 출제할 문항이 없음(이론상 완전 정복 상태) → 판 종료
      _endSession();
      return;
    }
    _currentQuestion = _sessionQueue.removeAt(0);
    _hiddenChoices = <int>{};
    _hintUsedThisQuestion = false;
    _sessionServed++;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = questionSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        _timer?.cancel();
        submitAnswer(-1); // 시간 초과
      }
    });
  }

  void submitAnswer(int selectedIndex) {
    if (_showFeedback) return;
    _timer?.cancel();

    final q = _currentQuestion;
    _isLastAnswerCorrect = (q != null && q.answerIndex == selectedIndex);

    bool justClearedStage = false;
    int answeredStage = q != null ? stageDifficulties.indexOf(q.difficulty) : -1;

    if (_isLastAnswerCorrect) {
      HapticFeedback.lightImpact();
      SoundManager.playCorrect();
      _combo++;
      _score += (10 + _timeLeft) * _combo; // 콤보 보너스
      _sessionCorrect++;

      // 복습 대기열에서 졸업
      if (q != null && _reviewIds.remove(q.id)) {
        LocalStore.saveWrongIds(_reviewIds);
      }

      if (q != null && answeredStage >= 0) {
        final set = _mastered[q.difficulty]!;
        final wasCleared = isStageCleared(answeredStage);
        if (set.add(q.id)) {
          LocalStore.saveMasteredIds(q.difficulty, set); // 비동기 영구 저장
        }
        justClearedStage = !wasCleared && isStageCleared(answeredStage);
      }

      if (_combo == 10) {
        GameServicesManager.unlockAchievement(
          androidId: "achievement_combo_master",
          iosId: "com.kent.quiz.achievements.combo_master",
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      SoundManager.playWrong();
      _comboBeforeWrong = _combo;
      _combo = 0;
      // 광고가 준비돼 있을 때만 흐름을 멈춘다. 준비가 안 됐는데 멈추면
      // 띄울 UI 가 없어 게임이 그대로 정지한다.
      _awaitingRevive = canReviveCombo && AdService.instance.isRewardedReady;
      if (q != null) {
        _wrongQuestions.add(q);
        _sessionQueue.add(q); // 틀린 문제는 풀 끝으로 재투입(다시 출제)
        // 다음 판까지 이월해 우선 출제한다.
        if (_reviewIds.add(q.id)) {
          LocalStore.saveWrongIds(_reviewIds);
        }
      }
    }

    _showFeedback = true;
    notifyListeners();

    // 콤보 부활 제안 중에는 사용자가 고를 때까지 다음 문항으로 넘어가지 않는다.
    if (_awaitingRevive) return;

    Future.delayed(const Duration(milliseconds: 1500), () {
      _advanceAfterFeedback(justClearedStage, answeredStage);
    });
  }

  /// 콤보 부활 제안에 대한 사용자의 결정. [revived] 는 광고 시청 완료 여부.
  void resolveRevive({required bool revived}) {
    if (!_awaitingRevive) return;
    _awaitingRevive = false;
    if (revived) reviveCombo();
    // 오답 경로이므로 단계 정복 연출은 발생하지 않는다.
    _advanceAfterFeedback(false, -1);
  }

  void _advanceAfterFeedback(bool justClearedStage, int answeredStage) {
    _showFeedback = false;

    if (justClearedStage) {
      _clearedStageIndex = answeredStage;
      _isFullConquest = isAllConquered;
      _timer?.cancel();
      // 정복 연출 — 효과음 + 강한 햅틱
      SoundManager.playCorrect();
      HapticFeedback.heavyImpact();
      if (_isFullConquest) HapticFeedback.vibrate();
      _showStageClear = true;
      notifyListeners();
      return;
    }

    if (_sessionServed >= sessionLength) {
      _endSession();
    } else {
      _presentNext();
    }
    notifyListeners();
  }

  /// 단계 정복 연출 후 계속하기 (다음 단계로 진입 또는 판 종료)
  void continueAfterStageClear() {
    _showStageClear = false;

    if (_isFullConquest) {
      _endSession();
      notifyListeners();
      return;
    }

    // 새 활성 단계로 큐 재구성 후 이어서 진행
    _buildSessionQueue(activeStage);
    if (_sessionServed >= sessionLength) {
      _endSession();
      notifyListeners();
    } else {
      _presentNext();
    }
  }

  Future<void> _endSession() async {
    _isGameOver = true;
    _timer?.cancel();
    HapticFeedback.vibrate();
    SoundManager.playResultBgm();

    final updated = await LocalStore.updateBestScore(_score);
    if (updated) {
      _isNewRecord = true;
      _bestScore = _score;
      GameServicesManager.submitScore(_score);
    }

    if (_score >= topRankScore) {
      GameServicesManager.unlockAchievement(
        androidId: "achievement_legendary_general",
        iosId: "com.kent.quiz.achievements.legendary_general",
      );
    }
    notifyListeners();
  }

  /// 리워드 광고 보상 ①: 방금 끊긴 콤보를 되살린다(판당 1회).
  void reviveCombo() {
    if (_comboRevivedThisSession || _comboBeforeWrong <= 0) return;
    _combo = _comboBeforeWrong;
    _comboBeforeWrong = 0;
    _comboRevivedThisSession = true;
    notifyListeners();
  }

  /// 리워드 광고 보상 ②: 오답 선택지 절반을 가린다(문항당 1회).
  void applyFiftyFiftyHint() {
    final q = _currentQuestion;
    if (q == null || _hintUsedThisQuestion) return;

    final wrongIndexes = <int>[];
    for (var i = 0; i < q.choiceCount; i++) {
      if (i != q.answerIndex) wrongIndexes.add(i);
    }
    if (wrongIndexes.length < 2) return;

    wrongIndexes.shuffle();
    _hiddenChoices = wrongIndexes.take(wrongIndexes.length ~/ 2).toSet();
    _hintUsedThisQuestion = true;
    notifyListeners();
  }

  /// 리워드 광고 보상 ③: 이번 판 점수를 2배로(판당 1회).
  /// 최고 기록과 리더보드에도 2배 점수가 반영되도록 갱신한다.
  Future<void> doubleScore() async {
    if (_scoreDoubled || !_isGameOver) return;
    _scoreDoubled = true;
    _score *= 2;

    if (await LocalStore.updateBestScore(_score)) {
      _isNewRecord = true;
      _bestScore = _score;
    }
    notifyListeners();
  }

  /// 정복 진행도 초기화 (재도전용)
  Future<void> resetConquest() async {
    await LocalStore.resetConquest(stageDifficulties);
    for (final d in stageDifficulties) {
      _mastered[d] = <int>{};
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 글로벌 리더보드 닉네임 기본값(영웅명 미설정 시).
  /// 화면에 보이는 계급(보병/맹장/군주/황제)은 정복 단계 수 기준이라 별개다.
  ///
  /// 한 판 최대 점수는 3000이므로(= (10+15) * 15*16/2) 구간을 0~3000에
  /// 4등분했다. 이전 임계값(1000/5000)은 최상위가 도달 불가였다.
  /// 실서버 38명 기준 분포: 9 / 8 / 10 / 11명.
  static String rankNameForScore(int score) {
    if (score < 800) return 'Soldier';
    if (score < 1600) return 'General';
    if (score < topRankScore) return 'Lord';
    return 'Emperor';
  }

  Future<LeaderboardSubmission?> submitExternalLeaderboardRank({
    String? nickname,
    String? locale,
  }) async {
    if (_isDemoResult) return null;

    final submission = await ExternalLeaderboardService.submitScore(
      score: _score,
      locale: locale ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      nickname: nickname ?? rankNameForScore(_score),
    );
    if (submission == null) return null;

    _leaderboardSubmission = submission;
    notifyListeners();
    return submission;
  }
}
