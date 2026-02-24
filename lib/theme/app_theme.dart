import 'package:flutter/material.dart';

class AppColors {
  // 메인 브랜드 컬러
  static const Color primaryPurple = Color(0xFF7B61FF);
  static const Color deepPurple = Color(0xFF2D1B69);

  // Text Color
  static const Color titleTextColor = Color.fromARGB(255, 0, 0, 0);
  static const Color explainTextColor = AppColors.textGrey;
  // 상태 표시 컬러
  static const Color infoBlue = Colors.blue;
  static const Color infoGreen = Colors.green;
  static const Color infoOrange = Colors.orange;

  // 배경 및 무채색
  static const Color background = Colors.white;
  static const Color textGrey = Colors.grey;

  // 그림자 전용 (withValues 활용)
  static Color shadowColor = const Color(0xFF2D1B69).withValues(alpha: 0.1);
}

class AppDesign {
  // 기본 카드 곡률
  static const double cardRadiusValue = 25.0;

  // BorderRadius 객체 자체를 상수로 등록 (더 편리함)
  static final BorderRadius cardRadius = BorderRadius.circular(cardRadiusValue);
}
