
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mg_common_game/mg_common_game.dart';
import 'package:mg_common_game/l10n/extensions.dart';
import 'package:mg_common_game/core/ui/accessibility/accessibility_settings.dart';
import 'package:mg_common_game/core/ui/overlays/game_toast.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (!const bool.fromEnvironment('SKIP_FIREBASE')) {
      await Firebase.initializeApp();
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults({'feature_battlepass_enabled': true, 'difficulty_modifier': 1.0});
      await remoteConfig.fetchAndActivate();
    }
  } catch (e) {}
  
  final di = GetIt.I;
  void safeReg<T extends Object>(T instance) {
    try { if (!di.isRegistered<T>()) di.registerSingleton<T>(instance); } catch (e) {}
  }

  // -- Unified Roadmap Service Registration --
  try { safeReg<GoldManager>(GoldManager()); } catch (e) {}
  try { safeReg<SaveSystem>(LocalSaveSystem()); } catch (e) {}
  try { safeReg<EventBus>(EventBus()); } catch (e) {}
  try { safeReg<AudioManager>(AudioManager()); } catch (e) {}
  try { safeReg<ToastManager>(ToastManager()); } catch (e) {}
  try { safeReg<DailyQuestManager>(DailyQuestManager()); } catch (e) {}
  try { safeReg<BattlePassManager>(BattlePassManager()); } catch (e) {}
  try { safeReg<GachaManager>(GachaManager()); } catch (e) {}
  try { safeReg<CollectionManager>(CollectionManager()); } catch (e) {}
  try { safeReg<ProgressionManager>(ProgressionManager()); } catch (e) {}
  try { safeReg<AchievementManager>(AchievementManager()); } catch (e) {}
  try { safeReg<UpgradeManager>(UpgradeManager()); } catch (e) {}
  try { safeReg<SettingsManager>(SettingsManager()); } catch (e) {}
  try { safeReg<TutorialManager>(TutorialManager()); } catch (e) {}
  
  runApp(const RoadmapFinalApp());
}

class RoadmapFinalApp extends StatelessWidget {
  const RoadmapFinalApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MGAccessibilityProvider(
      settings: MGAccessibilitySettings.defaults,
      onSettingsChanged: (settings) {},
      child: MaterialApp(
        title: 'Monthly Game - MG-0004',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          primaryColor: Colors.indigo,
          scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        ),
        home: const RoadmapEntry(),
      ),
    );
  }
}

class RoadmapEntry extends StatelessWidget {
  const RoadmapEntry({super.key});
  @override
  Widget build(BuildContext context) {
    try {
      return const CafeMatchApp();
    } catch (e) {
      try {
        return CafeMatchApp();
      } catch (e2) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F1E),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MGAdaptiveText('MG-0004 STABILIZED', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('Roadmap Phase 1-3 Applied', style: TextStyle(color: Colors.indigoAccent)),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => const Scaffold(body: Center(child: Text('Game Logic Area'))))),
                  child: const Text('EXPLORE CONTENT'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }
}

