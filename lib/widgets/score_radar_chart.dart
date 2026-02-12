import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ScoreRadarChart extends StatelessWidget {
  final List<double> scores;

  const ScoreRadarChart({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3, // 그래프의 비율
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: true),

          // 1. 데이터 세트 설정
          dataSets: [
            RadarDataSet(
              fillColor: const Color(
                0xFF7B61FF,
              ).withValues(alpha: 0.25), // 내부 채우기
              borderColor: const Color(0xFF7B61FF), // 테두리 색상
              entryRadius: 3, // 꼭짓점 점 크기
              borderWidth: 2, // 테두리 두께
              dataEntries: scores.map((s) => RadarEntry(value: s)).toList(),
            ),
          ],

          // 2. 외형 및 가이드 라인 설정
          radarShape: RadarShape.polygon, // [중요] 원형이 아닌 칠각형 모양으로 설정
          gridBorderData: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),

          // 3. 내부 구획 설정
          tickCount: 10, // [중요] 내부를 10개 영역으로 나눔
          ticksTextStyle: const TextStyle(
            color: Colors.transparent,
          ), // 수치 텍스트는 숨김
          tickBorderData: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1), // 내부 선들의 색상
            width: 0.5,
          ),

          // 4. 각 영역 라벨 설정
          getTitle: (index, angle) {
            final labels = ['사회', '인문', '예술', '역사', '경제', '과학', '일상'];
            return RadarChartTitle(text: labels[index], angle: 0);
          },
          titlePositionPercentageOffset: 0.15,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
