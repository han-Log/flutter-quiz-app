import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/level_service.dart';
import '../services/database_service.dart';
import '../widgets/attendance_grass_widget.dart';
import '../widgets/score_radar_chart.dart';

class ProfileDetailSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String myUid;

  const ProfileDetailSheet({
    super.key,
    required this.userData,
    required this.myUid,
  });

  @override
  State<ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends State<ProfileDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  final DatabaseService _dbService = DatabaseService();
  bool isFollowing = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 초기 팔로우 상태 설정
    isFollowing = widget.userData['isFollowing'] ?? false;
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _handleFollow() async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    final targetUid = widget.userData['uid'];
    if (targetUid == null || targetUid == widget.myUid) {
      Get.snackbar("알림", "자신은 팔로우할 수 없습니다.");
      setState(() => isProcessing = false);
      return;
    }

    try {
      // 💡 Firebase Rules 수정 후에 이 부분이 정상 작동합니다.
      await _dbService.toggleFollow(widget.myUid, targetUid, isFollowing);

      setState(() {
        isFollowing = !isFollowing;
      });

      Get.snackbar(
        "완료",
        isFollowing ? "팔로우를 시작했습니다." : "팔로우를 취소했습니다.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF7B61FF).withValues(alpha: 0.7),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("오류", "처리에 실패했습니다: $e");
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user = widget.userData;
    final String nickname = user['nickname']?.toString() ?? "익명";
    final int score = user['score'] is int ? user['score'] : 0;
    final int level = LevelService.getLevel(score);
    final Map<String, dynamic> attendance = user['attendance'] is Map
        ? Map<String, dynamic>.from(user['attendance'])
        : {};
    final Map<String, dynamic> categories = user['categories'] is Map
        ? Map<String, dynamic>.from(user['categories'])
        : {};

    int totalSolved = 0;
    int totalCorrect = 0;
    categories.forEach((key, value) {
      if (value is Map) {
        totalSolved += (value['total'] as int? ?? 0);
        totalCorrect += (value['correct'] as int? ?? 0);
      }
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
    List<double> chartScores = categoryOrder
        .map((cat) {
          var stats = categories[cat];
          if (stats == null || stats['total'] == 0 || stats['total'] == null)
            return 1.0;
          return (stats['correct'] / stats['total']) * 10.0;
        })
        .toList()
        .cast<double>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$nickname님의 수족관",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D1B69),
                        ),
                      ),
                      if (widget.myUid != user['uid']) _buildFollowButton(),
                    ],
                  ),
                ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AttendanceGrassWidget(attendance: attendance),
                ),
                const SizedBox(height: 25),
                _buildAnalysisSection(chartScores),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "닫기",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return GestureDetector(
      onTap: _handleFollow,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white : const Color(0xFF7B61FF),
          borderRadius: BorderRadius.circular(12),
          border: isFollowing
              ? Border.all(color: const Color(0xFF7B61FF))
              : null,
          boxShadow: [
            if (!isFollowing)
              BoxShadow(
                color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: isProcessing
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              )
            : Text(
                isFollowing ? "팔로잉" : "팔로우",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isFollowing ? const Color(0xFF7B61FF) : Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildAnalysisSection(List<double> scores) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "영역별 역량 분석",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF2D1B69),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 220,
              width: 220,
              child: ScoreRadarChart(scores: scores),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedBackground() => Container(
    width: double.infinity,
    height: 200,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7B61FF).withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
    ),
  );

  Widget _buildAnimatedFish(int level) => AnimatedBuilder(
    animation: _floatController,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, _floatController.value * 15 - 7.5),
      child: Image.asset('assets/images/fish_$level.png', width: 110),
    ),
  );

  Widget _buildLevelBadge(int level, int score) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      "Lv.$level ${LevelService.getLevelName(level)} ($score pts)",
      style: const TextStyle(
        color: Color(0xFF7B61FF),
        fontSize: 12,
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
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
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
          fontSize: 16,
        ),
      ),
    ),
  );
}
