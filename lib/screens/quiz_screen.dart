import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../services/database_service.dart';
import '../services/level_service.dart';

class QuizScreen extends StatefulWidget {
  final int initialExp;
  const QuizScreen({super.key, required this.initialExp});

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

  // [유지] 카테고리별 정답 현황 기록 맵
  final Map<String, Map<String, int>> _sessionCategoryStats = {};

  @override
  void initState() {
    super.initState();
    _currentExp = widget.initialExp;
    _loadQuizzes();

    // [추가] 금붕어 애니메이션
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
      final quizzes = await _quizService.generateQuizzes();
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading quizzes: $e");
    }
  }

  void _handleAnswer(int index) {
    final currentQuiz = _quizzes[_currentIndex];
    final String category = currentQuiz.category;
    bool isCorrect = index == currentQuiz.answerIndex;

    // [유지] 카테고리별 통계 데이터 수집
    if (!_sessionCategoryStats.containsKey(category)) {
      _sessionCategoryStats[category] = {'total': 0, 'correct': 0};
    }
    _sessionCategoryStats[category]!['total'] =
        _sessionCategoryStats[category]!['total']! + 1;

    if (isCorrect) {
      _sessionCategoryStats[category]!['correct'] =
          _sessionCategoryStats[category]!['correct']! + 1;
      setState(() {
        _correctCount++;
        _currentExp++;
      });
    }

    // [디자인 변경] 정답/오답 결과 팝업 스타일링
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isCorrect ? "정답! 🎉" : "오답.. 😭",
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect
                  ? "경험치가 1 올랐습니다!"
                  : "정답은 '${currentQuiz.options[currentQuiz.answerIndex]}' 입니다.",
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "현재 등급: ${LevelService.getLevelName(LevelService.getLevel(_currentExp))}",
                style: const TextStyle(
                  color: Color(0xFF7B61FF),
                  fontWeight: FontWeight.bold,
                ),
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
    // [유지] 경험치와 통계 한 번에 업데이트
    await _dbService.updateQuizResults(_sessionCategoryStats, _currentExp);

    if (!mounted) return;

    int finalLevel = LevelService.getLevel(_currentExp);
    String finalName = LevelService.getLevelName(finalLevel);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("🎓 퀴즈 완료!", textAlign: TextAlign.center),
        content: Text(
          "총 $_correctCount문제를 맞혔습니다!\n"
          "최종 등급: $finalName (Lv.$finalLevel)\n\n"
          "성장 데이터가 저장되었습니다.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, _currentExp);
              },
              child: const Text(
                "홈으로 돌아가기",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final double backgroundHeight = screenHeight * 0.35;
    final quiz = _quizzes[_currentIndex];
    int currentLevel = LevelService.getLevel(_currentExp);
    int displayLevel = LevelService.getSafeLevel(currentLevel);

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
      body: Stack(
        children: [
          // 1. 배경 이미지 (HomeScreen과 동일)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: backgroundHeight,
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.fill,
              alignment: Alignment.bottomCenter,
            ),
          ),

          // 2. 캐릭터 (애니메이션 적용)
          _buildAnimatedFish(displayLevel, backgroundHeight),

          // 3. 하단 카드 (퀴즈 내용)
          Positioned(
            top: backgroundHeight - 70, // HomeScreen과 간격 동일화
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 25, 24, 20),
                  child: Column(
                    children: [
                      // 진행바 헤더
                      _buildHeader(currentLevel),
                      const SizedBox(height: 25),

                      // 문제 영역
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
                                  color: Color(0xFF7B61FF),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                quiz.question,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D1B69),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 35),

                              // 선택지 버튼 리스트
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFish(int displayLevel, double backgroundHeight) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          top: (backgroundHeight * 0.18) + (_floatController.value * 20),
          child: Center(
            child: Image.asset(
              'assets/images/fish_$displayLevel.png',
              width: 160,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset('assets/images/fish_1.png', width: 160),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int currentLevel) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Lv.$currentLevel ${LevelService.getLevelName(currentLevel)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1B69),
              ),
            ),
            Text(
              "문항 ${_currentIndex + 1} / ${_quizzes.length}",
              style: const TextStyle(
                color: Color(0xFF7B61FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _quizzes.length,
            minHeight: 8,
            backgroundColor: const Color(0xFFF8F9FF),
            color: const Color(0xFF7B61FF),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(int index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () => _handleAnswer(index),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2D1B69),
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
}
