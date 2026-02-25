import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/quiz_model.dart';
import '../services/level_service.dart';

class QuizService {
  final _apiKey = dotenv.env['API_KEY'] ?? '';

  Future<List<Quiz>> generateQuizzes(
    List<String> selectedCategories,
    int userLevel,
  ) async {
    // 모델명은 최신 버전인 'gemini-1.5-flash' 혹은 사용 가능한 모델로 확인해 주세요.
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

    final String categoriesString = selectedCategories.join(", ");

    // 💡 난이도 로직 상향 조정
    final double difficultyRatio = userLevel / LevelService.maxLevel;
    String difficultyDescription;

    // 0~30% 구간을 바로 '중학교 수준'으로 설정하여 초기 난이도를 올림
    if (difficultyRatio <= 0.3) {
      difficultyDescription = "보통 (중학생 수준의 교양 및 지식 필요, 단순 상식 이상의 문제)";
    } else if (difficultyRatio <= 0.6) {
      difficultyDescription = "어려움 (고등학교 수준 및 일반 성인 상식, 깊이 있는 지식 필요)";
    } else if (difficultyRatio <= 0.8) {
      difficultyDescription = "매우 어려움 (전문 분야 지식 포함, 까다로운 논리 문제)";
    } else {
      difficultyDescription = "최상 (전문가 수준, 박사급 상식, 고난도의 함정 문제)";
    }

    final prompt =
        """
      당신은 퀴즈 생성 전문가입니다. 사용자의 지적 수준을 고려하여 도전적인 문제를 생성하세요.
      
      [사용자 정보]
      - 현재 레벨: $userLevel / ${LevelService.maxLevel}
      - 권장 난이도: $difficultyDescription
      
      [지시 사항]
      1. 반드시 다음 카테고리 내에서만 출제하세요: [$categoriesString]
      
      2. **중요: 난이도 하한선 설정**
         - 사용자의 레벨이 낮더라도 최소한 '중학교 수준'의 지식이 필요한 문제를 출제하세요.
         - 초등학생 수준이나 너무 당연한 기초 상식(예: 사과는 빨갛다 등)은 절대 금지입니다.
         - 레벨이 올라감에 따라 학술적 용어나 복잡한 인과관계가 포함된 문제를 출제하세요.
      
      3. 문제는 총 3개를 생성하세요.
      4. 결과는 반드시 아래 JSON 형식을 따르며, 다른 설명은 생략하세요.
      
      [JSON 형식]
      [
        {
          "category": "선택된 리스트 중 실제 해당되는 항목명",
          "question": "문제 내용",
          "options": ["보기1", "보기2", "보기3", "보기4"],
          "answerIndex": 0
        }
      ]
      """;

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String responseText = response.text ?? "[]";

      if (responseText.contains("```json")) {
        responseText = responseText.split("```json")[1].split("```")[0];
      } else if (responseText.contains("```")) {
        responseText = responseText.split("```")[1].split("```")[0];
      }

      final List<dynamic> data = jsonDecode(responseText);

      List<Quiz> filteredQuizzes = data
          .map((item) => Quiz.fromJson(Map<String, dynamic>.from(item)))
          .where((quiz) => selectedCategories.contains(quiz.category))
          .toList();

      if (filteredQuizzes.isEmpty && data.isNotEmpty) {
        return data.map((item) {
          var quiz = Quiz.fromJson(Map<String, dynamic>.from(item));
          return Quiz(
            category: selectedCategories[0],
            question: quiz.question,
            options: quiz.options,
            answerIndex: quiz.answerIndex,
          );
        }).toList();
      }

      return filteredQuizzes;
    } catch (e) {
      debugPrint("퀴즈 생성 중 오류 발생: $e");
      throw Exception("퀴즈를 불러오지 못했습니다.");
    }
  }
}
