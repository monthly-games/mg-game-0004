import 'package:flutter/foundation.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';
import 'dart:async';

// Game Modes
enum GameMode {
  timed,      // Limited time mode
  endless,    // No time limit
  challenge,  // Special challenges
}

class CafeManager extends ChangeNotifier {
  final GoldManager goldManager;
  final UpgradeManager upgradeManager = GetIt.I<UpgradeManager>();
  final ProgressionManager progression = GetIt.I<ProgressionManager>();
  final AchievementManager achievements = GetIt.I<AchievementManager>();

  Timer? _passiveIncomeTimer;

  // Current Game Mode
  GameMode currentMode = GameMode.timed;
  int timeRemaining = 120; // seconds for timed mode

  // Tycoon State
  int _stars = 0;
  int get stars => _stars;

  // Decor Levels mapped to Upgrades
  int get chairLevel =>
      upgradeManager.getUpgrade('chair_upgrade')?.currentLevel ?? 0;
  int get tableLevel =>
      upgradeManager.getUpgrade('table_upgrade')?.currentLevel ?? 0;

  // Expose Cafe Level (Reputation)
  int get cafeReputationLevel => progression.currentLevel;

  // Ingredients Inventory
  final Map<String, int> ingredients = {
    'bean': 0,
    'milk': 0,
    'sugar': 0,
    'cup': 0,
    'ice': 0,
  };

  // Menu System
  final List<CafeMenu> menus = [];

  // Furniture System (NEW)
  final List<Furniture> furniture = [];

  // Event System (NEW)
  CafeEvent? activeEvent;

  // Staff Management System (NEW)
  final List<Barista> baristas = [];
  final List<StaffSchedule> schedules = [];
  int _hiredBaristaCount = 0;
  int get hiredBaristaCount => _hiredBaristaCount;

  CafeManager({required this.goldManager}) {
    _initializeMenus();
    _initializeFurniture();
    _initializeBaristas();
    _startPassiveIncome();
    _checkEventSchedule();
  }

  void _initializeMenus() {
    menus.add(
      CafeMenu(
        id: 'espresso',
        name: 'Espresso',
        basePrice: 5,
        requiredIngredients: {'bean': 3, 'cup': 1},
        isUnlocked: true,
      ),
    );
    menus.add(
      CafeMenu(
        id: 'latte',
        name: 'Latte',
        basePrice: 12,
        requiredIngredients: {'bean': 2, 'milk': 2, 'cup': 1},
        isUnlocked: false,
      ),
    );
    menus.add(
      CafeMenu(
        id: 'americano',
        name: 'Americano',
        basePrice: 8,
        requiredIngredients: {'bean': 2, 'ice': 2, 'cup': 1},
        isUnlocked: false,
      ),
    );
    menus.add(
      CafeMenu(
        id: 'macchiato',
        name: 'Macchiato',
        basePrice: 15,
        requiredIngredients: {'bean': 2, 'milk': 1, 'sugar': 1, 'cup': 1},
        isUnlocked: false,
      ),
    );
    // NEW: Premium menus
    menus.add(
      CafeMenu(
        id: 'cappuccino',
        name: 'Cappuccino',
        basePrice: 18,
        requiredIngredients: {'bean': 3, 'milk': 2, 'sugar': 1, 'cup': 1},
        isUnlocked: false,
      ),
    );
    menus.add(
      CafeMenu(
        id: 'mocha',
        name: 'Cafe Mocha',
        basePrice: 20,
        requiredIngredients: {'bean': 3, 'milk': 2, 'sugar': 2, 'cup': 1, 'ice': 1},
        isUnlocked: false,
      ),
    );
  }

