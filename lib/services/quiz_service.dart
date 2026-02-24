import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/quiz_model.dart';
import '../services/level_service.dart'; // LevelService.maxLevel 참조를 위해 추가

// quiz와 관련된 시스템
class QuizService {
  final _apiKey = dotenv.env['API_KEY'] ?? '';

  /// [userLevel] 파라미터를 추가하여 난이도를 동적으로 조절합니다.
  Future<List<Quiz>> generateQuizzes(
    List<String> selectedCategories,
    int userLevel,
  ) async {
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

    final String categoriesString = selectedCategories.join(", ");

    // 난이도 자동 계산 로직: 최고 레벨 대비 현재 레벨의 비율을 계산
    final double difficultyRatio = userLevel / LevelService.maxLevel;
    String difficultyDescription;

    if (difficultyRatio <= 0.2) {
      difficultyDescription = "아주 쉬움 (기초 상식, 초등학생 수준의 쉬운 단어 사용)";
    } else if (difficultyRatio <= 0.4) {
      difficultyDescription = "쉬움 (일반적인 상식 수준)";
    } else if (difficultyRatio <= 0.7) {
      difficultyDescription = "보통 (중고등학생 수준의 지식 필요)";
    } else if (difficultyRatio <= 0.9) {
      difficultyDescription = "어려움 (전문적인 지식이나 깊이 있는 사고 필요)";
    } else {
      difficultyDescription = "매우 어려움 (해당 분야의 전문가 수준, 까다로운 함정 문제 포함)";
    }

    final prompt =
        """
      당신은 퀴즈 생성 전문가입니다.
      
      [사용자 정보]
      - 현재 레벨: $userLevel / ${LevelService.maxLevel}
      - 권장 난이도: $difficultyDescription
      
      [지시 사항]
      1. 반드시 아래의 카테고리 목록 중에서만 문제를 출제하세요:
         목록: [$categoriesString]
      
      2. 사용자의 레벨에 맞춰 문제를 생성하세요. 
         - 현재 사용자의 난이도는 '$difficultyDescription'입니다. 
         - 레벨이 낮을수록 직관적이고 쉬운 문제를, 레벨이 높을수록 전문 용어가 섞인 복잡한 문제를 내주세요.
      
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

      // 카테고리 필터링 보완
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
