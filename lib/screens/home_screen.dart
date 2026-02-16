import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart';
import 'search_screen.dart';
import '../services/level_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/score_radar_chart.dart';
import '../widgets/ranking_system.dart'; // 💡 새로 만든 위젯 임포트

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
    final double backgroundHeight = screenHeight * 0.35;

    return StreamBuilder<DocumentSnapshot>(
      stream: _dbService.userDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(body: Center(child: Text("데이터를 불러올 수 없습니다.")));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        int currentExp = userData['score'] ?? 0;
        int currentLevel = LevelService.getLevel(currentExp);
        String levelName = LevelService.getLevelName(currentLevel);

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
              var stats = (userData['categories'] ?? {})[cat];
              if (stats == null || stats['total'] == 0) return 0.0;
              return (stats['correct'] / stats['total']) * 10.0;
            })
            .toList()
            .cast<double>();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // 1. 배경 이미지
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

              // 2. 애니메이션 물고기
              _buildAnimatedFish(
                LevelService.getSafeLevel(currentLevel),
                backgroundHeight,
              ),

              // 3. 상단 친구 추가 버튼 (Social 기능)
              Positioned(
                top: 50,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.2),
                  child: IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. 메인 콘텐츠 시트
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
                      padding: const EdgeInsets.fromLTRB(24, 25, 24, 30),
                      child: Column(
                        children: [
                          _buildProfileHeader(userData, levelName, currentExp),
                          const SizedBox(height: 12),
                          _buildProgressBar(
                            LevelService.getLevelProgress(currentExp),
                            LevelService.expUntilNextLevel(currentExp),
                          ),
                          const SizedBox(height: 35),

                          // 💡 분리된 랭킹 시스템 위젯 호출
                          RankingSystem(myUid: userData['uid']),

                          const SizedBox(height: 35),
                          _buildSectionTitle("영역별 역량 분석"),
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
                              if (mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              }
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

  // --- UI 빌더 함수들 ---

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

  Widget _buildProfileHeader(
    Map<String, dynamic> userData,
    String levelName,
    int exp,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: userData['profileUrl'] != null
              ? NetworkImage(userData['profileUrl'])
              : const AssetImage('assets/images/default_profile.png')
                    as ImageProvider,
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userData['nickname'] ?? "익명",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            Text(
              levelName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1B69),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          "Lv.${LevelService.getLevel(exp)}",
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF7B61FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress, int remaining) {
    return Container(
      padding: const EdgeInsets.all(11),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white,
              color: const Color(0xFF7B61FF),
            ),
          ),

          // 칸이 적어서 숨김
          // const SizedBox(height: 10),
          // Text(
          //   remaining > 0 ? "다음 레벨까지 $remaining EXP" : "최고 레벨 달성!",
          //   style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          // ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D1B69),
      ),
    ),
  );

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
