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
    // 🐟 물고기가 둥둥 떠다니는 부드러운 애니메이션
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // 💡 메모리 누수 방지를 위해 컨트롤러 해제는 필수!
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
            level = LevelService.getLevel(userData['score'] ?? 0);
          }

          return Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🏷️ 상단 타이틀 (선택 사항)
                const Text(
                  "머리 지적 수준",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B69),
                  ),
                ),
                const SizedBox(height: 30),

                // 📦 둥근 모서리 배경과 물고기 레이어
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. 모서리가 둥근 배경
                    _buildRoundedBackground(),

                    // 2. 둥둥 떠다니는 애니메이션 물고기
                    _buildAnimatedFish(LevelService.getSafeLevel(level)),
                  ],
                ),

                const SizedBox(height: 40),
                Text(
                  "현재 레벨: Lv.$level",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF7B61FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🖼️ 배경 이미지 위젯 (모서리 라운딩 처리)
  Widget _buildRoundedBackground() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
      ),
    );
  }

  // 🐟 애니메이션 효과 위젯
  Widget _buildAnimatedFish(int level) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // 💡 오프셋 값을 조절해 위아래로 부드럽게 이동
        return Transform.translate(
          offset: Offset(0, _floatController.value * 24 - 12),
          child: Image.asset('assets/images/fish_$level.png', width: 180),
        );
      },
    );
  }
}
