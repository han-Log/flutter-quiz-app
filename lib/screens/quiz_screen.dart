import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../services/database_service.dart';
import '../services/level_service.dart';
import 'package:login/theme/app_theme.dart';
import '../widgets/quiz_level_visualizer.dart';

class QuizScreen extends StatefulWidget {
  final int initialExp;
  final List<String> selectedCategories;

  const QuizScreen({
    super.key,
    required this.initialExp,
    required this.selectedCategories,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _floatController;

  List<Quiz> _quizzes = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  late int _currentExp;
  bool _isLoading = true;

  // 💡 [개선된 스트릭 추적 변수]
  int _sessionStreak = 0; // 현재 세션 내에서 유지 중인 연속 정답 수
  bool _hasFailedThisSession = false; // 이번 세션 중 한 번이라도 틀렸는지 기록

  final Map<String, Map<String, int>> _sessionCategoryStats = {};

  @override
  void initState() {
    super.initState();
    _currentExp = widget.initialExp;
    _loadQuizzes();

    // 캐릭터 둥둥 애니메이션 유지
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _loadQuizzes() async {
    try {
      final int userLevel = LevelService.getLevel(_currentExp);
      final quizzes = await _quizService.generateQuizzes(
        widget.selectedCategories,
        userLevel,
      );

      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading quizzes: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("퀴즈를 불러오는 데 실패했습니다.")));
        Navigator.pop(context);
      }
    }
  }

  void _handleAnswer(int index) {
    final currentQuiz = _quizzes[_currentIndex];
    final String category = currentQuiz.category;
    bool isCorrect = index == currentQuiz.answerIndex;

    // 카테고리 통계 기록 유지
    if (!_sessionCategoryStats.containsKey(category)) {
      _sessionCategoryStats[category] = {'total': 0, 'correct': 0};
    }
    _sessionCategoryStats[category]!['total'] =
        _sessionCategoryStats[category]!['total']! + 1;

    if (isCorrect) {
      _sessionCategoryStats[category]!['correct'] =
          _sessionCategoryStats[category]!['correct']! + 1;

      // 🔥 [스트릭 로직 핵심] 맞히면 세션 내 스트릭 카운트 증가
      _sessionStreak++;

      setState(() {
        _correctCount++;
        _currentExp += 1; // 문제당 1점 (기존 설정 유지)
      });
    } else {
      // 🔥 [스트릭 로직 핵심] 틀리면 스트릭은 즉시 0, 세션 실패 기록 남김
      _sessionStreak = 0;
      _hasFailedThisSession = true;
    }

    _showResultDialog(isCorrect, currentQuiz);
  }

  void _showResultDialog(bool isCorrect, Quiz currentQuiz) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isCorrect ? "정답! 🎉" : "오답.. 😭",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isCorrect ? AppColors.primaryPurple : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect
                  ? "경험치가 올랐습니다!"
                  : "정답은 '${currentQuiz.options[currentQuiz.answerIndex]}' 입니다.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            // 💡 [시각적 피드백] 현재 실시간 스트릭 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fireplace_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "연속 정답: $_sessionStreak",
                    style: const TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (_currentIndex < _quizzes.length - 1) {
                  setState(() => _currentIndex++);
                } else {
                  _finishQuiz();
                }
              },
              child: const Text(
                "다음 문제",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finishQuiz() async {
    setState(() => _isLoading = true);

    int gainedExp = _currentExp - widget.initialExp;

    // 💡 [DB 업데이트 호출] 바뀐 DatabaseService 파라미터에 맞춰 전송
    await _dbService.updateQuizResults(
      sessionStats: _sessionCategoryStats,
      newExp: gainedExp,
      totalSolved: _quizzes.length,
      totalCorrect: _correctCount,
      sessionStreak: _sessionStreak, // 최종 세션 스트릭
      failedThisSession: _hasFailedThisSession, // 세션 내 실패 기록 여부
    );

    if (!mounted) return;
    // 결과 전송 후 업데이트된 경험치를 가지고 홈으로 복귀
    Navigator.pop(context, _currentExp);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
      );

    final screenHeight = MediaQuery.of(context).size.height;
    final quiz = _quizzes[_currentIndex];
    int currentLevel = LevelService.getLevel(_currentExp);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 수족관 비주얼 영역 유지
          Stack(
            clipBehavior: Clip.none,
            children: [
              QuizLevelVisualizer(
                height: screenHeight * 0.35,
                level: LevelService.getSafeLevel(currentLevel),
                floatAnimation: _floatController,
              ),
              Positioned(
                bottom: -1,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildQuizHeader(currentLevel),
                  const SizedBox(height: 25),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          Text(
                            "Q${_currentIndex + 1}. [${quiz.category}]",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            quiz.question,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepPurple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 35),
                          ...List.generate(
                            quiz.options.length,
                            (i) => _buildOptionButton(i, quiz.options[i]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상단 진행도 및 레벨 헤더 유지
  Widget _buildQuizHeader(int lvl) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Lv.$lvl ${LevelService.getLevelName(lvl)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.deepPurple,
            ),
          ),
          Text(
            "문항 ${_currentIndex + 1} / ${_quizzes.length}",
            style: const TextStyle(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      LinearProgressIndicator(
        value: (_currentIndex + 1) / _quizzes.length,
        minHeight: 8,
        backgroundColor: const Color(0xFFF2F4FF),
        color: AppColors.primaryPurple,
      ),
    ],
  );

  // 문제 선택지 버튼 디자인 유지
  Widget _buildOptionButton(int index, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _handleAnswer(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.deepPurple,
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade200, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
      ),
    ),
  );
}
