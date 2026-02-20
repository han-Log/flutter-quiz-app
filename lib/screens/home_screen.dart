import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/level_service.dart';
import '../services/database_service.dart';

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
    // 🐟 물고기 둥둥 떠다니는 애니메이션 설정
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 💡 앱 진입 시 서버와 실제 팔로우/팔로워 숫자를 동기화합니다.
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
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _dbService.userDataStream,
        builder: (context, snapshot) {
          int level = 1;

          if (snapshot.hasData && snapshot.data?.data() != null) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            // 경험치(score)를 바탕으로 현재 레벨 계산
            level = LevelService.getLevel(userData['score'] ?? 0);
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "나의 수족관",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B69),
                  ),
                ),
                const SizedBox(height: 30),

                // 수족관 배경과 애니메이션 물고기
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildRoundedBackground(),
                    _buildAnimatedFish(LevelService.getSafeLevel(level)),
                  ],
                ),

                const SizedBox(height: 35),

                // 레벨 이름과 등급 태그
                _buildLevelTag(level),

                const SizedBox(height: 15),
                Text(
                  "문제를 풀어서 수족관을 키워보세요!",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI 구성 요소들 ---

  // 1. 수족관 배경 (이미지 포함)
  Widget _buildRoundedBackground() => Container(
    width: double.infinity,
    height: 350,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(45),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7B61FF).withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 20),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(45),
      child: Image.asset(
        'assets/images/background.jpg', // 수족관 배경 이미지
        fit: BoxFit.cover,
      ),
    ),
  );

  // 2. 애니메이션 물고기
  Widget _buildAnimatedFish(int level) => AnimatedBuilder(
    animation: _floatController,
    builder: (context, child) => Transform.translate(
      // 위아래로 부드럽게 움직이는 효과
      offset: Offset(0, _floatController.value * 20 - 10),
      child: Image.asset(
        'assets/images/fish_$level.png', // 레벨별 물고기 이미지
        width: 200,
      ),
    ),
  );

  // 3. 레벨 표시 태그
  Widget _buildLevelTag(int level) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF7B61FF).withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Text(
          "Lv.$level",
          style: const TextStyle(
            fontSize: 22,
            color: Color(0xFF7B61FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          LevelService.getLevelName(level),
          style: const TextStyle(fontSize: 16, color: Color(0xFF7B61FF)),
        ),
      ],
    ),
  );
}
