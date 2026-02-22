import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/quiz_model.dart';

class QuizService {
  final _apiKey = dotenv.env['API_KEY'] ?? '';

  Future<List<Quiz>> generateQuizzes(List<String> selectedCategories) async {
    // 💡 gemini-1.5-flash 또는 gemini-2.0-flash-lite 등 최신 모델 권장
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

    // AI가 딴소리 못하게 목록을 명확히 전달
    final String categoriesString = selectedCategories.join(", ");

    final prompt =
        """
      당신은 퀴즈 생성 전문가입니다.
      
      [지시 사항]
      1. 반드시 아래의 카테고리 목록 중에서만 문제를 출제하세요:
         목록: [$categoriesString]
      
      2. 위 목록에 없는 카테고리는 절대로 사용하지 마세요.
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

      // 💡 [추가 보완] AI가 혹시라도 목록에 없는 카테고리를 냈을 경우를 대비해 코드에서 필터링
      List<Quiz> filteredQuizzes = data
          .map((item) => Quiz.fromJson(Map<String, dynamic>.from(item)))
          .where(
            (quiz) => selectedCategories.contains(quiz.category),
          ) // 👈 선택된 카테고리에 포함된 것만 통과
          .toList();

      // 만약 필터링 후 문제가 하나도 없다면, 선택된 것 중 하나로 강제 지정해서라도 반환 (안전장치)
      if (filteredQuizzes.isEmpty && data.isNotEmpty) {
        return data.map((item) {
          var quiz = Quiz.fromJson(Map<String, dynamic>.from(item));
          return Quiz(
            category: selectedCategories[0], // 강제로 선택된 카테고리 중 첫 번째 주입
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