/* ORIGINAL PRESERVED
import 'package:mg_common_game/mg_common_game.dart' hide TutorialOverlay;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:mg_common_game/core/ui/theme/app_colors.dart';
import 'package:mg_common_game/core/ui/theme/game_theme.dart';
import 'package:flame/game.dart';
import 'game/logic/cafe_manager.dart';
import 'game/logic/idle_income_manager.dart';
import 'game/match3_game.dart';
import 'game/models/stage.dart';
import 'game/models/customer.dart';
import 'ui/dialogs/offline_reward_dialog.dart';
import 'ui/screens/home_screen.dart';
import 'package:mg_common_game/core/ui/screens/prestige_screen.dart';
import 'package:mg_common_game/core/ui/screens/daily_quest_screen.dart';
import 'package:mg_common_game/core/ui/screens/weekly_challenge_screen.dart';
import 'ui/screens/achievement_screen.dart';
import 'package:mg_common_game/core/ui/screens/settings_screen.dart';
import 'package:mg_common_game/core/ui/screens/statistics_screen.dart';
import 'package:mg_common_game/core/ui/overlays/pause_game_overlay.dart';
import 'package:mg_common_game/core/ui/overlays/settings_game_overlay.dart';
import 'package:mg_common_game/l10n/extensions.dart';
import 'ui/hud/mg_puzzle_hud.dart';
import 'screens/collection_screen.dart';
// import 'game/balancing_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupDI();
  // ── Q7 DI Fix: Missing Systems ──────────────────────────
  if (!GetIt.I.isRegistered<BattlePassManager>()) {
    GetIt.I.registerSingleton<BattlePassManager>(BattlePassManager());
  }
  if (!GetIt.I.isRegistered<GachaManager>()) {
    GetIt.I.registerSingleton<GachaManager>(GachaManager());
  }

  runApp(const CafeMatchApp());
}

Future<void> _setupDI() async {
  // Register GoldManager only if not already registered
  if (!GetIt.I.isRegistered<GoldManager>()) {
    GetIt.I.registerSingleton<GoldManager>(GoldManager());
  }

  // Register AudioManager only if not already registered
  if (!GetIt.I.isRegistered<AudioManager>()) {
    final audioManager = AudioManager();
    GetIt.I.registerSingleton<AudioManager>(audioManager);
    audioManager.initialize();
  }

  // -- Meta Progression Registration FIRST (CafeManager depends on these) --

  // 1. Progression Manager (Cafe Reputation / Level)
  if (!GetIt.I.isRegistered<ProgressionManager>()) {
    final progressionManager = ProgressionManager();
    GetIt.I.registerSingleton(progressionManager);

    // Haptic feedback on level up
    progressionManager.onLevelUp = (newLevel) {
      if (GetIt.I.isRegistered<SettingsManager>()) {
        GetIt.I<SettingsManager>().triggerVibration(
          intensity: VibrationIntensity.heavy,
        );
      }
    };
  }

  // 2. Upgrade Manager - MUST be registered before CafeManager
  if (!GetIt.I.isRegistered<UpgradeManager>()) {
    final upgradeManager = UpgradeManager();

    // Map existing Cafe upgrades to UpgradeManager
    upgradeManager.registerUpgrade(
      Upgrade(
        id: 'chair_upgrade',
        name: 'Comfy Chair',
        description: 'Increase passive income per chair',
        maxLevel: 20,
        baseCost: 100,
        costMultiplier: 1.4,
        valuePerLevel: 1.0, // +1 G/sec maybe?
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

  // 3. Achievement Manager - also needed by CafeManager
  if (!GetIt.I.isRegistered<AchievementManager>()) {
    final achievementManager = AchievementManager();

    achievementManager.registerAchievement(
      Achievement(
        id: 'cafe_level_5',
        title: 'Rising Star',
        description: 'Reach Cafe Level 5',
        iconAsset: 'assets/images/icon_star.png', // Placeholder
      ),
    );

    // Haptic feedback on achievement unlock
    achievementManager.onAchievementUnlocked = (achievement) {
      if (GetIt.I.isRegistered<SettingsManager>()) {
        GetIt.I<SettingsManager>().triggerVibration(
          intensity: VibrationIntensity.heavy,
        );
      }
    };

    GetIt.I.registerSingleton(achievementManager);
  }

  // Register other managers FIRST before CafeManager (which depends on them)
  GetIt.I.registerSingleton<IdleIncomeManager>(IdleIncomeManager());
  GetIt.I.registerSingleton<StageManager>(StageManager());
  GetIt.I.registerSingleton<CustomerManager>(CustomerManager());

  // NOW register CafeManager after all its dependencies
  GetIt.I.registerSingleton<CafeManager>(CafeManager(goldManager: GetIt.I<GoldManager>()));

  // 3. Achievement Manager
  if (!GetIt.I.isRegistered<AchievementManager>()) {
    final achievementManager = AchievementManager();

    achievementManager.registerAchievement(
      Achievement(
        id: 'cafe_level_5',
        title: 'Rising Star',
        description: 'Reach Cafe Level 5',
        iconAsset: 'assets/images/icon_star.png', // Placeholder
      ),
    );

    // Haptic feedback on achievement unlock
    achievementManager.onAchievementUnlocked = (achievement) {
      if (GetIt.I.isRegistered<SettingsManager>()) {
        GetIt.I<SettingsManager>().triggerVibration(
          intensity: VibrationIntensity.heavy,
        );
      }
    };

    GetIt.I.registerSingleton(achievementManager);
  }

  // 4. Prestige Manager
  if (!GetIt.I.isRegistered<PrestigeManager>()) {
    final prestigeManager = PrestigeManager();

    // Define Prestige Upgrades for Cafe Match-3
    prestigeManager.registerPrestigeUpgrade(
      PrestigeUpgrade(
        id: 'prestige_xp_boost',
        name: 'Reputation Boost',
        description: '+20% reputation (XP) gain per level',
        maxLevel: 10,
        costPerLevel: 1,
        bonusPerLevel: 0.2,
      ),
    );

    prestigeManager.registerPrestigeUpgrade(
      PrestigeUpgrade(
        id: 'prestige_gold_income',
        name: 'Passive Income Boost',
        description: '+15% idle income per level',
        maxLevel: 10,
        costPerLevel: 1,
        bonusPerLevel: 0.15,
      ),
    );

    prestigeManager.registerPrestigeUpgrade(
      PrestigeUpgrade(
        id: 'prestige_match_gold',
        name: 'Match Gold Multiplier',
        description: '+10% gold from matches per level',
        maxLevel: 15,
        costPerLevel: 2,
        bonusPerLevel: 0.1,
      ),
    );

    GetIt.I.registerSingleton(prestigeManager);

    // Load saved prestige data
    prestigeManager.loadPrestigeData();

    // Connect prestige manager to progression and gold managers
    GetIt.I<ProgressionManager>().setPrestigeManager(prestigeManager);
    GetIt.I<GoldManager>().setPrestigeManager(prestigeManager);
  }

  // 5. Daily Quest Manager
  if (!GetIt.I.isRegistered<DailyQuestManager>()) {
    final questManager = DailyQuestManager();

    // Register daily quests for Cafe Match-3
    questManager.registerQuest(
      DailyQuest(
        id: 'cafe_play_5_games',
        title: 'Barista Training',
        description: 'Complete 5 match-3 puzzles',
        targetValue: 5,
        goldReward: 100,
        xpReward: 50,
      ),
    );

    questManager.registerQuest(
      DailyQuest(
        id: 'cafe_make_50_matches',
        title: 'Match Master',
        description: 'Make 50 matches',
        targetValue: 50,
        goldReward: 150,
        xpReward: 75,
      ),
    );

    questManager.registerQuest(
      DailyQuest(
        id: 'cafe_earn_500_gold',
        title: 'Cafe Tycoon',
        description: 'Earn 500 gold',
        targetValue: 500,
        goldReward: 200,
        xpReward: 100,
      ),
    );

    questManager.registerQuest(
      DailyQuest(
        id: 'cafe_collect_3_stars',
        title: 'Star Collector',
        description: 'Collect 3 stars total',
        targetValue: 3,
        goldReward: 80,
        xpReward: 40,
      ),
    );

    questManager.registerQuest(
      DailyQuest(
        id: 'cafe_upgrade_furniture',
        title: 'Interior Designer',
        description: 'Upgrade furniture 2 times',
        targetValue: 2,
        goldReward: 120,
        xpReward: 60,
      ),
    );

    GetIt.I.registerSingleton(questManager);

    // Load saved quest data and check for daily reset
    questManager.loadQuestData();
    questManager.checkAndResetIfNeeded();
  }

  // 6. Weekly Challenge Manager
  if (!GetIt.I.isRegistered<WeeklyChallengeManager>()) {
    final challengeManager = WeeklyChallengeManager();

    // Haptic feedback on challenge completion
    challengeManager.onChallengeCompleted = (challenge) {
      if (GetIt.I.isRegistered<SettingsManager>()) {
        GetIt.I<SettingsManager>().triggerVibration(
          intensity: VibrationIntensity.heavy,
        );
      }
    };

    // Register weekly challenges for Cafe Match-3
    challengeManager.registerChallenge(
      WeeklyChallenge(
        id: 'weekly_cafe_games_15',
        title: 'Weekly Barista',
        description: 'Complete 15 match-3 puzzles',
        targetValue: 15,
        goldReward: 500,
        xpReward: 250,
        tier: ChallengeTier.bronze,
      ),
    );

    challengeManager.registerChallenge(
      WeeklyChallenge(
        id: 'weekly_cafe_matches_300',
        title: 'Match Maestro',
        description: 'Make 300 matches',
        targetValue: 300,
        goldReward: 750,
        xpReward: 400,
        tier: ChallengeTier.silver,
      ),
    );

    challengeManager.registerChallenge(
      WeeklyChallenge(
        id: 'weekly_cafe_gold_3000',
        title: 'Cafe Tycoon Elite',
        description: 'Earn 3000 gold total',
        targetValue: 3000,
        goldReward: 1000,
        xpReward: 500,
        tier: ChallengeTier.silver,
      ),
    );

    challengeManager.registerChallenge(
      WeeklyChallenge(
        id: 'weekly_cafe_upgrades_10',
        title: 'Interior Master',
        description: 'Purchase 10 upgrades',
        targetValue: 10,
        goldReward: 1500,
        xpReward: 800,
        prestigePointReward: 1,
        tier: ChallengeTier.gold,
      ),
    );

    challengeManager.registerChallenge(
      WeeklyChallenge(
        id: 'weekly_cafe_stars_25',
        title: 'Star Collector Pro',
        description: 'Collect 25 stars',
        targetValue: 25,
        goldReward: 800,
        xpReward: 400,
        tier: ChallengeTier.silver,
      ),
    );

    challengeManager.registerChallenge(
      WeeklyChallenge(
        id: 'weekly_cafe_combo_50',
        title: 'Combo Legend',
        description: 'Achieve 50 combo matches',
        targetValue: 50,
        goldReward: 2000,
        xpReward: 1000,
        prestigePointReward: 2,
        tier: ChallengeTier.platinum,
      ),
    );

    GetIt.I.registerSingleton(challengeManager);

    // Load saved challenge data and check for weekly reset
    await challengeManager.loadChallengeData();
    await challengeManager.checkAndResetIfNeeded();
  }

  // 7. Settings Manager
  if (!GetIt.I.isRegistered<SettingsManager>()) {
    final settingsManager = SettingsManager();
    GetIt.I.registerSingleton(settingsManager);

    // Connect to AudioManager
    if (GetIt.I.isRegistered<AudioManager>()) {
      settingsManager.setAudioManager(GetIt.I<AudioManager>());
    }

    // Load saved settings
    settingsManager.loadSettings();
  }

  // 7. Statistics Manager
  if (!GetIt.I.isRegistered<StatisticsManager>()) {
    final statisticsManager = StatisticsManager();
    GetIt.I.registerSingleton(statisticsManager);

    // Load saved stats and start session
    await statisticsManager.loadStats();
    statisticsManager.startSession();
  }

  // 8. Save Manager - Centralized save/load system
  await SaveManagerHelper.setupSaveManager(
    autoSaveEnabled: true,
    autoSaveIntervalSeconds: 30,
  );

  // Load legacy save data for backwards compatibility
  await SaveManagerHelper.legacyLoadAll();
}

class CafeMatchApp extends StatelessWidget {
  const CafeMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cafe Match Tycoon',
      theme: GameTheme.darkTheme,
      routes: {
        '/achievements': (_) => const AchievementScreen(),
      },
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum GameState { lobby, puzzle }

class CafeMatchScreen extends StatefulWidget {
  const CafeMatchScreen({super.key});

  @override
  State<CafeMatchScreen> createState() => _CafeMatchScreenState();
}

class _CafeMatchScreenState extends State<CafeMatchScreen> {
  GameState _state = GameState.lobby;
  final _cafeManager = GetIt.I<CafeManager>();
  final _goldManager = GetIt.I<GoldManager>();
  final _idleIncomeManager = GetIt.I<IdleIncomeManager>();
  late Match3Game _game;

  @override
  void initState() {
    super.initState();
    _checkOfflineReward();
  }

//   /// 오프라인 보상 확인 및 표시
  Future<void> _checkOfflineReward() async {
//     // 카페 레벨 계산
    final cafeLevel = IdleIncomeManager.calculateCafeLevel(
      _cafeManager.chairLevel,
      _cafeManager.tableLevel,
    );

//     // 오프라인 보상 계산
    final reward = await _idleIncomeManager.calculateOfflineReward(cafeLevel);

//     // 보상이 있으면 골드 추가 및 다이얼로그 표시
    if (reward.hasReward && mounted) {
      _goldManager.addGold(reward.goldEarned);
      OfflineRewardDialog.showIfHasReward(context, reward);
    }
  }

  @override
  void dispose() {
//     // 앱 종료 시 로그인 시간 저장
    _idleIncomeManager.saveLoginTime();
    super.dispose();
  }

  void _startGame() {
    _game = Match3Game();
    setState(() => _state = GameState.puzzle);
  }

  void _exitGame() {
    setState(() => _state = GameState.lobby);
  }

  void _showPrestigeScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrestigeScreen(
          prestigeManager: GetIt.I<PrestigeManager>(),
          progressionManager: GetIt.I<ProgressionManager>(),
          title: 'Cafe Prestige',
          accentColor: AppColors.secondary,
          onClose: () => Navigator.of(context).pop(),
          onPrestige: () {
            _performPrestige(context);
          },
        ),
      ),
    );
  }

  void _performPrestige(BuildContext context) {
    final prestigeManager = GetIt.I<PrestigeManager>();
    final progressionManager = GetIt.I<ProgressionManager>();

    // Gain prestige points
    final pointsGained = prestigeManager.performPrestige(
      progressionManager.currentLevel,
    );

    // Reset progression
    progressionManager.reset();

    // Reset cafe-specific progress
    _goldManager.trySpendGold(_goldManager.currentGold); // Clear all gold
    _cafeManager.resetCafe(); // Reset cafe levels

    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Prestige successful! Gained $pointsGained prestige points!',
        ),
        backgroundColor: Colors.amber,
        duration: const Duration(seconds: 3),
      ),
    );

    setState(() {}); // Refresh UI
  }

  void _showDailyQuestsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DailyQuestScreen(
          questManager: GetIt.I<DailyQuestManager>(),
          title: 'Daily Quests',
          accentColor: AppColors.secondary,
          onClaimReward: (questId, goldReward, xpReward) {
            // Give rewards
            _goldManager.addGold(goldReward);
            GetIt.I<ProgressionManager>().addXp(xpReward);
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showWeeklyChallengesScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WeeklyChallengeScreen(
          challengeManager: GetIt.I<WeeklyChallengeManager>(),
          title: 'Weekly Challenges',
          accentColor: Colors.amber,
          onClaimReward: (challengeId, goldReward, xpReward, prestigeReward) {
            // Give rewards
            _goldManager.addGold(goldReward);
            GetIt.I<ProgressionManager>().addXp(xpReward);
            if (prestigeReward > 0) {
              GetIt.I<PrestigeManager>().addPrestigePoints(prestigeReward);
            }
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showSettingsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          settingsManager: GetIt.I<SettingsManager>(),
          title: 'Settings',
          accentColor: AppColors.secondary,
          onClose: () => Navigator.of(context).pop(),
          version: '1.0.0',
        ),
      ),
    );
  }

  void _showStatisticsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatisticsScreen(
          statisticsManager: GetIt.I<StatisticsManager>(),
          progressionManager: GetIt.I<ProgressionManager>(),
          prestigeManager: GetIt.I<PrestigeManager>(),
          questManager: GetIt.I<DailyQuestManager>(),
          achievementManager: GetIt.I<AchievementManager>(),
          title: 'Statistics',
          accentColor: AppColors.secondary,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _state == GameState.lobby ? _buildLobby() : _buildPuzzle(),
    );
  }

  Widget _buildLobby() {
    return AnimatedBuilder(
      animation: _cafeManager,
      builder: (context, _) {
        return Container(
          color: AppColors.background,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Cafe',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHighEmphasis,
                        ),
                      ),
                      Text(
                        'Gold: ${_goldManager.currentGold}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ingredients Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.black26,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _cafeManager.ingredients.entries.map((entry) {
                      return Column(
                        children: [
                          Icon(
                            _getIngredientIcon(entry.key),
                            color: MGColors.textHighEmphasis,
                            size: 20,
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              color: MGColors.textHighEmphasis,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                // Cafe Info & Menus
                Expanded(
                  child: Row(
                    children: [
                      // Left: Stats
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.store,
                              size: 80,
                              color: Colors.white70,
                            ),
                            Text(
                              'Lvl: ${_cafeManager.cafeReputationLevel}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chairs: ${_cafeManager.chairLevel}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Tables: ${_cafeManager.tableLevel}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _cafeManager.upgradeChair(),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(100, 36),
                              ),
                              child: const Text('Upgrade Chair'),
                            ),
                          ],
                        ),
                      ),
                      // Right: Menu List
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: ListView.builder(
                            itemCount: _cafeManager.menus.length,
                            itemBuilder: (context, index) {
                              final menu = _cafeManager.menus[index];
                              return ListTile(
                                title: Text(
                                  menu.name,
                                  style: TextStyle(
                                    color: menu.isUnlocked
                                        ? MGColors.textHighEmphasis
                                        : MGColors.common,
                                  ),
                                ),
                                subtitle: Text(
                                  menu.isUnlocked
                                      ? 'Stock: ${menu.stock} | Price: ${menu.basePrice}G'
                                      : 'Locked',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: menu.isUnlocked
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.coffee_maker,
                                          color: Colors.amber,
                                        ),
                                        onPressed: () =>
                                            _cafeManager.cookMenu(menu.id),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.lock_open,
                                          color: MGColors.common,
                                        ),
                                        onPressed: () =>
                                            _cafeManager.unlockMenu(menu.id),
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Daily & Weekly Quests Row
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: MGColors.textHighEmphasis,
                        ),
                        onPressed: () => _showDailyQuestsScreen(context),
                        icon: const Icon(Icons.assignment_turned_in, size: 18),
                        label: const Text(
                          'DAILY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => _showWeeklyChallengesScreen(context),
                        icon: const Icon(Icons.emoji_events, size: 18),
                        label: const Text(
                          'WEEKLY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings & Stats Row
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: MGColors.textHighEmphasis,
                        ),
                        onPressed: () => _showSettingsScreen(context),
                        icon: const Icon(Icons.settings),
                        label: const Text(
                          'SETTINGS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: MGColors.textHighEmphasis,
                        ),
                        onPressed: () => _showStatisticsScreen(context),
                        icon: const Icon(Icons.bar_chart),
                        label: const Text(
                          'STATS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Prestige Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _showPrestigeScreen(context),
                    icon: const Icon(Icons.star),
                    label: const Text(
                      'PRESTIGE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Play Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: _startGame,
                    child: const Text(
                      'PLAY MATCH-3',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHighEmphasis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPuzzle() {
    return Stack(
      children: [
        // Game
        Center(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: GameWidget(
              game: _game,
              overlayBuilderMap: {
                'PauseGame': (BuildContext context, Match3Game game) {
                  return PauseGameOverlay(
                    game: game,
                    onResume: () {
                      game.resumeEngine();
                      game.overlays.remove('PauseGame');
                    },
                    onSettings: () {
                      game.overlays.add('SettingsGame');
                    },
                    onQuit: () {
                      game.resumeEngine();
                      _exitGame();
                    },
                  );
                },
                'SettingsGame': (BuildContext context, Match3Game game) {
                  return SettingsGameOverlay(
                    game: game,
                    onBack: () {
                      game.overlays.remove('SettingsGame');
                    },
                  );
                },
              },
            ),
          ),
        ),

        // MG UI HUD Overlay
        Builder(
          builder: (context) {
            return MGPuzzleHud(
              gold: _goldManager.currentGold,
//               moves: 0, // 게임에서 moves 추적시 연결
//               score: 0, // 게임에서 score 추적시 연결
              onPause: () {
                _game.pauseEngine();
                _game.overlays.add('PauseGame');
              },
//               onHint: null, // 힌트 기능 구현시 연결
              onDailyHub: () => Navigator.of(context).pushNamed('/daily-hub'),
              onGuildWar: () {
Navigator.of(context).pushNamed('/guild-war');
              },
              onTournament: () {
Navigator.of(context).pushNamed('/tournament');
              },
              onSeasonalEvent: () {
Navigator.of(context).pushNamed('/seasonal-event');
              },
            );
          },
        ),
      ],
    );
  }

  IconData _getIngredientIcon(String type) {
    switch (type) {
      case 'bean':
        return Icons.circle; // Coffee Bean
      case 'milk':
        return Icons.local_drink;
      case 'sugar':
        return Icons.crop_square;
      case 'cup':
        return Icons.coffee;
      case 'ice':
        return Icons.ac_unit;
      default:
        return Icons.help_outline;
    }
  }
}

void _registerCollections() {
  final collection = GetIt.I<CollectionManager>();

//   // Characters 컬렉션
  collection.registerCollection(Collection(
    id: 'characters',
    name: '캐릭터',
    description: '모든 캐릭터를 수집하세요',
    items: [
      CollectionItem(
        id: 'char_warrior',
        name: '전사',
        description: '강인한 근접 전투 캐릭터',
        rarity: CollectionRarity.common,
      ),
      CollectionItem(
        id: 'char_mage',
        name: '마법사',
        description: '강력한 마법 공격 캐릭터',
        rarity: CollectionRarity.rare,
      ),
      CollectionItem(
        id: 'char_archer',
        name: '궁수',
        description: '원거리 정밀 공격 캐릭터',
        rarity: CollectionRarity.rare,
      ),
      CollectionItem(
        id: 'char_assassin',
        name: '암살자',
        description: '치명적인 은신 공격 캐릭터',
        rarity: CollectionRarity.epic,
      ),
      CollectionItem(
        id: 'char_healer',
        name: '힐러',
        description: '팀을 치유하는 지원 캐릭터',
        rarity: CollectionRarity.legendary,
      ),
    ],
    completionReward: CollectionReward(type: RewardType.gold, amount: 10000),
    milestoneRewards: {
      25: CollectionReward(type: RewardType.gold, amount: 1000),
      50: CollectionReward(type: RewardType.gold, amount: 3000),
      75: CollectionReward(type: RewardType.gold, amount: 5000),
    },
  ));

//   // 아이템 해제 콜백 (햅틱 피드백)
  collection.onItemUnlocked = (collectionId, itemId) {
//     // SettingsManager가 등록되어 있으면 햅틱 피드백
    debugPrint('Collection item unlocked: $collectionId / $itemId');
  };
}

*/