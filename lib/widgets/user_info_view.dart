import 'package:flutter/material.dart';
import '../services/level_service.dart';
import '../theme/app_theme.dart';
import '../widgets/attendance_grass_widget.dart';
import '../widgets/score_radar_chart.dart';

class UserInfoView extends StatelessWidget {
  final Map<String, dynamic> userData;
  final AnimationController floatController;

  const UserInfoView({
    super.key,
    required this.userData,
    required this.floatController,
  });

  @override
  Widget build(BuildContext context) {
    // 데이터 파싱
    final int score = (userData['score'] is num)
        ? (userData['score'] as num).toInt()
        : 0;
    final int level = LevelService.getLevel(score);

    final int answerStreak = userData['answerStreak'] ?? 0;
    final int attendanceStreak = userData['attendanceStreak'] ?? 0;

    final Map<String, dynamic> attendance = userData['attendance'] is Map
        ? Map<String, dynamic>.from(userData['attendance'])
        : {};
    final Map<String, dynamic> categories = userData['categories'] is Map
        ? Map<String, dynamic>.from(userData['categories'])
        : {};

    // 통계 계산
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
          if (stats == null || stats['total'] == 0) return 1.0;
          return (stats['correct'] / stats['total']) * 10.0;
        })
        .toList()
        .cast<double>();

    return Column(
      children: [
        // 1. 수족관 배경 & 캐릭터
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildRoundedBackground(level),
              _buildAnimatedFish(LevelService.getSafeLevel(level)),
            ],
          ),
        ),

        // 2. 연속 기록 대시보드 (2단 카드)
        _buildStreakDashboard(answerStreak, attendanceStreak),

        const SizedBox(height: 12),

        // 💡 3. 학습 스탯 카드 (3단 카드 - 푼 문제, 정답, 정답률)
        _buildStatCards(totalSolved, totalCorrect),

        const SizedBox(height: 35),

        // 4. 학습 리포트
        _buildSectionTitle("2026년 학습 리포트"),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDesign.cardDecoration(),
            child: AttendanceGrassWidget(attendance: attendance),
          ),
        ),

        const SizedBox(height: 25),

        // 5. 역량 분석
        _buildSectionTitle("영역별 역량 분석"),
        const SizedBox(height: 12),
        _buildAnalysisSection(chartScores),
      ],
    );
  }

  // --- 💡 연속 기록 대시보드 (2칸) ---
  Widget _buildStreakDashboard(int answerStreak, int attendanceStreak) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildInfoCard(
            "연속 정답",
            "$answerStreak회",
            Icons.local_fire_department,
            const Color(0xFFFF5252),
            isTriple: false,
          ),
          const SizedBox(width: 10),
          _buildInfoCard(
            "연속 출석",
            "$attendanceStreak일",
            Icons.calendar_today_rounded,
            const Color(0xFF4CAF50),
            isTriple: false,
          ),
        ],
      ),
    );
  }

  // --- 💡 학습 스탯 카드 (3칸 - 요청하신 변경 사항) ---
  Widget _buildStatCards(int solved, int correct) {
    double accuracy = solved == 0 ? 0 : (correct / solved) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildInfoCard(
            "푼 문제",
            "$solved",
            Icons.edit_note_rounded,
            AppColors.infoBlue,
            isTriple: true,
          ),
          const SizedBox(width: 8),
          _buildInfoCard(
            "정답",
            "$correct",
            Icons.check_circle_outline_rounded,
            AppColors.infoGreen,
            isTriple: true,
          ),
          const SizedBox(width: 8),
          _buildInfoCard(
            "정답률",
            "${accuracy.toStringAsFixed(1)}%",
            Icons.insights_rounded,
            AppColors.infoOrange,
            isTriple: true,
          ),
        ],
      ),
    );
  }

  // --- 💡 공통 정보 카드 빌더 (2칸/3칸 겸용) ---
  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    required bool isTriple,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 14,
          horizontal: isTriple ? 8 : 12,
        ),
        decoration: AppDesign.cardDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 배경
            Container(
              padding: EdgeInsets.all(isTriple ? 6 : 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: isTriple ? 16 : 18),
            ),
            SizedBox(width: isTriple ? 6 : 10),
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isTriple ? 9 : 10,
                      color: AppColors.explainTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isTriple ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF101828),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 나머지 기존 메서드들 ---
  Widget _buildAnimatedFish(int safeLevel) => AnimatedBuilder(
    animation: floatController,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, floatController.value * 15 - 7.5),
      child: Image.asset(
        'assets/images/level_$safeLevel.png',
        width: 350,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.help_outline, size: 100, color: Colors.white70),
      ),
    ),
  );

  Widget _buildAnalysisSection(List<double> scores) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.all(20),
    decoration: AppDesign.cardDecoration(),
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

  Widget _buildRoundedBackground(int level) {
    final String bgName = LevelService.getLevelBackground(level);
    return Container(
      width: double.infinity,
      height: 240,
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
        child: Image.asset(
          'assets/images/$bgName',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset('assets/images/sea.jpeg', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
