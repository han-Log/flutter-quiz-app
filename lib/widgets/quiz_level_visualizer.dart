import 'package:flutter/material.dart';
import '../services/level_service.dart'; // LevelService 임포트 확인

class QuizLevelVisualizer extends StatelessWidget {
  final double height;
  final int level;
  final Animation<double> floatAnimation;

  const QuizLevelVisualizer({
    super.key,
    required this.height,
    required this.level,
    required this.floatAnimation,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 LevelService를 통해 배경 파일명을 가져옵니다.
    final String bgName = LevelService.getLevelBackground(level);

    return Stack(
      children: [
        // 1. 레벨별 테마 배경
        SizedBox(
          width: double.infinity,
          height: height,
          child: Image.asset(
            'assets/images/$bgName', // 💡 동적으로 변경됨
            fit: BoxFit.cover,
          ),
        ),

        // 2. 부유 애니메이션 캐릭터
        AnimatedBuilder(
          animation: floatAnimation,
          builder: (context, child) => Positioned(
            top: (height * 0.18) + (floatAnimation.value * 15),
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/level_$level.png',
                width: 140,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.pets, size: 100, color: Colors.white24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
