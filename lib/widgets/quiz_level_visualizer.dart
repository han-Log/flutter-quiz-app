import 'package:flutter/material.dart';

///  성장에 따라 변화하는 배경과 캐릭터를 시각화하는 위젯
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
    return Stack(
      children: [
        // 1. 레벨별 테마 배경 (현재는 공통 background.jpg)
        SizedBox(
          width: double.infinity,
          height: height,
          child: Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover, // fill보다 자연스럽게 채워줍니다.
          ),
        ),

        // 2. 부유 애니메이션이 적용된 캐릭터 (물고기, 해파리, 뱀 등)
        AnimatedBuilder(
          animation: floatAnimation,
          builder: (context, child) => Positioned(
            // 캐릭터의 높낮이를 애니메이션 값에 따라 조절
            top: (height * 0.18) + (floatAnimation.value * 15),
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/level_$level.png', // 파일명 규칙은 유지하되 위젯 이름은 범용적으로 변경
                width: 140,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
