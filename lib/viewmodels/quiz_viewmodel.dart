import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/local_store.dart';
import '../services/game_services_manager.dart';
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

  Question? get currentQuestion {
    if (_currentQuizQuestions.isEmpty || _currentIndex >= _currentQuizQuestions.length) return null;
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
      final String response = await rootBundle.loadString('assets/data/questions.json');
      final data = await json.decode(response);
      _allQuestions = (data as List).map((i) => Question.fromJson(i)).toList();
      
      // 로컬 최고 점수 캐싱
      _bestScore = await LocalStore.getBestScore();
    } catch (e) {
      print("Error loading data: $e");
    }
    _isLoading = false;
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
    _isGameOver = false;
    _showFeedback = false;
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
    
    _isLastAnswerCorrect = (currentQuestion != null && currentQuestion!.answerIndex == selectedIndex);
    // 타격감 효과음 재생
    if (_isLastAnswerCorrect) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playWrong();
    }

    if (_isLastAnswerCorrect) {
      _combo++;
      _score += (10 + _timeLeft) * _combo; // 콤보 보너스 배수 적용
    } else {
      _combo = 0;
      _lives--;
    }

    _showFeedback = true;
    notifyListeners();

    // 1.5초 후 다음 로직 진행
    Future.delayed(const Duration(milliseconds: 1500), () async {
      _showFeedback = false;
      
      if (_lives <= 0 || _currentIndex >= _currentQuizQuestions.length - 1) {
        // 체력을 모두 소진하거나 마지막 문제에 도달하면 게임 오버
        _isGameOver = true;
        
        // 최고 점수 갱신 확인
        bool updated = await LocalStore.updateBestScore(_score);
        if (updated) {
          _isNewRecord = true;
          _bestScore = _score;
          // 글로벌 랭킹 플랫폼(Game Center / Google Play)에 점수 업로드
          GameServicesManager.submitScore(_score);
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
}
