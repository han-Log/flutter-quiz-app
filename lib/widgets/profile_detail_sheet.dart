import 'package:flutter/material.dart';
import '../services/level_service.dart';
import '../widgets/score_radar_chart.dart';

class ProfileDetailSheet extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileDetailSheet({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
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

    // 차트 데이터 준비
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
            const SizedBox(height: 25),

            // 프로필 이미지 및 기본 정보
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: userData['profileUrl'] != null
                  ? NetworkImage(userData['profileUrl'])
                  : const AssetImage('assets/images/default_profile.png')
                        as ImageProvider,
            ),
            const SizedBox(height: 15),
            Text(
              userData['nickname'] ?? "익명",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1B69),
              ),
            ),
            Text(
              LevelService.getLevelName(level),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 30),

            // 요약 스탯 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem("푼 문제", "$totalSolved"),
                  _buildStatItem("정답", "$totalCorrect", color: Colors.blue),
                  _buildStatItem("오답", "$totalWrong", color: Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // 레벨 정보
            _buildSectionTitle("레벨 정보 (Lv.$level)"),
            const SizedBox(height: 12),
            _buildProgressBar(progress),
            const SizedBox(height: 35),

            // 역량 차트
            _buildSectionTitle("영역별 역량 분석"),
            const SizedBox(height: 15),
            SizedBox(height: 250, child: ScoreRadarChart(scores: chartScores)),
            const SizedBox(height: 30),
          ],
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF2D1B69),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
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

  Widget _buildProgressBar(double progress) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 12,
          backgroundColor: const Color(0xFFE0E0E0),
          color: const Color(0xFF7B61FF),
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          "${(progress * 100).toInt()}% 완료",
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7B61FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}
