import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/question_model.dart';
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

  List<Question> get currentQuizQuestions => _currentQuizQuestions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int get timeLeft => _timeLeft;
  bool get isGameOver => _isGameOver;
  bool get isLoading => _isLoading;
  bool get showFeedback => _showFeedback;
  bool get isLastAnswerCorrect => _isLastAnswerCorrect;

  Question? get currentQuestion {
    if (_currentQuizQuestions.isEmpty || _currentIndex >= _currentQuizQuestions.length) return null;
    return _currentQuizQuestions[_currentIndex];
  }

  QuizViewModel() {
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final String response = await rootBundle.loadString('assets/data/questions.json');
      final data = await json.decode(response);
      _allQuestions = (data as List).map((i) => Question.fromJson(i)).toList();
    } catch (e) {
      print("Error loading questions: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  void startQuiz({int questionCount = 10}) {
    _allQuestions.shuffle();
    _currentQuizQuestions = _allQuestions.take(questionCount).toList();
    _currentIndex = 0;
    _score = 0;
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
    if (_isLastAnswerCorrect) {
      _score += 10 + _timeLeft; 
    }

    _showFeedback = true;
    notifyListeners();

    // 1.5초 후 다음 문제로 진행
    Future.delayed(const Duration(milliseconds: 1500), () {
      _showFeedback = false;
      if (_currentIndex < _currentQuizQuestions.length - 1) {
        _currentIndex++;
        _startTimer();
      } else {
        _isGameOver = true;
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
