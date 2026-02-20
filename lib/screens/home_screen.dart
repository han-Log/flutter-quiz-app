import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/level_service.dart';
import '../services/database_service.dart';
import '../widgets/attendance_grass_widget.dart'; // 💡 새로 만든 위젯 임포트

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
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _dbService.userDataStream,
        builder: (context, snapshot) {
          int level = 1;
          Map<String, dynamic> attendance = {};

          if (snapshot.hasData && snapshot.data?.data() != null) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            level = LevelService.getLevel(userData['score'] ?? 0);
            attendance = userData['attendance'] as Map<String, dynamic>? ?? {};
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  "나의 수족관",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B69),
                  ),
                ),
                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRoundedBackground(),
                      _buildAnimatedFish(LevelService.getSafeLevel(level)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 잔디 위젯 호출
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "2026년 학습 리포트",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D1B69),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                AttendanceGrassWidget(attendance: attendance), // 🚀 한 줄로 끝!

                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 수족관 UI 디자인 ---
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
      child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
    ),
  );

  Widget _buildAnimatedFish(int level) => AnimatedBuilder(
    animation: _floatController,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, _floatController.value * 20 - 10),
      child: Image.asset('assets/images/fish_$level.png', width: 200),
    ),
  );
}