  // NEW: Furniture system
  void _initializeFurniture() {
    furniture.addAll([
      Furniture(
        id: 'chair_wood',
        name: '나무 의자',
        type: FurnitureType.chair,
        cost: 100,
        incomeBonus: 1.0,
        customerBonus: 1,
      ),
      Furniture(
        id: 'chair_comfort',
        name: '편안한 의자',
        type: FurnitureType.chair,
        cost: 500,
        incomeBonus: 1.2,
        customerBonus: 1,
      ),
      Furniture(
        id: 'table_basic',
        name: '기본 테이블',
        type: FurnitureType.table,
        cost: 200,
        incomeBonus: 1.0,
        customerBonus: 2,
      ),
      Furniture(
        id: 'table_large',
        name: '대형 테이블',
        type: FurnitureType.table,
        cost: 800,
        incomeBonus: 1.3,
        customerBonus: 4,
      ),
      Furniture(
        id: 'decor_plant',
        name: '실내 식물',
        type: FurnitureType.decor,
        cost: 300,
        incomeBonus: 1.1,
        customerBonus: 0,
      ),
      Furniture(
        id: 'decor_art',
        name: '벽걸이 그림',
        type: FurnitureType.decor,
        cost: 600,
        incomeBonus: 1.15,
        customerBonus: 0,
      ),
    ]);
  }

  // NEW: Staff management system
  void _initializeBaristas() {
    baristas.addAll([
      Barista(
        id: 'barista_novice',
        name: '입력 바리스타',
        baseCost: 100,
        level: 1,
        skillTree: BaristaSkillTree(
          speedLevel: 0,
          qualityLevel: 0,
          serviceLevel: 0,
        ),
      ),
      Barista(
        id: 'barista_experienced',
        name: '숙련 바리스타',
        baseCost: 500,
        level: 1,
        skillTree: BaristaSkillTree(
          speedLevel: 0,
          qualityLevel: 0,
          serviceLevel: 0,
        ),
      ),
      Barista(
        id: 'barista_master',
        name: '마스터 바리스타',
        baseCost: 2000,
        level: 1,
        skillTree: BaristaSkillTree(
          speedLevel: 0,
          qualityLevel: 0,
          serviceLevel: 0,
        ),
      ),
    ]);
  }

  // NEW: Game mode switching
  void switchGameMode(GameMode mode) {
    currentMode = mode;
    if (mode == GameMode.timed) {
      timeRemaining = 120;
    }
    notifyListeners();
  }

  // NEW: Event system
  void _checkEventSchedule() {
    // Check for seasonal events
    final now = DateTime.now();
    if (now.month == 12 && now.day >= 20) {
      // Christmas event
      activeEvent = CafeEvent(
        id: 'christmas_2026',
        name: '크리스마스 특별',
        description: '연말 시즌 특별 이벤트!',
        incomeBonus: 1.5,
        customerBonus: 2,
      );
    } else if (now.month == 2 && now.day >= 10) {
      // Valentine's event
      activeEvent = CafeEvent(
        id: 'valentine_2026',
        name: '발렌타인 데이',
        description: '사랑의 커피 시간',
        incomeBonus: 1.3,
        customerBonus: 1,
      );
    }
  }

  // NEW: Purchase furniture
  bool purchaseFurniture(String furnitureId) {
    final item = furniture.firstWhere(
      (f) => f.id == furnitureId,
      orElse: () => furniture.first,
    );

    if (goldManager.currentGold < item.cost) {
      return false;
    }

    goldManager.trySpendGold(item.cost);
    // Apply furniture bonus
    notifyListeners();
    return true;
  }

  // NEW: Hire barista
  bool hireBarista(String baristaId) {
    final barista = baristas.firstWhere(
      (b) => b.id == baristaId,
      orElse: () => baristas.first,
    );

    if (barista.isHired) {
      return false; // Already hired
    }

    if (goldManager.currentGold < barista.baseCost) {
      return false; // Not enough gold
    }

    goldManager.trySpendGold(barista.baseCost);
    barista.isHired = true;
    _hiredBaristaCount++;

    // Create default schedule
    schedules.add(StaffSchedule(
      baristaId: baristaId,
      shiftStart: 9, // 9 AM
      shiftEnd: 17, // 5 PM
      workDays: [1, 2, 3, 4, 5], // Monday to Friday
    ));

    notifyListeners();
    return true;
  }

  // NEW: Train barista skill
  bool trainBaristaSkill(String baristaId, BaristaSkillType skillType) {
    final barista = baristas.firstWhere(
      (b) => b.id == baristaId,
      orElse: () => baristas.first,
    );

    if (!barista.isHired) {
      return false;
    }

    final trainingCost = _getTrainingCost(barista, skillType);
    if (goldManager.currentGold < trainingCost) {
      return false;
    }

    goldManager.trySpendGold(trainingCost);

    // Apply training
    switch (skillType) {
      case BaristaSkillType.speed:
        barista.skillTree.speedLevel++;
        break;
      case BaristaSkillType.quality:
        barista.skillTree.qualityLevel++;
        break;
      case BaristaSkillType.service:
        barista.skillTree.serviceLevel++;
        break;
    }

    barista.level++;
    notifyListeners();
    return true;
  }

