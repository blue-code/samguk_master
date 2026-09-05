// 앱 내 다국어 문자열 직접 관리 클래스
// flutter_gen 자동생성 대신 수동으로 관리하여 빌드 의존성 없이 안정 동작
class AppStrings {
  final String appTitle;
  final String startGame;
  final String globalRanking;
  final String globalRankingUnavailable;
  final String bestScore;
  final String score;
  final String combo;
  final String difficulty;
  final String gameOver;
  final String myRank;
  final String finalScore;
  final String newRecord;
  final String backToMain;
  final String wrongNotes;
  final String correctAnswer;
  final String rankSoldier;
  final String rankGeneral;
  final String rankLord;
  final String loading;
  final String languageSelect;
  // 단계 정복 모델
  final String stageClear;
  final String fullConquest;
  final String nextStage;
  final String viewResult;
  final String conquestProgress;
  final String currentStageLabel;
  final String rankEmperor;
  // 리워드 광고 보상
  final String hintFiftyFifty;
  final String reviveCombo;
  final String doubleScore;
  final String watchAdSuffix;
  final String reviewQueue;
  final String noThanks;

  const AppStrings({
    required this.appTitle,
    required this.startGame,
    required this.globalRanking,
    required this.globalRankingUnavailable,
    required this.bestScore,
    required this.score,
    required this.combo,
    required this.difficulty,
    required this.gameOver,
    required this.myRank,
    required this.finalScore,
    required this.newRecord,
    required this.backToMain,
    required this.wrongNotes,
    required this.correctAnswer,
    required this.rankSoldier,
    required this.rankGeneral,
    required this.rankLord,
    required this.loading,
    required this.languageSelect,
    required this.stageClear,
    required this.fullConquest,
    required this.nextStage,
    required this.viewResult,
    required this.conquestProgress,
    required this.currentStageLabel,
    required this.rankEmperor,
    required this.hintFiftyFifty,
    required this.reviveCombo,
    required this.doubleScore,
    required this.watchAdSuffix,
    required this.reviewQueue,
    required this.noThanks,
  });

  String shareText(int score, String rank) =>
      _shareTemplates[appTitle]?.call(score, rank) ?? '$score / $rank';

  // 단계명: "1단계" / "Stage 1" / "第1关" / "ステージ1"
  String stageName(int n) =>
      _stageTemplates[appTitle]?.call(n) ?? 'Stage $n';

  static final Map<String, String Function(int)> _stageTemplates = {
    '삼국지 덕력고사': (n) => '$n단계',
    'Three Kingdoms Quiz': (n) => 'Stage $n',
    '三国英雄试炼': (n) => '第$n关',
    '三国志英雄検定': (n) => 'ステージ$n',
  };

  // 난이도 표시명 (Easy/Medium/Hard 현지화)
  String difficultyName(String difficulty) =>
      (_difficultyTemplates[appTitle] ?? const {})[difficulty] ?? difficulty;

  static final Map<String, Map<String, String>> _difficultyTemplates = {
    '삼국지 덕력고사': {'Easy': '입문', 'Medium': '숙련', 'Hard': '고수'},
    'Three Kingdoms Quiz': {'Easy': 'Easy', 'Medium': 'Medium', 'Hard': 'Hard'},
    '三国英雄试炼': {'Easy': '入门', 'Medium': '熟练', 'Hard': '高手'},
    '三国志英雄検定': {'Easy': '初級', 'Medium': '中級', 'Hard': '上級'},
  };

  // 언어별 공유 텍스트 (언어마다 다른 형식)
  static final Map<String, String Function(int, String)> _shareTemplates = {
    '삼국지 덕력고사': (s, r) =>
        '나의 삼국지 덕력 점수는 ${s}점!\n나의 계급은 [$r]! 과연 당신은 나를 넘을 수 있을까?\n\n#삼국지덕력고사 #삼국지퀴즈',
    'Three Kingdoms Quiz': (s, r) =>
        'My Three Kingdoms score is $s!\nMy rank is [$r]! Can you beat me?\n\n#ThreeKingdomsQuiz',
    '三国英雄试炼': (s, r) => '我的三国志得分是${s}分！\n我的等级是【$r】！你能超越我吗？\n\n#三国英雄试炼',
    '三国志英雄検定': (s, r) => '私の三国志スコアは${s}点！\n階級は【$r】！あなたは私を超えられる？\n\n#三国志英雄検定',
  };

