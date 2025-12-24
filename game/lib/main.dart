import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:mg_common_game/core/ui/theme/game_theme.dart';
import 'package:flame/game.dart';
import 'game/logic/cafe_manager.dart';
import 'game/logic/idle_income_manager.dart';
import 'game/match3_game.dart';
import 'package:mg_common_game/core/audio/audio_manager.dart';
import 'package:mg_common_game/core/ui/theme/app_colors.dart';
import 'ui/dialogs/offline_reward_dialog.dart';
import 'ui/overlays/tutorial_overlay.dart';
import 'package:mg_common_game/systems/progression/progression_manager.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'package:mg_common_game/systems/progression/achievement_manager.dart';
import 'package:mg_common_game/systems/progression/prestige_manager.dart';
import 'package:mg_common_game/core/ui/screens/prestige_screen.dart';
import 'package:mg_common_game/systems/quests/daily_quest.dart';
import 'package:mg_common_game/core/ui/screens/daily_quest_screen.dart';
import 'package:mg_common_game/systems/quests/weekly_challenge.dart';
import 'package:mg_common_game/core/ui/screens/weekly_challenge_screen.dart';
import 'package:mg_common_game/systems/settings/settings_manager.dart';
import 'package:mg_common_game/core/ui/screens/settings_screen.dart';
import 'package:mg_common_game/core/systems/save_manager_helper.dart';
import 'package:mg_common_game/systems/stats/statistics_manager.dart';
import 'package:mg_common_game/core/ui/screens/statistics_screen.dart';
import 'package:mg_common_game/core/ui/overlays/pause_game_overlay.dart';
import 'package:mg_common_game/core/ui/overlays/settings_game_overlay.dart';
import 'ui/hud/mg_puzzle_hud.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _setupDI();
  runApp(const CafeMatchApp());
}

Future<void> _setupDI() async {
  final goldManager = GoldManager();
  GetIt.I.registerSingleton<GoldManager>(goldManager);

  final audioManager = AudioManager();
  GetIt.I.registerSingleton<AudioManager>(audioManager);
  audioManager.initialize();

  GetIt.I.registerSingleton<CafeManager>(CafeManager(goldManager: goldManager));
  GetIt.I.registerSingleton<IdleIncomeManager>(IdleIncomeManager());

  // -- Meta Progression Registration --

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

  // 2. Upgrade Manager
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
    goldManager.setPrestigeManager(prestigeManager);
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
      home: const CafeMatchScreen(),
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
  bool _showTutorial = false;
  late Match3Game _game;

  @override
  void initState() {
    super.initState();
    _checkTutorial();
    _checkOfflineReward();
  }

  Future<void> _checkTutorial() async {
    final hasSeenTutorial = await TutorialOverlay.hasSeenTutorial();
    if (!hasSeenTutorial && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  /// 오프라인 보상 확인 및 표시
  Future<void> _checkOfflineReward() async {
    // 카페 레벨 계산
    final cafeLevel = IdleIncomeManager.calculateCafeLevel(
      _cafeManager.chairLevel,
      _cafeManager.tableLevel,
    );

    // 오프라인 보상 계산
    final reward = await _idleIncomeManager.calculateOfflineReward(cafeLevel);

    // 보상이 있으면 골드 추가 및 다이얼로그 표시
    if (reward.hasReward && mounted) {
      _goldManager.addGold(reward.goldEarned);
      OfflineRewardDialog.showIfHasReward(context, reward);
    }
  }

  @override
  void dispose() {
    // 앱 종료 시 로그인 시간 저장
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
      body: Stack(
        children: [
          _state == GameState.lobby ? _buildLobby() : _buildPuzzle(),
          if (_showTutorial)
            TutorialOverlay(
              onComplete: () {
                setState(() {
                  _showTutorial = false;
                });
              },
            ),
        ],
      ),
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
                      StreamBuilder<int>(
                        stream: _goldManager.onGoldChanged,
                        initialData: _goldManager.currentGold,
                        builder: (_, snapshot) => Text(
                          'Gold: ${snapshot.data}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.secondary,
                          ),
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
                            color: Colors.white,
                            size: 20,
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              color: Colors.white,
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
                                        ? Colors.white
                                        : Colors.grey,
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
                                          color: Colors.grey,
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
                          foregroundColor: Colors.white,
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
                          foregroundColor: Colors.white,
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
                          foregroundColor: Colors.white,
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
        StreamBuilder<int>(
          stream: _goldManager.onGoldChanged,
          initialData: _goldManager.currentGold,
          builder: (context, snapshot) {
            return MGPuzzleHud(
              gold: snapshot.data ?? 0,
              moves: 0, // 게임에서 moves 추적시 연결
              score: 0, // 게임에서 score 추적시 연결
              onPause: () {
                _game.pauseEngine();
                _game.overlays.add('PauseGame');
              },
              onHint: null, // 힌트 기능 구현시 연결
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