  int _getTrainingCost(Barista barista, BaristaSkillType skillType) {
    final baseMultiplier = skillType == BaristaSkillType.speed ? 50 :
                           skillType == BaristaSkillType.quality ? 75 : 60;
    return (barista.level * baseMultiplier).round();
  }

  // NEW: Update staff schedule
  void updateStaffSchedule(String baristaId, int shiftStart, int shiftEnd, List<int> workDays) {
    final scheduleIndex = schedules.indexWhere((s) => s.baristaId == baristaId);
    if (scheduleIndex >= 0) {
      schedules[scheduleIndex] = StaffSchedule(
        baristaId: baristaId,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
        workDays: workDays,
      );
      notifyListeners();
    }
  }

  // NEW: Get active baristas (on schedule)
  List<Barista> getActiveBaristas() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday

    return baristas.where((barista) {
      if (!barista.isHired) return false;

      final schedule = schedules.firstWhere(
        (s) => s.baristaId == barista.id,
        orElse: () => StaffSchedule(baristaId: barista.id, shiftStart: 9, shiftEnd: 17, workDays: []),
      );

      final isOnShift = currentHour >= schedule.shiftStart && currentHour < schedule.shiftEnd;
      final isWorkDay = schedule.workDays.contains(currentWeekday);

      return isOnShift && isWorkDay;
    }).toList();
  }

  // NEW: Calculate staff bonus
  double getStaffBonus() {
    final activeBaristas = getActiveBaristas();
    if (activeBaristas.isEmpty) return 1.0;

    double totalBonus = 1.0;
    for (final barista in activeBaristas) {
      // Each skill level contributes to bonus
      final speedBonus = 1.0 + (barista.skillTree.speedLevel * 0.05);
      final qualityBonus = 1.0 + (barista.skillTree.qualityLevel * 0.08);
      final serviceBonus = 1.0 + (barista.skillTree.serviceLevel * 0.06);
      totalBonus *= (speedBonus * qualityBonus * serviceBonus);
    }

    return totalBonus;
  }

  void addIngredient(String type, int amount) {
    ingredients[type] = (ingredients[type] ?? 0) + amount;
    notifyListeners();
  }

  bool canCook(String menuId) {
    final menu = menus.firstWhere(
      (m) => m.id == menuId,
      orElse: () => menus.first,
    );
    if (!menu.isUnlocked) return false;

    for (var entry in menu.requiredIngredients.entries) {
      if ((ingredients[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  void cookMenu(String menuId) {
    if (!canCook(menuId)) return;

    final menu = menus.firstWhere((m) => m.id == menuId);

    // Consume ingredients
    for (var entry in menu.requiredIngredients.entries) {
      ingredients[entry.key] = ingredients[entry.key]! - entry.value;
    }

    menu.stock += 1;
    notifyListeners();
  }

  bool unlockMenu(String menuId) {
    final menu = menus.firstWhere((m) => m.id == menuId);
    if (menu.isUnlocked) return false;

    menu.isUnlocked = true;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _passiveIncomeTimer?.cancel();
    super.dispose();
  }

  void _startPassiveIncome() {
    _passiveIncomeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _generatePassiveIncome();
    });
  }

  void _generatePassiveIncome() {
    int totalIncome = 0;

    // Base Income from upgrades
    double baseIncome = 0.5 + (chairLevel * 0.5);

    // Event bonus
    double eventMultiplier = activeEvent?.incomeBonus ?? 1.0;

    // Furniture bonus
    double furnitureMultiplier = 1.0;
    for (var f in furniture) {
      if (f.purchased) {
        furnitureMultiplier *= f.incomeBonus;
      }
    }

    // Staff bonus (NEW)
    double staffMultiplier = getStaffBonus();

    // Sales from Stock
    for (var menu in menus.reversed) {
      if (menu.isUnlocked && menu.stock > 0) {
        menu.stock--;
        double multiplier = 1.0 + (tableLevel * 0.1);
        multiplier *= eventMultiplier;
        multiplier *= furnitureMultiplier;
        multiplier *= staffMultiplier; // Apply staff bonus
        totalIncome += (menu.basePrice * multiplier).round();
        break;
      }
    }

    // Add Base Income
    totalIncome += (baseIncome * eventMultiplier * furnitureMultiplier * staffMultiplier).floor();

    if (totalIncome > 0) {
      goldManager.addGold(totalIncome);
      notifyListeners();
    }

    // Update timer for timed mode
    if (currentMode == GameMode.timed && timeRemaining > 0) {
      timeRemaining--;
      if (timeRemaining == 0) {
        // Game over logic
        notifyListeners();
      }
    }
  }

  void addStars(int amount) {
    _stars += amount;
    progression.addXp(amount);
    if (progression.currentLevel >= 5) {
      if (achievements.unlock('cafe_level_5')) {
        // success
      }
    }
    notifyListeners();
  }

  // ... upgrades ...
  bool upgradeChair() {
    return upgradeManager.purchaseUpgrade(
      'chair_upgrade',
      () => goldManager.currentGold,
      (cost) => goldManager.trySpendGold(cost),
    );
  }

  bool upgradeTable() {
    return upgradeManager.purchaseUpgrade(
      'table_upgrade',
      () => goldManager.currentGold,
      (cost) => goldManager.trySpendGold(cost),
    );
  }

  void resetCafe() {
    _stars = 0;
    ingredients.updateAll((key, value) => 0);
    for (var m in menus) {
      m.stock = 0;
      if (m.id != 'espresso') m.isUnlocked = false;
    }
    upgradeManager.setUpgradeLevel('chair_upgrade', 0);
    upgradeManager.setUpgradeLevel('table_upgrade', 0);

    // Reset staff
    for (var b in baristas) {
      b.isHired = false;
      b.level = 1;
      b.skillTree = BaristaSkillTree(speedLevel: 0, qualityLevel: 0, serviceLevel: 0);
    }
    _hiredBaristaCount = 0;
    schedules.clear();

    notifyListeners();
  }
}

class CafeMenu {
  final String id;
  final String name;
  final int basePrice;
  final Map<String, int> requiredIngredients;
  bool isUnlocked;
  int stock;

  CafeMenu({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.requiredIngredients,
    this.isUnlocked = false,
    this.stock = 0,
  });
}

// NEW: Furniture class
class Furniture {
  final String id;
  final String name;
  final FurnitureType type;
  final int cost;
  final double incomeBonus;
  final int customerBonus;
  bool purchased = false;

  Furniture({
    required this.id,
    required this.name,
    required this.type,
    required this.cost,
    required this.incomeBonus,
    required this.customerBonus,
  });
}

enum FurnitureType { chair, table, decor }

// NEW: Event class
class CafeEvent {
  final String id;
  final String name;
  final String description;
  final double incomeBonus;
  final int customerBonus;

  CafeEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.incomeBonus,
    required this.customerBonus,
  });
}

