/// Stage/Level system for Cafe Match Tycoon
library;

enum StageGoalType {
  collectIngredients,
  reachScore,
  serveCustomers,
  clearBlocks,
}

class StageGoal {
  final StageGoalType type;
  final String? ingredientType;
  final int targetAmount;
  int currentAmount;

  StageGoal({
    required this.type,
    this.ingredientType,
    required this.targetAmount,
    this.currentAmount = 0,
  });

  bool get isCompleted => currentAmount >= targetAmount;

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);

  String get displayText {
    switch (type) {
      case StageGoalType.collectIngredients:
        return '$ingredientType: $currentAmount/$targetAmount';
      case StageGoalType.reachScore:
        return 'Score: $currentAmount/$targetAmount';
      case StageGoalType.serveCustomers:
        return 'Customers: $currentAmount/$targetAmount';
      case StageGoalType.clearBlocks:
        return 'Cleared: $currentAmount/$targetAmount';
    }
  }
}

class Stage {
  final int id;
  final String name;
  final int maxMoves;
  final List<StageGoal> goals;
  final int starThreshold1;
  final int starThreshold2;
  final int starThreshold3;

  int movesUsed = 0;
  int score = 0;
  bool isCompleted = false;
  int starsEarned = 0;

  Stage({
    required this.id,
    required this.name,
    required this.maxMoves,
    required this.goals,
    this.starThreshold1 = 1000,
    this.starThreshold2 = 2000,
    this.starThreshold3 = 3500,
  });

  int get movesRemaining => maxMoves - movesUsed;

  bool get allGoalsCompleted => goals.every((g) => g.isCompleted);

  int calculateStars() {
    if (!allGoalsCompleted) return 0;
    if (score >= starThreshold3) return 3;
    if (score >= starThreshold2) return 2;
    if (score >= starThreshold1) return 1;
    return 1;
  }

  void useMove() {
    movesUsed++;
  }

  void addScore(int points) {
    score += points;
  }

  void addGoalProgress(StageGoalType type, {String? ingredientType, int amount = 1}) {
    for (final goal in goals) {
      if (goal.type == type) {
        if (type == StageGoalType.collectIngredients) {
          if (goal.ingredientType == ingredientType) {
            goal.currentAmount += amount;
          }
        } else {
          goal.currentAmount += amount;
        }
      }
    }
  }
}

class StageManager {
  final List<Stage> stages = [];
  int currentStageIndex = 0;
  int highestUnlockedStage = 0;

  StageManager() {
    _initializeStages();
  }

  void _initializeStages() {
    // Chapter 1: Tutorial
    stages.add(Stage(
      id: 1,
      name: 'First Day',
      maxMoves: 20,
      goals: [
        StageGoal(type: StageGoalType.reachScore, targetAmount: 500),
      ],
      starThreshold1: 500,
      starThreshold2: 800,
      starThreshold3: 1200,
    ));

    stages.add(Stage(
      id: 2,
      name: 'Coffee Beans',
      maxMoves: 18,
      goals: [
        StageGoal(type: StageGoalType.collectIngredients, ingredientType: 'bean', targetAmount: 10),
      ],
      starThreshold1: 600,
      starThreshold2: 1000,
      starThreshold3: 1500,
    ));

    stages.add(Stage(
      id: 3,
      name: 'Milk Run',
      maxMoves: 18,
      goals: [
        StageGoal(type: StageGoalType.collectIngredients, ingredientType: 'milk', targetAmount: 10),
      ],
      starThreshold1: 600,
      starThreshold2: 1000,
      starThreshold3: 1500,
    ));

    stages.add(Stage(
      id: 4,
      name: 'Sweet Treat',
      maxMoves: 20,
      goals: [
        StageGoal(type: StageGoalType.collectIngredients, ingredientType: 'bean', targetAmount: 8),
        StageGoal(type: StageGoalType.collectIngredients, ingredientType: 'sugar', targetAmount: 8),
      ],
      starThreshold1: 800,
      starThreshold2: 1200,
      starThreshold3: 1800,
    ));

    stages.add(Stage(
      id: 5,
      name: 'First Customer',
      maxMoves: 25,
      goals: [
        StageGoal(type: StageGoalType.reachScore, targetAmount: 1500),
      ],
      starThreshold1: 1500,
      starThreshold2: 2000,
      starThreshold3: 3000,
    ));

    // Chapter 2: Expansion
    for (int i = 6; i <= 20; i++) {
      stages.add(Stage(
        id: i,
        name: 'Stage $i',
        maxMoves: 15 + (i ~/ 5) * 2,
        goals: [
          StageGoal(type: StageGoalType.reachScore, targetAmount: 1000 + i * 200),
          if (i % 3 == 0)
            StageGoal(type: StageGoalType.collectIngredients, ingredientType: 'bean', targetAmount: 5 + i),
        ],
        starThreshold1: 1000 + i * 200,
        starThreshold2: 1500 + i * 250,
        starThreshold3: 2000 + i * 350,
      ));
    }
  }

  Stage? get currentStage =>
      currentStageIndex < stages.length ? stages[currentStageIndex] : null;

  bool isStageUnlocked(int index) => index <= highestUnlockedStage;

  void completeCurrentStage(int stars) {
    if (currentStage != null) {
      currentStage!.isCompleted = true;
      currentStage!.starsEarned = stars;
      if (currentStageIndex == highestUnlockedStage &&
          highestUnlockedStage < stages.length - 1) {
        highestUnlockedStage++;
      }
    }
  }

  void selectStage(int index) {
    if (isStageUnlocked(index) && index < stages.length) {
      currentStageIndex = index;
      // Reset stage state
      final stage = stages[index];
      stage.movesUsed = 0;
      stage.score = 0;
      for (final goal in stage.goals) {
        goal.currentAmount = 0;
      }
    }
  }

  int get totalStars => stages.fold(0, (sum, s) => sum + s.starsEarned);
}
