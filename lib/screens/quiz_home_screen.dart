import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // 💡 intl 패키지 추가 확인
import 'quiz_screen.dart';
import 'search_screen.dart';
import '../services/level_service.dart';
import '../services/database_service.dart';
import '../widgets/ranking_system.dart';
import '../widgets/profile_detail_sheet.dart';

class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _floatController;
  final ScrollController _rankingScrollController = ScrollController();

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
    _rankingScrollController.dispose();
    super.dispose();
  }

  void _openProfile(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(userData: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double backgroundHeight = screenHeight * 0.32;

    return StreamBuilder<DocumentSnapshot>(
      stream: _dbService.userDataStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        int currentExp = userData['score'] ?? 0;
        int currentLevel = LevelService.getLevel(currentExp);

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              _buildBackground(backgroundHeight),
              _buildAnimatedFish(
                LevelService.getSafeLevel(currentLevel),
                backgroundHeight,
              ),
              _buildTopSearchButton(),
              Positioned(
                top: backgroundHeight - 40,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: _sheetDecoration(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _openProfile(userData),
                          child: _buildSlimProfileHeader(userData, currentExp),
                        ),
                        const SizedBox(height: 10),
                        _buildSlimProgressBar(
                          LevelService.getLevelProgress(currentExp),
                        ),
                        const SizedBox(height: 25),
                        _buildScrollableRanking(userData['uid']),
                        const SizedBox(height: 20),
                        _buildQuizButton(currentExp),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- UI Helper Methods (클래스 내부에 포함) ---

  Widget _buildBackground(double h) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    height: h,
    child: Image.asset('assets/images/background.jpg', fit: BoxFit.fill),
  );

  Widget _buildAnimatedFish(int lvl, double h) => AnimatedBuilder(
    animation: _floatController,
    builder: (context, child) => Positioned(
      top: (h * 0.15) + (_floatController.value * 15),
      left: 0,
      right: 0,
      child: Center(
        child: Image.asset('assets/images/fish_$lvl.png', width: 130),
      ),
    ),
  );

  Widget _buildTopSearchButton() => Positioned(
    top: 45,
    right: 20,
    child: CircleAvatar(
      backgroundColor: Colors.black26,
      child: IconButton(
        icon: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        ),
      ),
    ),
  );

  Widget _buildSlimProfileHeader(Map<String, dynamic> data, int exp) => Row(
    children: [
      CircleAvatar(
        radius: 22,
        backgroundImage: data['profileUrl'] != null
            ? NetworkImage(data['profileUrl'])
            : const AssetImage('assets/images/default_profile.png')
                  as ImageProvider,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['nickname'] ?? "익명",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              LevelService.getLevelName(LevelService.getLevel(exp)),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      Text(
        "Lv.${LevelService.getLevel(exp)}",
        style: const TextStyle(
          color: Color(0xFF7B61FF),
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _buildSlimProgressBar(double p) => Row(
    children: [
      const Text(
        "EXP",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7B61FF),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: LinearProgressIndicator(
          value: p,
          minHeight: 6,
          backgroundColor: Colors.black12,
          color: const Color(0xFF7B61FF),
        ),
      ),
      const SizedBox(width: 10),
      Text("${(p * 10).toInt()}%"),
    ],
  );

  Widget _buildScrollableRanking(String? uid) => SizedBox(
    height: 280,
    child: Scrollbar(
      controller: _rankingScrollController,
      child: SingleChildScrollView(
        controller: _rankingScrollController,
        child: RankingSystem(myUid: uid),
      ),
    ),
  );

  Widget _buildQuizButton(int exp) => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuizScreen(initialExp: exp)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B61FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: const Text(
        "퀴즈 시작 🚀",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );

  BoxDecoration _sheetDecoration() => const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(35),
      topRight: Radius.circular(35),
    ),
  );
} // <--- 클래스 닫기
