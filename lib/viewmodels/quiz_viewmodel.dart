import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/local_store.dart';
import '../services/game_services_manager.dart';
import '../services/external_leaderboard_service.dart';
import '../services/sound_manager.dart';
import 'dart:async';

class QuizViewModel extends ChangeNotifier {
  List<Question> _allQuestions = [];
  List<Question> _currentQuizQuestions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _timeLeft = 15; // 15 seconds per question
  Timer? _timer;
  bool _isGameOver = false;
  bool _isLoading = true;
  bool _showFeedback = false;
  bool _isLastAnswerCorrect = false;

  // 게임적 요소
  int _lives = 3;
  int _combo = 0;

  // 로컬 저장소 최고기록
  int _bestScore = 0;
  bool _isNewRecord = false;
  LeaderboardSubmission? _leaderboardSubmission;

  // [NEW] 오답 노트 리스트
  List<Question> _wrongQuestions = [];

  List<Question> get currentQuizQuestions => _currentQuizQuestions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int get timeLeft => _timeLeft;
  bool get isGameOver => _isGameOver;
  bool get isLoading => _isLoading;
  bool get showFeedback => _showFeedback;
  bool get isLastAnswerCorrect => _isLastAnswerCorrect;
  int get lives => _lives;
  int get combo => _combo;
  int get bestScore => _bestScore;
  bool get isNewRecord => _isNewRecord;
  LeaderboardSubmission? get leaderboardSubmission => _leaderboardSubmission;
  List<Question> get wrongQuestions => _wrongQuestions;

  // 음소거 상태 UI 바인딩용
  bool get isMuted => SoundManager.isMuted;

  Future<void> toggleMute() async {
    await SoundManager.toggleMute();
    notifyListeners();
  }

  Question? get currentQuestion {
    if (_currentQuizQuestions.isEmpty ||
        _currentIndex >= _currentQuizQuestions.length)
      return null;
    return _currentQuizQuestions[_currentIndex];
  }

  QuizViewModel() {
    loadInitData();
  }

  Future<void> loadInitData() async {
    _isLoading = true;
    notifyListeners();
    try {
      // JSON 파싱
      final String response = await rootBundle.loadString(
        'assets/data/questions.json',
      );
      final data = await json.decode(response);
      _allQuestions = (data as List).map((i) => Question.fromJson(i)).toList();

      // 로컬 최고 점수 캐싱
      _bestScore = await LocalStore.getBestScore();

      // 멋진 로딩 시스템을 보여주기 위한 강제 지연 (게임성 향상)
      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      print("Error loading data: $e");
    }
    _isLoading = false;
    SoundManager.playLobbyBgm(); // 로딩 완료 후 로비 브금 재생
    notifyListeners();
  }

  void startQuiz({int questionCount = 20}) {
    _allQuestions.shuffle();
    _currentQuizQuestions = _allQuestions.take(questionCount).toList();
    _currentIndex = 0;
    _score = 0;
    _lives = 3;
    _combo = 0;
    _isNewRecord = false;
    _leaderboardSubmission = null;
    _isGameOver = false;
    _showFeedback = false;
    _wrongQuestions.clear(); // 초기화

    SoundManager.playInGameBgm(); // 퀴즈 시작과 함께 인게임 브금 재생
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        _timer?.cancel();
        submitAnswer(-1); // Time's up
      }
    });
  }

  void submitAnswer(int selectedIndex) {
    if (_showFeedback) return; // 이미 결과 표시 중이면 무시
    _timer?.cancel();

    _isLastAnswerCorrect =
        (currentQuestion != null &&
        currentQuestion!.answerIndex == selectedIndex);

    // 타격감 효과음 & 햅틱(진동) 재생
    if (_isLastAnswerCorrect) {
      HapticFeedback.lightImpact(); // 정답 시 가볍고 경쾌한 진동
      SoundManager.playCorrect();
      _combo++;
      _score += (10 + _timeLeft) * _combo; // 콤보 보너스 배수 적용

      // [업적] 연속 정답(콤보) 달성 확인
      if (_combo == 10) {
        GameServicesManager.unlockAchievement(
          androidId: "achievement_combo_master",
          iosId: "com.kent.quiz.achievements.combo_master",
        );
      }
    } else {
      HapticFeedback.heavyImpact(); // 오답 시 묵직하고 강렬한 진동
      SoundManager.playWrong();
      _combo = 0;
      _lives--;
      if (currentQuestion != null) {
        _wrongQuestions.add(currentQuestion!); // 오답 저장
      }
    }

    _showFeedback = true;
    notifyListeners();

    // 1.5초 후 다음 로직 진행
    Future.delayed(const Duration(milliseconds: 1500), () async {
      _showFeedback = false;

      if (_lives <= 0 || _currentIndex >= _currentQuizQuestions.length - 1) {
        // 게임 오버
        _isGameOver = true;
        HapticFeedback.vibrate(); // 게임오버 시 긴 진동
        SoundManager.playResultBgm(); // 종료 시 결과 랭킹 브금 재생

        // 최고 점수 갱신 확인
        bool updated = await LocalStore.updateBestScore(_score);
        if (updated) {
          _isNewRecord = true;
          _bestScore = _score;
          // 글로벌 랭킹 플랫폼(Game Center / Google Play)에 점수 업로드
          GameServicesManager.submitScore(_score);
        }

        // 닉네임은 ResultView에서 PlayerProfileProvider와 함께 호출

        // [업적] 고득점 달성 확인
        if (_score >= 5000) {
          GameServicesManager.unlockAchievement(
            androidId: "achievement_legendary_general",
            iosId: "com.kent.quiz.achievements.legendary_general",
          );
        }
      } else {
        _currentIndex++;
        _startTimer();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String rankNameForScore(int score) {
    if (score < 1000) return 'Soldier';
    if (score < 5000) return 'General';
    return 'Lord';
  }

  Future<LeaderboardSubmission?> submitExternalLeaderboardRank({
    String? nickname,
    String? locale,
  }) async {
    final submission = await ExternalLeaderboardService.submitScore(
      score: _score,
      locale:
          locale ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      nickname: nickname ?? rankNameForScore(_score),
    );
    if (submission == null) return null;

    _leaderboardSubmission = submission;
    notifyListeners();
    return submission;
  }
}
