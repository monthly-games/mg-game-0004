import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_match_tycoon/main.dart';

import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:cafe_match_tycoon/game/logic/cafe_manager.dart';
import 'package:cafe_match_tycoon/game/logic/idle_income_manager.dart';
import 'package:mg_common_game/core/audio/audio_manager.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';

void main() {
  setUp(() {
    // Mock Managers
    if (!GetIt.I.isRegistered<GoldManager>()) {
      GetIt.I.registerSingleton(GoldManager());
    }
    if (!GetIt.I.isRegistered<AudioManager>()) {
      final audio = AudioManager();
      // audio.initialize(); // Skip init in test to avoid loading assets
      GetIt.I.registerSingleton(audio);
    }
    if (!GetIt.I.isRegistered<IdleIncomeManager>()) {
      GetIt.I.registerSingleton(IdleIncomeManager());
    }

    // New Meta Managers
    if (!GetIt.I.isRegistered<ProgressionManager>()) {
      GetIt.I.registerSingleton(ProgressionManager());
    }
    if (!GetIt.I.isRegistered<AchievementManager>()) {
      GetIt.I.registerSingleton(AchievementManager());
    }
    if (!GetIt.I.isRegistered<UpgradeManager>()) {
      final upgradeManager = UpgradeManager();
      // Register necessary upgrades for CafeManager
      upgradeManager.registerUpgrade(
        Upgrade(
          id: 'chair_upgrade',
          name: 'Comfy Chair',
          description: 'Increase passive income per chair',
          maxLevel: 20,
          baseCost: 100,
          costMultiplier: 1.4,
          valuePerLevel: 1.0,
        ),
      );
      upgradeManager.registerUpgrade(
        Upgrade(
          id: 'table_upgrade',
          name: 'Fancy Table',
          description: 'Increase gold capacity',
          maxLevel: 20,
          baseCost: 250,
          costMultiplier: 1.4,
          valuePerLevel: 100.0,
        ),
      );
      GetIt.I.registerSingleton(upgradeManager);
    }

    if (!GetIt.I.isRegistered<CafeManager>()) {
      GetIt.I.registerSingleton(
        CafeManager(goldManager: GetIt.I<GoldManager>()),
      );
    }
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CafeMatchApp());
    expect(find.text('My Cafe'), findsOneWidget);
  });
}
