class LevelService {
  static const int maxLevel = 10;

  static const Map<int, Map<String, dynamic>> _levelConfig = {
    1: {"name": "금붕어", "minExp": 0, "nextExp": 10, "background": "sea.jpg"},
    2: {"name": "해파리", "minExp": 10, "nextExp": 30, "background": "sea.jpg"},
    3: {"name": "뱀", "minExp": 30, "nextExp": 40, "background": "forest.jpeg"},
    4: {"name": "개구리", "minExp": 40, "nextExp": 50, "background": "pond.jpeg"},
    5: {
      "name": "도마뱀",
      "minExp": 50,
      "nextExp": 60,
      "background": "desert.jpeg",
    },
    6: {"name": "닭", "minExp": 70, "nextExp": 80, "background": "farm.jpeg"},
    7: {
      "name": "양",
      "minExp": 90,
      "nextExp": 100,
      "background": "pasture.jpeg",
    },
    8: {
      "name": "소",
      "minExp": 100,
      "nextExp": 110,
      "background": "pasture.jpeg",
    },
    9: {"name": "말", "minExp": 110, "nextExp": 120, "background": "stall.jpeg"},
    10: {
      "name": "고양이",
      "minExp": 120,
      "nextExp": null,
      "background": "house.jpeg",
    },
  };

  static int getLevel(int exp) {
    int currentLevel = 1;
    _levelConfig.forEach((level, config) {
      if (exp >= config["minExp"]) {
        currentLevel = level;
      }
    });
    return getSafeLevel(currentLevel);
  }

  static String getLevelName(int level) {
    int safeLevel = getSafeLevel(level);
    return _levelConfig[safeLevel]?["name"] ?? "알 수 없음";
  }

  static String getLevelBackground(int level) {
    int safeLevel = getSafeLevel(level);
    String? bg = _levelConfig[safeLevel]?["background"];
    // 💡 삭제한 background.jpg 대신, 레벨 1의 배경인 sea.jpg를 기본값으로 설정합니다.
    return (bg != null && bg.isNotEmpty) ? bg : "sea.jpg";
  }

  static int expUntilNextLevel(int exp) {
    int currentLevel = getLevel(exp);
    int? nextGoal = _levelConfig[currentLevel]?["nextExp"];
    if (nextGoal == null) return 0;
    return nextGoal - exp;
  }

  static double getLevelProgress(int exp) {
    int currentLevel = getLevel(exp);
    var config = _levelConfig[currentLevel]!;
    int min = config["minExp"];
    int? max = config["nextExp"];
    if (max == null) return 1.0;
    return (exp - min) / (max - min);
  }

  static int getSafeLevel(int level) {
    if (level > maxLevel) return maxLevel;
    if (level < 1) return 1;
    return level;
  }
}
