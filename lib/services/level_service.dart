class LevelService {
  static const int maxLevel = 3; // 최대 레벨 고정

  // 1. 점수에 따른 레벨 계산
  static int getLevel(int exp) {
    if (exp >= 300) return 3;
    if (exp >= 100) return 2;
    return 1;
  }

  // 2. [추가] 다음 레벨까지 남은 경험치 계산 (에러 해결)
  static int expUntilNextLevel(int exp) {
    if (exp >= 300) return 0; // 만렙
    if (exp >= 100) return 300 - exp; // 3레벨까지 남은 점수
    return 100 - exp; // 2레벨까지 남은 점수
  }

  // 3. [추가] 레벨 진척도(0.0 ~ 1.0) 계산 (에러 해결)
  static double getLevelProgress(int exp) {
    if (exp >= 300) return 1.0;
    if (exp >= 100) return (exp - 100) / 200; // 2레벨 구간 진척도
    return exp / 100; // 1레벨 구간 진척도
  }

  // 4. 안전한 레벨 반환 (이미지용)
  static int getSafeLevel(int level) {
    return level > maxLevel ? maxLevel : level;
  }

  // 5. 레벨 이름 반환
  static String getLevelName(int level) {
    int safeLevel = getSafeLevel(level);
    if (safeLevel == 3) return "뱀";
    if (safeLevel == 2) return "해파리";
    return "금붕어";
  }
}
