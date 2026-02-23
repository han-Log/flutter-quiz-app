import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart';
import '../services/level_service.dart';
import '../services/database_service.dart';
import 'package:login/theme/app_colors.dart';
import '../widgets/quiz_level_visualizer.dart';

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
    final double visualizerHeight = screenHeight * 0.35;

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
          // 💡 Stack의 복잡한 위치 계산 대신 Column + Expanded 구조로 변경
          body: Column(
            children: [
              // 1. 상단 비주얼 영역 (Stack으로 겹침 효과 유지)
              Stack(
                clipBehavior: Clip.none, // 시트가 위로 올라오도록 설정
                children: [
                  QuizLevelVisualizer(
                    height: visualizerHeight,
                    level: LevelService.getSafeLevel(currentLevel),
                    floatAnimation: _floatController,
                  ),
                  // 시트의 둥근 모서리 부분이 비주얼 영역과 겹치도록 배치
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: _sheetDecoration(),
                    ),
                  ),
                ],
              ),

              // 2. 하단 콘텐츠 영역 (나머지 공간 전체 차지)
              Expanded(
                child: Container(
                  color: AppColors.background,
                  child: SingleChildScrollView(
                    // 💡 화면이 작을 경우를 대비해 스크롤 추가
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
                    child: Column(
                      children: [
                        _buildSlimProfileHeader(userData, currentExp),
                        const SizedBox(height: 15),
                        _buildSlimProgressBar(currentExp),
                        const SizedBox(height: 30),
                        _buildCategorySelector(),
                        const SizedBox(height: 30),
                        _buildQuizButton(currentExp),
                        const SizedBox(height: 20),
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

  // --- 내부 빌드 메서드 (동일) ---

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "어떤 분야의 퀴즈를 풀까요?",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.deepPurple,
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
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected)
                    _selectedCategories.add(cat);
                  else if (_selectedCategories.length > 1)
                    _selectedCategories.remove(cat);
                });
              },
              selectedColor: AppColors.primaryPurple,
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFF2F4FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSlimProfileHeader(Map<String, dynamic> data, int exp) {
    String? profileUrl = data['profileUrl'];
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFF2F4FF),
          backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
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
                style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              Text(
                LevelService.getLevelName(LevelService.getLevel(exp)),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepPurple,
                ),
              ),
            ],
          ),
        ),
        Text(
          "${LevelService.getLevel(exp)}",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildSlimProgressBar(int exp) {
    double progress = LevelService.getLevelProgress(exp);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0xFFF2F4FF),
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "다음 레벨까지 ${LevelService.expUntilNextLevel(exp)} 점 남음",
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ),
      ],
    );
  }

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
        backgroundColor: AppColors.primaryPurple,
        elevation: 8,
        shadowColor: AppColors.primaryPurple.withValues(
          alpha: 0.4,
        ), // 💡 withValues 적용
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
    color: AppColors.background,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(40),
      topRight: Radius.circular(40),
    ),
  );
}
