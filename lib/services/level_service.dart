class LevelService {
  static const int maxLevel = 3;

  // 💡 여기서 설정한 숫자들이 기준이 됩니다!
  static const Map<int, Map<String, dynamic>> _levelConfig = {
    1: {"name": "금붕어", "minExp": 0, "nextExp": 10},
    2: {"name": "해파리", "minExp": 10, "nextExp": 30},
    3: {"name": "뱀", "minExp": 30, "nextExp": 40},
    4: {"name": "개구리", "minExp": 40, "nextExp": 50},
    5: {"name": "도마뱀", "minExp": 50, "nextExp": 60},
    6: {"name": "닭", "minExp": 70, "nextExp": 80},
    7: {"name": "양", "minExp": 90, "nextExp": 100},
    8: {"name": "소", "minExp": 100, "nextExp": 110},
    9: {"name": "말", "minExp": 110, "nextExp": 120},
    10: {"name": "고양이", "minExp": 120, "nextExp": null},
  };

  // 1. 점수에 따른 현재 레벨 계산
  // 💡 더 이상 if (exp >= 100) 같은 하드코딩을 하지 않습니다.
  static int getLevel(int exp) {
    int currentLevel = 1;

    // _levelConfig를 돌면서 현재 점수(exp)가 최소 경험치(minExp)보다 높은지 확인합니다.
    _levelConfig.forEach((level, config) {
      if (exp >= config["minExp"]) {
        currentLevel = level;
      }
    });

    return getSafeLevel(currentLevel);
  }

  // 2. 레벨 이름 반환
  static String getLevelName(int level) {
    int safeLevel = getSafeLevel(level);
    return _levelConfig[safeLevel]?["name"] ?? "알 수 없음";
  }

  // 3. 다음 레벨까지 남은 경험치 계산
  static int expUntilNextLevel(int exp) {
    int currentLevel = getLevel(exp);
    int? nextGoal = _levelConfig[currentLevel]?["nextExp"];

    if (nextGoal == null) return 0;
    return nextGoal - exp;
  }

  // 4. 현재 레벨 구간에서의 진척도(0.0 ~ 1.0) 계산
  static double getLevelProgress(int exp) {
    int currentLevel = getLevel(exp);
    var config = _levelConfig[currentLevel]!;

    int min = config["minExp"];
    int? max = config["nextExp"];

    if (max == null) return 1.0;

    return (exp - min) / (max - min);
  }

  // 5. 안전한 레벨 범위 보장
  static int getSafeLevel(int level) {
    if (level > maxLevel) return maxLevel;
    if (level < 1) return 1;
    return level;
  }
}
