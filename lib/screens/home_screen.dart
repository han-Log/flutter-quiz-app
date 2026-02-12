import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart';
import '../services/level_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/score_radar_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // 배경 영역 높이 설정
    final double backgroundHeight = screenHeight * 0.35;

    return StreamBuilder<DocumentSnapshot>(
      stream: _dbService.userDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        int currentExp = userData['score'] ?? 0;
        Map<String, dynamic> categories = userData['categories'] ?? {};

        int rawLevel = LevelService.getLevel(currentExp);
        int displayLevel = LevelService.getSafeLevel(rawLevel);
        String levelName = LevelService.getLevelName(rawLevel);
        double progress = LevelService.getLevelProgress(currentExp);
        int remaining = LevelService.expUntilNextLevel(currentExp);

        final List<String> categoryOrder = [
          '사회',
          '인문',
          '예술',
          '역사',
          '경제',
          '과학',
          '일상',
        ];
        List<double> chartScores = categoryOrder
            .map((cat) {
              var stats = categories[cat];
              if (stats == null || stats['total'] == 0) return 0.0;
              return (stats['correct'] / stats['total']) * 10.0;
            })
            .toList()
            .cast<double>();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // 1. 배경 이미지 영역
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: backgroundHeight,
                child: Image.asset(
                  'assets/images/background.jpg',
                  // 💡 BoxFit.fill로 설정하여 이미지를 잘림 없이 영역에 꽉 맞춥니다.
                  // 만약 비율 유지가 중요하다면 BoxFit.fitWidth와 Alignment.bottomCenter를 조합하세요.
                  fit: BoxFit.fill,
                  alignment: Alignment.bottomCenter,
                ),
              ),

              // 2. 캐릭터
              _buildAnimatedFish(displayLevel, backgroundHeight),

              // 3. 하단 카드 (바닥 끝까지 연결)
              Positioned(
                top: backgroundHeight - 50,
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                      child: Column(
                        children: [
                          Text(
                            levelName,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D1B69),
                            ),
                          ),
                          Text(
                            "Lv.$rawLevel",
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildProgressBar(progress, remaining),
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "영역별 역량 분석",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D1B69),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 250,
                            child: ScoreRadarChart(scores: chartScores),
                          ),
                          const SizedBox(height: 40),
                          _buildQuizButton(context, currentExp),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () async {
                              await _authService.signOut();
                              if (!mounted) return;
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              "로그아웃",
                              style: TextStyle(color: Colors.grey.shade400),
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
      },
    );
  }

  Widget _buildAnimatedFish(int displayLevel, double backgroundHeight) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          // 💡 캐릭터 위치를 조금 더 내려서 배경 하단부와 어울리게 조정
          top: (backgroundHeight * 0.2) + (_floatController.value * 20),
          child: Center(
            child: Image.asset(
              'assets/images/fish_$displayLevel.png',
              width: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset('assets/images/fish_1.png', width: 180),
            ),
          ),
        );
      },
    );
  }

  // _buildProgressBar 및 _buildQuizButton은 기존과 동일
  Widget _buildProgressBar(double progress, int remaining) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "레벨 진척도",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: Color(0xFF7B61FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white,
              color: const Color(0xFF7B61FF),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            remaining > 0 ? "다음 레벨까지 $remaining점" : "최고 레벨 달성!",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizButton(BuildContext context, int currentExp) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(initialExp: currentExp),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B61FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: const Text(
          "퀴즈 시작하기",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
