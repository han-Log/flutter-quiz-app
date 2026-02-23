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
      // 💡 외부 Container(HomeScreen)에서 이미 마진과 패딩을 주므로 내부 마진은 제거했습니다.
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white, // 👈 배경색을 흰색으로 변경
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

  // 💡 요일 라벨
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

  // 💡 월 라벨
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
              width: 13 * 4.34,
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

  // 💡 잔디 컬럼
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
              int count = attendance[dateStr] ?? 0;

              bool isThisYear = currentDate.year == year;
              bool isFuture = currentDate.isAfter(DateTime.now());

              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: (!isThisYear || isFuture)
                      ? Colors.grey.withValues(alpha: 0.05) // [2026-02-22] 적용
                      : _getGrassColor(count),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Color _getGrassColor(int count) {
    // [2026-02-22] 모든 투명도 처리를 withValues(alpha: ...)로 변경
    if (count <= 0) return Colors.grey.withValues(alpha: 0.15);
    if (count <= 3) return const Color(0xFF7B61FF).withValues(alpha: 0.3);
    if (count <= 8) return const Color(0xFF7B61FF).withValues(alpha: 0.6);
    return const Color(0xFF7B61FF);
  }
}