  // ─── 언어 데이터 ──────────────────────────────────
  static const AppStrings ko = AppStrings(
    appTitle: '삼국지 덕력고사',
    startGame: '전쟁 시작!',
    globalRanking: '글로벌 랭킹',
    globalRankingUnavailable: 'Game Center 로그인이 필요합니다.',
    bestScore: '최고 점수',
    score: '점수',
    combo: '콤보',
    difficulty: '난이도',
    gameOver: 'GAME OVER',
    myRank: '당신의 계급',
    finalScore: '최종 점수',
    newRecord: '🎉 신기록 달성! 🎉',
    backToMain: '메인으로 돌아가기',
    wrongNotes: '📝 오답 노트',
    correctAnswer: '정답',
    rankSoldier: '일개 보병',
    rankGeneral: '천하 맹장',
    rankLord: '위대한 군주',
    loading: '천하 삼분지계를 여는 중...',
    languageSelect: '언어 선택',
    stageClear: '단계 정복!',
    fullConquest: '천하 통일!',
    nextStage: '다음 단계 도전',
    viewResult: '결과 보기',
    conquestProgress: '정복도',
    currentStageLabel: '현재 단계',
    rankEmperor: '천하통일 황제',
    hintFiftyFifty: '오답 2개 지우기',
    reviveCombo: '콤보 되살리기',
    doubleScore: '점수 2배로',
    watchAdSuffix: '광고 보기',
    reviewQueue: '복습 대기',
    noThanks: '괜찮아요',
  );

  static const AppStrings en = AppStrings(
    appTitle: 'Three Kingdoms Quiz',
    startGame: 'Start Battle!',
    globalRanking: 'Global Ranking',
    globalRankingUnavailable: 'Game Center sign-in is required.',
    bestScore: 'Best Score',
    score: 'Score',
    combo: 'Combo',
    difficulty: 'Difficulty',
    gameOver: 'GAME OVER',
    myRank: 'Your Rank',
    finalScore: 'Final Score',
    newRecord: '🎉 New Record! 🎉',
    backToMain: 'Back to Main',
    wrongNotes: '📝 Wrong Answer Notes',
    correctAnswer: 'Answer',
    rankSoldier: 'Common Foot Soldier',
    rankGeneral: 'Legendary General',
    rankLord: 'Sovereign Lord',
    loading: 'Loading...',
    languageSelect: 'Language',
    stageClear: 'STAGE CLEAR!',
    fullConquest: 'UNITED THE LAND!',
    nextStage: 'Next Stage',
    viewResult: 'View Result',
    conquestProgress: 'Conquest',
    currentStageLabel: 'Stage',
    rankEmperor: 'Unifier Emperor',
    hintFiftyFifty: 'Remove 2 wrong answers',
    reviveCombo: 'Revive combo',
    doubleScore: 'Double your score',
    watchAdSuffix: 'Watch ad',
    reviewQueue: 'To review',
    noThanks: 'No thanks',
  );

  static const AppStrings zh = AppStrings(
    appTitle: '三国英雄试炼',
    startGame: '开战！',
    globalRanking: '全球排名',
    globalRankingUnavailable: '需要登录 Game Center。',
    bestScore: '最高分',
    score: '分数',
    combo: '连击',
    difficulty: '难度',
    gameOver: '游戏结束',
    myRank: '你的等级',
    finalScore: '最终得分',
    newRecord: '🎉 新纪录！ 🎉',
    backToMain: '返回主界面',
    wrongNotes: '📝 错题笔记',
    correctAnswer: '正确答案',
    rankSoldier: '普通士兵',
    rankGeneral: '天下猛将',
    rankLord: '伟大君主',
    loading: '加载中...',
    languageSelect: '语言选择',
    stageClear: '通关！',
    fullConquest: '天下统一！',
    nextStage: '挑战下一关',
    viewResult: '查看结果',
    conquestProgress: '征服度',
    currentStageLabel: '当前关卡',
    rankEmperor: '天下统一帝',
    hintFiftyFifty: '排除2个错误选项',
    reviveCombo: '恢复连击',
    doubleScore: '分数翻倍',
    watchAdSuffix: '观看广告',
    reviewQueue: '待复习',
    noThanks: '不用了',
  );

  static const AppStrings ja = AppStrings(
    appTitle: '三国志英雄検定',
    startGame: '戦い開始！',
    globalRanking: 'グローバルランキング',
    globalRankingUnavailable: 'Game Centerへのサインインが必要です。',
    bestScore: '最高スコア',
    score: 'スコア',
    combo: 'コンボ',
    difficulty: '難易度',
    gameOver: 'ゲームオーバー',
    myRank: 'あなたの階級',
    finalScore: '最終スコア',
    newRecord: '🎉 新記録達成！ 🎉',
    backToMain: 'メインに戻る',
    wrongNotes: '📝 間違いノート',
    correctAnswer: '正解',
    rankSoldier: '一般兵',
    rankGeneral: '天下の猛将',
    rankLord: '偉大な君主',
    loading: '読み込み中...',
    languageSelect: '言語',
    stageClear: 'ステージ制覇！',
    fullConquest: '天下統一！',
    nextStage: '次のステージへ',
    viewResult: '結果を見る',
    conquestProgress: '制覇度',
    currentStageLabel: '現在のステージ',
    rankEmperor: '天下統一の覇者',
    hintFiftyFifty: '誤答を2つ消す',
    reviveCombo: 'コンボ復活',
    doubleScore: 'スコア2倍',
    watchAdSuffix: '広告を見る',
    reviewQueue: '復習待ち',
    noThanks: '結構です',
  );

  // locale 코드에서 AppStrings 반환
  static AppStrings of(String languageCode) {
    switch (languageCode) {
      case 'en':
        return en;
      case 'zh':
        return zh;
      case 'ja':
        return ja;
      default:
        return ko;
    }
  }
}
