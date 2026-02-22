import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../services/database_service.dart';
import '../services/level_service.dart';

class QuizScreen extends StatefulWidget {
  final int initialExp;
  final List<String> selectedCategories; // 💡 추가

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

  final Map<String, Map<String, int>> _sessionCategoryStats = {};

  @override
  void initState() {
    super.initState();
    _currentExp = widget.initialExp;
    _loadQuizzes();
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
      // 💡 선택된 카테고리를 서비스에 전달
      final quizzes = await _quizService.generateQuizzes(
        widget.selectedCategories,
      );
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
    await _dbService.updateQuizResults(
      _sessionCategoryStats,
      _currentExp,
      _correctCount,
    );
    if (!mounted) return;
    Navigator.pop(context, _currentExp);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final screenHeight = MediaQuery.of(context).size.height;
    final double backgroundHeight = screenHeight * 0.35;
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
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: backgroundHeight,
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.fill,
            ),
          ),
          _buildAnimatedFish(
            LevelService.getSafeLevel(currentLevel),
            backgroundHeight,
          ),
          Positioned(
            top: backgroundHeight - 70,
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
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 25, 24, 20),
                child: Column(
                  children: [
                    _buildHeader(currentLevel),
                    const SizedBox(height: 25),
                    Expanded(
                      child: SingleChildScrollView(
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
        ],
      ),
    );
  }

  Widget _buildAnimatedFish(int lvl, double h) => AnimatedBuilder(
    animation: _floatController,
    builder: (context, child) => Positioned(
      left: 0,
      right: 0,
      top: (h * 0.18) + (_floatController.value * 20),
      child: Center(
        child: Image.asset('assets/images/fish_$lvl.png', width: 160),
      ),
    ),
  );

  Widget _buildHeader(int lvl) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Lv.$lvl ${LevelService.getLevelName(lvl)}",
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
      LinearProgressIndicator(
        value: (_currentIndex + 1) / _quizzes.length,
        minHeight: 8,
        backgroundColor: const Color(0xFFF8F9FF),
        color: const Color(0xFF7B61FF),
      ),
    ],
  );

  Widget _buildOptionButton(int index, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _handleAnswer(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2D1B69),
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
