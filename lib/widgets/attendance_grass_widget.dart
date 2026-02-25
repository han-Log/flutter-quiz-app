import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceGrassWidget extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final int year;

  const AttendanceGrassWidget({
    super.key,
    required this.attendance,
    this.year = 2026,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayLabels(),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFixedMonthLabels(),
                  const SizedBox(height: 8),
                  _buildFixedGrassColumns(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 요일 라벨 (월, 수, 금 표시)
  Widget _buildDayLabels() {
    final days = ['', 'Mon', '', 'Wed', '', 'Fri', ''];
    return Column(
      children: [
        const SizedBox(height: 22),
        ...days.map(
          (day) => Container(
            height: 10,
            margin: const EdgeInsets.only(bottom: 3),
            alignment: Alignment.centerLeft,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 💡 월 라벨 (간격 조정)
  Widget _buildFixedMonthLabels() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return Row(
      children: months
          .map(
            (m) => SizedBox(
              width: 13 * 4.34, // 1주 13px * 한 달 평균 주차
              child: Text(
                m,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // 💡 잔디 컬럼 생성
  Widget _buildFixedGrassColumns() {
    DateTime firstDayOfYear = DateTime(year, 1, 1);
    int adjustment = firstDayOfYear.weekday % 7;
    DateTime startDate = firstDayOfYear.subtract(Duration(days: adjustment));

    return Row(
      children: List.generate(53, (weekIndex) {
        return Container(
          width: 10,
          margin: const EdgeInsets.only(right: 3),
          child: Column(
            children: List.generate(7, (dayIndex) {
              DateTime currentDate = startDate.add(
                Duration(days: (weekIndex * 7) + dayIndex),
              );
              String dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

              // 💡 Firestore에서 가져온 해당 날짜의 퀴즈 해결 수
              int count = attendance[dateStr] ?? 0;

              bool isThisYear = currentDate.year == year;
              bool isFuture = currentDate.isAfter(DateTime.now());

              return Tooltip(
                message: "$dateStr: $count 문제 해결", // 💡 누르면 정보 확인 가능
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(
                    color: (!isThisYear || isFuture)
                        ? Colors.grey.withValues(alpha: 0.05)
                        : _getGrassColor(count),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // 💡 [핵심] 퀴즈 개수에 따른 5단계 색상 로직
  Color _getGrassColor(int count) {
    const baseColor = Color(0xFF7B61FF); // 메인 테마 보라색

    if (count <= 0) {
      return Colors.grey.withValues(alpha: 0.15); // 활동 없음
    } else if (count <= 3) {
      return baseColor.withValues(alpha: 0.2); // 1~3문제: 연함
    } else if (count <= 7) {
      return baseColor.withValues(alpha: 0.45); // 4~7문제: 보통
    } else if (count <= 12) {
      return baseColor.withValues(alpha: 0.75); // 8~12문제: 진함
    } else {
      return baseColor; // 13문제 이상: 아주 진함 (최고 단계)
    }
  }
}
