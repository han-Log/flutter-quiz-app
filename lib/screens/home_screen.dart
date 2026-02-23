import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/level_service.dart';
import '../services/database_service.dart';
import '../widgets/attendance_grass_widget.dart';
import '../widgets/score_radar_chart.dart';
import 'following_list_screen.dart';
import 'package:login/theme/app_colors.dart';

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
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _dbService.userDataStream,
        builder: (context, snapshot) {
          int score = 0;
          int level = 1;
          int followerCount = 0;
          int followingCount = 0;
          int totalSolved = 0;
          int totalCorrect = 0;
          String myUid = "";
          Map<String, dynamic> attendance = {};
          List<double> chartScores = List.filled(7, 1.0);

          if (snapshot.hasData && snapshot.data?.data() != null) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            myUid = userData['uid'] ?? "";

            // 💡 실시간 점수 로드
            score = userData['score'] ?? 0;
            // 💡 점수에 따른 실시간 레벨 계산 (이게 바뀌어야 레벨이 오릅니다)
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

            final List<String> categoryOrder = [
              '사회',
              '인문',
              '예술',
              '역사',
              '경제',
              '과학',
              '일상',
            ];
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
                _buildHeader(context, myUid, followerCount, followingCount),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRoundedBackground(),
                      // 💡 파일명을 level_ 로 변경 (pubspec.yaml 기반)
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
                const SizedBox(height: 35),
                _buildSectionTitle("2026년 학습 리포트"),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: AttendanceGrassWidget(attendance: attendance),
                  ),
                ),
                const SizedBox(height: 25),
                _buildSectionTitle("영역별 역량 분석"),
                const SizedBox(height: 12),
                _buildAnalysisSection(chartScores),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 빌드 메서드 ---

  Widget _buildAnimatedFish(int safeLevel) {
    // 💡 pubspec.yaml에 level_1.png가 있으므로 파일명을 level_로 맞춥니다.
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatController.value * 15 - 7.5),
        child: Image.asset(
          'assets/images/level_$safeLevel.png',
          width: 140,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("❌ 이미지 로드 실패: assets/images/level_$safeLevel.png");
            return const Icon(
              Icons.help_outline,
              size: 100,
              color: Colors.white70,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int level, int score) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      // [2026-02-22] 규칙 적용
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      "Lv.$level ${LevelService.getLevelName(level)} ($score pts)",
      style: const TextStyle(
        color: AppColors.deepPurple,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "현재 나의 상식 상태",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.titleTextColor,
                ),
              ),
              Text(
                "꾸준한 퀴즈 풀이로 레벨을 올려보세요",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.explainTextColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildFollowItem(context, "팔로워", followers, uid, false),
              const SizedBox(width: 15),
              _buildFollowItem(context, "팔로잉", following, uid, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowItem(
    BuildContext context,
    String label,
    int count,
    String uid,
    bool isFollowing,
  ) => GestureDetector(
    onTap: () => uid.isEmpty
        ? null
        : Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => FollowingListScreen(
                myUid: uid,
                title: label,
                isFollowingMode: isFollowing,
              ),
            ),
          ),
    child: Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ],
    ),
  );

  Widget _buildRoundedBackground() => Container(
    width: double.infinity,
    height: 260,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(40),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor,
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

  Widget _buildStatCards(int solved, int correct) {
    double accuracy = solved == 0 ? 0 : (correct / solved) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildStatBox("푼 문제", "$solved", AppColors.infoBlue),
          const SizedBox(width: 10),
          _buildStatBox("정답", "$correct", AppColors.infoGreen),
          const SizedBox(width: 10),
          _buildStatBox(
            "정답률",
            "${accuracy.toStringAsFixed(1)}%",
            AppColors.infoOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _cardDecoration(borderColor: color.withValues(alpha: 0.3)),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.explainTextColor,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildAnalysisSection(List<double> scores) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(),
    child: SizedBox(height: 220, child: ScoreRadarChart(scores: scores)),
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.deepPurple,
          fontSize: 17,
        ),
      ),
    ),
  );

  BoxDecoration _cardDecoration({Color? borderColor}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(25),
    border: borderColor != null ? Border.all(color: borderColor) : null,
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
