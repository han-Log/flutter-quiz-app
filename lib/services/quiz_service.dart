import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/quiz_model.dart';

class QuizService {
  //Gemini API 키
  final _apiKey = dotenv.env['API_KEY'] ?? '키를 찾을 수 없음';

  //카테고리 리스트
  final List<String> categories = ["사회", "인문", "예술", "역사", "경제", "과학", "일상"];

  Future<List<Quiz>> generateQuizzes() async {
    // 💡 현재 안정적으로 작동하는 모델명을 사용합니다.
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

    // 1. 이번 퀴즈 세션에 사용할 카테고리를 무작위로 하나 선택합니다.
    final String selectedCategory =
        categories[Random().nextInt(categories.length)];

    final prompt =
        """
      $selectedCategory 카테고리의 상식 퀴즈 3개를 만들어줘.
      형식은 반드시 아래와 같은 JSON 배열이어야 하며, 다른 설명은 하지마:
      [
        {
          "question": "문제 내용",
          "options": ["보기1", "보기2", "보기3", "보기4"],
          "answerIndex": 0
        }
      ]
      """;

    try {
      final response = await model.generateContent([Content.text(prompt)]);

      // 2. AI 응답에서 JSON 텍스트만 추출합니다.
      String responseText = response.text ?? "[]";
      if (responseText.contains("```json")) {
        responseText = responseText.split("```json")[1].split("```")[0];
      } else if (responseText.contains("```")) {
        responseText = responseText.split("```")[1].split("```")[0];
      }

      final List<dynamic> data = jsonDecode(responseText);

      // 3. 중요: 각 문제(Quiz) 객체에 카테고리 정보를 직접 주입합니다.
      // 이렇게 해야 QuizScreen에서 어느 영역 점수를 올릴지 알 수 있습니다.
      return data.map((item) {
        Map<String, dynamic> quizData = Map<String, dynamic>.from(item);
        quizData['category'] = selectedCategory; // 💡 카테고리 정보 강제 주입
        return Quiz.fromJson(quizData);
      }).toList();
    } catch (e) {
      debugPrint("퀴즈 생성 중 오류 발생: $e");
      // 오류 발생 시 사용자 경험을 위해 빈 리스트 대신 기본 문제를 반환하거나 에러를 던집니다.
      throw Exception("퀴즈를 불러오지 못했습니다.");
    }
  }
}
