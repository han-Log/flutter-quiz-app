class Quiz {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String category; // 💡 추가: 어느 영역 문제인지 저장

  Quiz({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.category, // 💡 추가
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      question: json['question'],
      options: List<String>.from(json['options']),
      answerIndex: json['answerIndex'] is int
          ? json['answerIndex']
          : int.parse(json['answerIndex'].toString()),
      category: json['category'] ?? '일반', // 💡 추가 (기본값 설정)
    );
  }
}
