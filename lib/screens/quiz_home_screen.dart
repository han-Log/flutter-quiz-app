import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart';
import '../services/level_service.dart';
import '../services/database_service.dart';

class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _floatController;

  final List<String> _allCategories = [
    "사회",
    "인문",
    "예술",
    "역사",
    "경제",
    "과학",
    "일상",
  ];
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(_allCategories);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double backgroundHeight = screenHeight * 0.35;

    return StreamBuilder<DocumentSnapshot>(
      stream: _dbService.userDataStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
              Positioned(
                top: backgroundHeight - 40,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: _sheetDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
                    child: Column(
                      children: [
                        _buildSlimProfileHeader(userData, currentExp),
                        const SizedBox(height: 15),
                        _buildSlimProgressBar(
                          LevelService.getLevelProgress(currentExp),
                        ),
                        const Spacer(),
                        _buildCategorySelector(),
                        const Spacer(),
                        _buildQuizButton(currentExp),
                        const SizedBox(height: 10),
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

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "어떤 분야의 퀴즈를 풀까요?",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D1B69),
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _allCategories.map((cat) {
            final isSelected = _selectedCategories.contains(cat);
            return FilterChip(
              label: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(cat);
                  } else if (_selectedCategories.length > 1) {
                    _selectedCategories.remove(cat);
                  }
                });
              },
              selectedColor: const Color(0xFF7B61FF),
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFF2F4FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: Colors.grey.shade100),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

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
      top: (h * 0.18) + (_floatController.value * 15),
      left: 0,
      right: 0,
      child: Center(
        child: Image.asset('assets/images/fish_$lvl.png', width: 140),
      ),
    ),
  );

  Widget _buildSlimProfileHeader(Map<String, dynamic> data, int exp) {
    // 💡 에러의 원인 해결: URL이 null이거나 빈 문자열인지 확실히 체크
    String? profileUrl = data['profileUrl'];
    bool hasValidUrl =
        profileUrl != null &&
        profileUrl.isNotEmpty &&
        profileUrl.startsWith('http');

    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFF2F4FF),
          backgroundImage: hasValidUrl
              ? NetworkImage(profileUrl)
              : const AssetImage('assets/images/default_profile.png')
                    as ImageProvider,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['nickname'] ?? "익명",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                LevelService.getLevelName(LevelService.getLevel(exp)),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B69),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "LEVEL",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B61FF),
              ),
            ),
            Text(
              "${LevelService.getLevel(exp)}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B61FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlimProgressBar(double p) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: p,
          minHeight: 10,
          backgroundColor: const Color(0xFFF2F4FF),
          color: const Color(0xFF7B61FF),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "다음 레벨까지 ${((1 - p) * 100).toInt()}% 남음",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    ],
  );

  Widget _buildQuizButton(int exp) => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            initialExp: exp,
            selectedCategories: _selectedCategories,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B61FF),
        elevation: 8,
        // 💡 [2026-02-22] 규칙 적용: withValues 사용
        shadowColor: const Color(0xFF7B61FF).withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        "퀴즈 여행 시작 🚀",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  BoxDecoration _sheetDecoration() => const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(40),
      topRight: Radius.circular(40),
    ),
  );
}
