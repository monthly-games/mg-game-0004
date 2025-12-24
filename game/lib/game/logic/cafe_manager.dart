import 'package:flutter/foundation.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';
import 'dart:async';

class CafeManager extends ChangeNotifier {
  final GoldManager goldManager;
  final UpgradeManager upgradeManager = GetIt.I<UpgradeManager>();
  final ProgressionManager progression = GetIt.I<ProgressionManager>();
  final AchievementManager achievements = GetIt.I<AchievementManager>();

  Timer? _passiveIncomeTimer;

  // Tycoon State
  // _stars is now mapped to progression.currentXp or similar,
  // but let's keep _stars for match-3 score and use progression for "Reputation"
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

  CafeManager({required this.goldManager}) {
    _initializeMenus();
    _startPassiveIncome();
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

    // Grant XP or immediate Gold?
    // Design says: Menu Production -> Cafe Operation (Sales).
    // For MVP simplification: Cooking immediately sells for now,
    // OR increases "Stock" which boosts passive income.
    // Let's go with: Cooking adds to "Stock", passive income sells Stock.
    menu.stock += 1;
    notifyListeners();
  }

  bool unlockMenu(String menuId) {
    // Unlock logic (could cost gold or reputation)
    final menu = menus.firstWhere((m) => m.id == menuId);
    if (menu.isUnlocked) return false;

    // Cost logic here... for now free if level met
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
    // Income depends on Active Menus (Stock) and Chair Level.
    // If no stock, low base income (coffee water?)

    int totalIncome = 0;

    // Base Income from upgrades
    double baseIncome = 0.5 + (chairLevel * 0.5);

    // Sales from Stock
    // Each second, try to sell 1 item from highest value unlocked menu with stock
    for (var menu in menus.reversed) {
      if (menu.isUnlocked && menu.stock > 0) {
        // Sell one
        menu.stock--;
        // Income = Menu Price * (1 + Satisfaction/100)
        // Satisfaction approx by Table Level for now
        double multiplier = 1.0 + (tableLevel * 0.1);
        totalIncome += (menu.basePrice * multiplier).round();
        break; // Sell one item per tick (or per chair later)
      }
    }

    // Add Base Income (Tips?)
    totalIncome += baseIncome.floor();

    if (totalIncome > 0) {
      goldManager.addGold(totalIncome);
      notifyListeners();
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
