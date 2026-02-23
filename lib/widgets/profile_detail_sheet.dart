import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/level_service.dart';
import '../services/database_service.dart';
import '../widgets/attendance_grass_widget.dart';
import '../widgets/score_radar_chart.dart';
import 'package:login/theme/app_colors.dart';

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
    // 💡 애니메이션 성능 최적화: 바텀시트가 완전히 열린 후 시작하거나 부드러운 주기를 가집니다.
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

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
      await _dbService.toggleFollow(widget.myUid, targetUid, isFollowing);
      setState(() {
        isFollowing = !isFollowing;
      });

      Get.snackbar(
        "완료",
        isFollowing ? "팔로우를 시작했습니다." : "팔로우를 취소했습니다.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.7),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("오류", "처리에 실패했습니다: $e");
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  BoxDecoration _cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: Colors.white, // 배경색을 흰색으로 고정하여 가독성 높임
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

  @override
  Widget build(BuildContext context) {
    // 💡 데이터 파싱 시 널 체크 및 타입 변환 강화
    final Map<String, dynamic> user = widget.userData;
    final String nickname =
        user['nickname']?.toString() ?? user['name']?.toString() ?? "익명";
    final int score = (user['score'] is num)
        ? (user['score'] as num).toInt()
        : 0;
    final int level = LevelService.getLevel(score);

    // 데이터 추출 안전화
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
      // 💡 높이를 고정하거나 제약 조건을 주어 렌더링 무한 루프 방지
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: Scaffold(
          // 💡 Scaffold로 감싸서 내부 레이아웃 안정화
          backgroundColor: Colors.white,
          body: Stack(
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
                          Expanded(
                            // 💡 긴 이름 대응
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$nickname님의 수족관",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.titleTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "상대방의 지식 성장도를 확인해보세요",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.explainTextColor,
                                  ),
                                ),
                              ],
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
                          // 💡 핵심 수정: HomeScreen과 동일하게 level_ 경로 사용
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
                    const SizedBox(height: 120), // 💡 하단 버튼 공간 확보
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
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      "수족관 나가기",
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
        ),
      ),
    );
  }

  // --- 빌드 메서드 (안전성 강화) ---

  Widget _buildAnimatedFish(int safeLevel) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatController.value * 15 - 7.5),
        child: Image.asset(
          'assets/images/level_$safeLevel.png', // 💡 fish_ -> level_ 로 수정
          width: 110,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.help_outline, size: 80, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int level, int score) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9), // [2026-02-22] 규칙
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      "Lv.$level ${LevelService.getLevelName(level)} ($score pts)",
      style: const TextStyle(
        color: AppColors.primaryPurple,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildStatBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: _cardDecoration(borderColor: color.withValues(alpha: 0.2)),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.explainTextColor,
            ),
          ),
        ],
      ),
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

  Widget _buildAnalysisSection(List<double> scores) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.all(24),
    decoration: _cardDecoration(),
    child: Center(
      child: SizedBox(
        height: 200, // 💡 크기를 명시적으로 제한하여 레이아웃 충돌 방지
        child: ScoreRadarChart(scores: scores),
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
          color: AppColors.deepPurple,
          fontSize: 17,
        ),
      ),
    ),
  );

  Widget _buildFollowButton() => GestureDetector(
    onTap: _handleFollow,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isFollowing ? Colors.white : AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPurple),
      ),
      child: isProcessing
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textGrey,
              ),
            )
          : Text(
              isFollowing ? "팔로잉" : "팔로우",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isFollowing ? AppColors.primaryPurple : Colors.white,
              ),
            ),
    ),
  );

  Widget _buildRoundedBackground() => Container(
    width: double.infinity,
    height: 220,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor,
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
}
