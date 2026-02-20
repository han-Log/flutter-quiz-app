import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/level_service.dart';
import '../services/database_service.dart';
import '../widgets/attendance_grass_widget.dart';
import '../widgets/score_radar_chart.dart';
import 'following_list_screen.dart'; // 💡 리스트 화면 이동을 위해 임포트

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dbService.syncFollowCounts();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _dbService.userDataStream,
        builder: (context, snapshot) {
          int level = 1;
          int score = 0;
          int followerCount = 0;
          int followingCount = 0;
          int totalSolved = 0;
          int totalCorrect = 0;
          String myUid = ""; // 💡 이동 시 필요한 내 UID
          Map<String, dynamic> attendance = {};

          final List<String> categoryOrder = [
            '사회',
            '인문',
            '예술',
            '역사',
            '경제',
            '과학',
            '일상',
          ];
          List<double> chartScores = [0, 0, 0, 0, 0, 0, 0];

          if (snapshot.hasData && snapshot.data?.data() != null) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            myUid = userData['uid'] ?? ""; // 💡 UID 가져오기
            score = userData['score'] ?? 0;
            level = LevelService.getLevel(score);
            followerCount = userData['followerCount'] ?? 0;
            followingCount = userData['followingCount'] ?? 0;
            attendance = userData['attendance'] as Map<String, dynamic>? ?? {};

            var categories =
                userData['categories'] as Map<String, dynamic>? ?? {};
            categories.forEach((key, value) {
              totalSolved += (value['total'] as int? ?? 0);
              totalCorrect += (value['correct'] as int? ?? 0);
            });

            chartScores = categoryOrder
                .map((cat) {
                  var stats = categories[cat];
                  if (stats == null || stats['total'] == 0) return 1.0;
                  return (stats['correct'] / stats['total']) * 10.0;
                })
                .toList()
                .cast<double>();
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // 💡 내 UID를 넘겨주어 클릭 가능하게 수정
                _buildHeader(context, myUid, followerCount, followingCount),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRoundedBackground(),
                      _buildAnimatedFish(LevelService.getSafeLevel(level)),
                      Positioned(
                        bottom: 15,
                        child: _buildLevelBadge(level, score),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                _buildStatCards(totalSolved, totalCorrect),
                const SizedBox(height: 25),
                _buildSectionTitle("2026년 학습 리포트"),
                const SizedBox(height: 12),
                AttendanceGrassWidget(attendance: attendance),

                const SizedBox(height: 25),
                _buildAnalysisSection(chartScores),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI 구성 메서드 ---

  Widget _buildHeader(
    BuildContext context,
    String uid,
    int followers,
    int following,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "나의 수족관",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B69),
            ),
          ),
          Row(
            children: [
              // 💡 클릭 이벤트가 추가된 팔로워 아이템
              _buildFollowItem(context, "팔로워", followers, uid, false),
              const SizedBox(width: 15),
              // 💡 클릭 이벤트가 추가된 팔로잉 아이템
              _buildFollowItem(context, "팔로잉", following, uid, true),
            ],
          ),
        ],
      ),
    );
  }

  // 💡 클릭 시 FollowingListScreen으로 이동하는 GestureDetector 추가
  Widget _buildFollowItem(
    BuildContext context,
    String label,
    int count,
    String uid,
    bool isFollowingMode,
  ) {
    return GestureDetector(
      onTap: () {
        if (uid.isEmpty) return; // UID가 없으면 이동 방지
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowingListScreen(
              myUid: uid,
              title: label,
              isFollowingMode: isFollowingMode,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent, // 클릭 영역 확보
        child: Column(
          children: [
            Text(
              "$count",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B61FF),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundedBackground() => Container(
    width: double.infinity,
    height: 260,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(40),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7B61FF).withOpacity(0.12),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
    ),
  );

  Widget _buildAnimatedFish(int level) => AnimatedBuilder(
    animation: _floatController,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, _floatController.value * 15 - 7.5),
      child: Image.asset('assets/images/fish_$level.png', width: 140),
    ),
  );

  Widget _buildAnalysisSection(List<double> scores) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "영역별 역량 분석",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 220, child: ScoreRadarChart(scores: scores)),
        ],
      ),
    );
  }

  Widget _buildLevelBadge(int level, int score) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      "Lv.$level ${LevelService.getLevelName(level)} ($score pts)",
      style: const TextStyle(
        color: Color(0xFF7B61FF),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildStatCards(int solved, int correct) {
    double accuracy = solved == 0 ? 0 : (correct / solved) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildStatBox("푼 문제", "$solved", Colors.blue),
          const SizedBox(width: 10),
          _buildStatBox("정답", "$correct", Colors.green),
          const SizedBox(width: 10),
          _buildStatBox(
            "정답률",
            "${accuracy.toStringAsFixed(1)}%",
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    ),
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D1B69),
          fontSize: 17,
        ),
      ),
    ),
  );
}
