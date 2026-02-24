import 'package:flutter/material.dart';
import '../services/level_service.dart';
import '../theme/app_colors.dart';
import '../widgets/attendance_grass_widget.dart';
import '../widgets/score_radar_chart.dart';

// 유저의 홈 정보를 나타내는 위젯
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
              _buildRoundedBackground(),
              _buildAnimatedFish(LevelService.getSafeLevel(level)),
              Positioned(bottom: 15, child: _buildLevelBadge(level, score)),
            ],
          ),
        ),
        const SizedBox(height: 25),

        // 2. 스탯 카드
        _buildStatCards(totalSolved, totalCorrect),
        const SizedBox(height: 35),

        // 3. 학습 리포트
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

        // 4. 역량 분석
        _buildSectionTitle("영역별 역량 분석"),
        const SizedBox(height: 12),
        _buildAnalysisSection(chartScores),
      ],
    );
  }

  // --- 내부 빌드 메서드들 ---

  Widget _buildAnimatedFish(int safeLevel) => AnimatedBuilder(
    animation: floatController,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, floatController.value * 15 - 7.5),
      child: Image.asset(
        'assets/images/level_$safeLevel.png',
        width: 130,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.help_outline, size: 100, color: Colors.white70),
      ),
    ),
  );

  Widget _buildLevelBadge(int level, int score) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      "Lv.$level ${LevelService.getLevelName(level)} ($score pts)",
      style: const TextStyle(
        color: AppColors.deepPurple,
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

  Widget _buildRoundedBackground() => Container(
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
      child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
    ),
  );
}
