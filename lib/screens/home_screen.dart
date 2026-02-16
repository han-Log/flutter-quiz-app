import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart';
import 'search_screen.dart';
import '../services/level_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/score_radar_chart.dart';
import '../widgets/ranking_system.dart';

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
  final ScrollController _rankingScrollController = ScrollController();

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
    _rankingScrollController.dispose();
    super.dispose();
  }

  // 💡 프로필 상세 정보를 보여주는 바텀 시트 함수
  void _showProfileDetail(
    Map<String, dynamic> userData,
    List<double> chartScores,
  ) {
    int exp = userData['score'] ?? 0;
    int level = LevelService.getLevel(exp);
    double progress = LevelService.getLevelProgress(exp);

    // 퀴즈 통계 계산
    int totalSolved = 0;
    int totalCorrect = 0;
    (userData['categories'] as Map<String, dynamic>? ?? {}).forEach((
      key,
      value,
    ) {
      totalSolved += (value['total'] as int? ?? 0);
      totalCorrect += (value['correct'] as int? ?? 0);
    });
    int totalWrong = totalSolved - totalCorrect;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundImage: userData['profileUrl'] != null
                    ? NetworkImage(userData['profileUrl'])
                    : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
              ),
              const SizedBox(height: 15),
              Text(
                userData['nickname'] ?? "익명",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                LevelService.getLevelName(level),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 25),

              // 📊 요약 스탯 카드
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem("푼 문제", "$totalSolved"),
                  _buildStatItem("맞춘 문제", "$totalCorrect", color: Colors.blue),
                  _buildStatItem("틀린 문제", "$totalWrong", color: Colors.red),
                ],
              ),
              const SizedBox(height: 30),

              // 📈 레벨 진척도
              _buildSectionTitle("레벨 정보 (Lv.$level)"),
              const SizedBox(height: 10),
              _buildProgressBar(progress),
              const SizedBox(height: 30),

              // 🕸️ 역량 분석 차트
              _buildSectionTitle("영역별 역량 분석"),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: ScoreRadarChart(scores: chartScores),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double backgroundHeight = screenHeight * 0.35;

    return StreamBuilder<DocumentSnapshot>(
      stream: _dbService.userDataStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        int currentExp = userData['score'] ?? 0;
        int currentLevel = LevelService.getLevel(currentExp);

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
              _buildBackground(backgroundHeight),
              _buildAnimatedFish(
                LevelService.getSafeLevel(currentLevel),
                backgroundHeight,
              ),
              _buildTopSearchButton(context),

              Positioned(
                top: backgroundHeight - 50,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: _sheetDecoration(),
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
                          // 💡 프로필 헤더 (클릭 시 상세 팝업 호출)
                          GestureDetector(
                            onTap: () =>
                                _showProfileDetail(userData, chartScores),
                            child: _buildProfileHeader(
                              userData,
                              LevelService.getLevelName(currentLevel),
                              currentExp,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildProgressBar(
                            LevelService.getLevelProgress(currentExp),
                          ),

                          const SizedBox(height: 35),
                          _buildScrollableRanking(userData['uid']),
                          const SizedBox(height: 25),
                          _buildQuizButton(context, currentExp),
                          const SizedBox(height: 40),
                          _buildSectionTitle("나의 역량 차트"),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 220,
                            child: ScoreRadarChart(scores: chartScores),
                          ),
                          const SizedBox(height: 40),
                          _buildLogoutButton(context),
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

  // --- 기존 헬퍼 함수들 (HomeScreen 내부) ---
  Widget _buildScrollableRanking(String? myUid) {
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(
              const Color(0xFF7B61FF).withOpacity(0.3),
            ),
            radius: const Radius.circular(10),
          ),
        ),
        child: Scrollbar(
          controller: _rankingScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _rankingScrollController,
            physics: const BouncingScrollPhysics(),
            child: RankingSystem(myUid: myUid),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizButton(BuildContext context, int exp) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizScreen(initialExp: exp)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B61FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill),
            SizedBox(width: 10),
            Text(
              "나도 랭킹 올리기 (퀴즈 시작)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _sheetDecoration() => const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(40),
      topRight: Radius.circular(40),
    ),
    boxShadow: [
      BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5)),
    ],
  );
  Widget _buildBackground(double height) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    height: height,
    child: Image.asset('assets/images/background.jpg', fit: BoxFit.fill),
  );
  Widget _buildAnimatedFish(int level, double bgHeight) => AnimatedBuilder(
    animation: _floatController,
    builder: (context, child) => Positioned(
      left: 0,
      right: 0,
      top: (bgHeight * 0.18) + (_floatController.value * 20),
      child: Center(
        child: Image.asset('assets/images/fish_$level.png', width: 160),
      ),
    ),
  );
  Widget _buildTopSearchButton(BuildContext context) => Positioned(
    top: 50,
    right: 20,
    child: CircleAvatar(
      backgroundColor: Colors.black.withOpacity(0.2),
      child: IconButton(
        icon: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        ),
      ),
    ),
  );

  Widget _buildProfileHeader(
    Map<String, dynamic> userData,
    String levelName,
    int exp,
  ) => Row(
    children: [
      CircleAvatar(
        radius: 28,
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

  Widget _buildProgressBar(double progress) => Container(
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
      ],
    ),
  );

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
  Widget _buildLogoutButton(BuildContext context) => TextButton(
    onPressed: () async {
      await _authService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    },
    child: Text("로그아웃", style: TextStyle(color: Colors.grey.shade400)),
  );
}
