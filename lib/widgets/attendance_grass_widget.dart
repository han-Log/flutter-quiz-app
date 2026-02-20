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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE8E5FF)),
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

  // 💡 요일 라벨 (월, 수, 금 고정 위치)
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

  // 💡 월 라벨 (Jan ~ Dec)
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

  // 💡 잔디 컬럼 (요일 완벽 교정 로직 포함)
  Widget _buildFixedGrassColumns() {
    DateTime firstDayOfYear = DateTime(year, 1, 1);
    // 깃허브 스타일: 첫 행은 항상 일요일. 1월 1일이 속한 주의 일요일을 시작점으로 잡음
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
                      ? Colors.grey.withOpacity(0.05)
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
    if (count <= 0) return Colors.grey.withOpacity(0.15);
    if (count <= 3) return const Color(0xFF7B61FF).withOpacity(0.3);
    if (count <= 8) return const Color(0xFF7B61FF).withOpacity(0.6);
    return const Color(0xFF7B61FF);
  }
}
