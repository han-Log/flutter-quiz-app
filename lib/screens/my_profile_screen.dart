import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/level_service.dart';
import '../widgets/score_radar_chart.dart';
import '../screens/search_screen.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart'; // 💡 추가
import 'following_list_screen.dart'; // 💡 추가

class MyProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const MyProfileScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final DatabaseService dbService = DatabaseService(); // 💡 스트림 사용을 위해 선언

    int exp = userData['score'] ?? 0;
    int level = LevelService.getLevel(exp);
    double progress = LevelService.getLevelProgress(exp);

    // 카테고리 통계 계산
    int totalSolved = 0;
    int totalCorrect = 0;
    (userData['categories'] as Map<String, dynamic>? ?? {}).forEach((
      key,
      value,
    ) {
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
      appBar: AppBar(
        title: const Text(
          "마이페이지",
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await authService.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 💡 실시간 숫자를 위해 StreamBuilder 사용
        stream: dbService.userDataStream,
        builder: (context, snapshot) {
          // 실시간 데이터가 있으면 업데이트, 없으면 전달받은 기본 데이터 사용
          var liveData = snapshot.hasData
              ? snapshot.data!.data() as Map<String, dynamic>
              : userData;
          int followerCount = liveData['followerCount'] ?? 0;
          int followingCount = liveData['followingCount'] ?? 0;
          String myUid = liveData['uid'] ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: liveData['profileUrl'] != null
                      ? NetworkImage(liveData['profileUrl'])
                      : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                ),
                const SizedBox(height: 15),
                Text(
                  liveData['nickname'] ?? "익명",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Lv.$level ${LevelService.getLevelName(level)}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 25),

                // 💡 1. 소셜 카운터 섹션 (새로 추가됨)
                _buildSocialCounter(
                  context,
                  myUid,
                  followerCount,
                  followingCount,
                ),
                const SizedBox(height: 30),

                _buildStatCard(totalSolved, totalCorrect, level),
                const SizedBox(height: 35),

                _buildSectionTitle("레벨 진척도"),
                const SizedBox(height: 12),
                _buildProgressBar(progress),
                const SizedBox(height: 35),

                _buildSectionTitle("소셜"),
                const SizedBox(height: 12),
                _buildMenuTile(
                  context,
                  icon: Icons.person_add,
                  title: "친구 찾기",
                  subtitle: "새로운 친구를 검색하고 팔로우하세요",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                _buildSectionTitle("영역별 역량 분석"),
                const SizedBox(height: 15),
                SizedBox(
                  height: 250,
                  child: ScoreRadarChart(scores: chartScores),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  // 💡 소셜 숫자를 보여주고 클릭 이벤트를 담당하는 위젯
  Widget _buildSocialCounter(
    BuildContext context,
    String uid,
    int followers,
    int following,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCountItem(context, "팔로워", followers, uid, false),
          const SizedBox(width: 40),
          _buildCountItem(context, "팔로잉", following, uid, true),
        ],
      ),
    );
  }

  Widget _buildCountItem(
    BuildContext context,
    String label,
    int count,
    String uid,
    bool isFollowing,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowingListScreen(
              myUid: uid,
              title: label,
              isFollowingMode: isFollowing,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Text(
            "$count",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF101828),
            ),
          ),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

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

  Widget _buildStatCard(int solved, int correct, int level) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("푼 문제", "$solved"),
          _buildStatItem("정답", "$correct", color: Colors.blue),
          _buildStatItem("레벨", "Lv.$level", color: const Color(0xFF7B61FF)),
        ],
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
            color: color ?? const Color(0xFF2D1B69),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8E5FF),
        child: Icon(icon, color: const Color(0xFF7B61FF)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}