// NEW: Staff management classes
class Barista {
  final String id;
  final String name;
  final int baseCost;
  int level;
  BaristaSkillTree skillTree;
  bool isHired = false;

  Barista({
    required this.id,
    required this.name,
    required this.baseCost,
    required this.level,
    required this.skillTree,
  });

  double getEffectiveness() {
    final baseEffectiveness = 1.0 + (level * 0.1);
    final skillBonus = (skillTree.speedLevel * 0.05) +
                      (skillTree.qualityLevel * 0.08) +
                      (skillTree.serviceLevel * 0.06);
    return baseEffectiveness + skillBonus;
  }
}

class BaristaSkillTree {
  int speedLevel;
  int qualityLevel;
  int serviceLevel;

  BaristaSkillTree({
    required this.speedLevel,
    required this.qualityLevel,
    required this.serviceLevel,
  });

  int get totalLevels => speedLevel + qualityLevel + serviceLevel;
}

enum BaristaSkillType {
  speed,
  quality,
  service,
}

class StaffSchedule {
  final String baristaId;
  final int shiftStart; // Hour (0-23)
  final int shiftEnd;   // Hour (0-23)
  final List<int> workDays; // Weekday numbers (1-7, 1=Monday)

  StaffSchedule({
    required this.baristaId,
    required this.shiftStart,
    required this.shiftEnd,
    required this.workDays,
  });
}
