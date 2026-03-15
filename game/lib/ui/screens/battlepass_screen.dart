import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'package:mg_common_game/systems/battlepass/battlepass_config.dart';

import '../../features/battlepass/battlepass_adapter.dart';

class BattlepassScreen extends StatefulWidget {
  const BattlepassScreen({super.key});

  @override
  State<BattlepassScreen> createState() => _BattlepassScreenState();
}

class _BattlepassScreenState extends State<BattlepassScreen> {
  late final CafeBattlePass _battlepass;

  @override
  void initState() {
    super.initState();
    _battlepass = GetIt.I<CafeBattlePass>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MGColors.surface,
      appBar: AppBar(
        title: const Text('Battle Pass'),
        backgroundColor: MGColors.primary,
      ),
      body: ListenableBuilder(
        listenable: _battlepass,
        builder: (context, _) {
          final season = _battlepass.currentSeason;
          if (season == null) {
            return Center(
              child: Text(
                'No active season',
                style: MGTextStyles.body,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Season header
                _buildSeasonHeader(season),
                const SizedBox(height: 24),

                // Progress indicator
                _buildProgressSection(season),
                const SizedBox(height: 24),

                // Missions
                _buildMissionsSection(),
                const SizedBox(height: 24),

                // Premium upgrade button
                if (!_battlepass.isPremium)
                  _buildPremiumUpgradeButton(season),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeasonHeader(BPSeasonConfig season) {
    return MGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(season.nameKr, style: MGTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Ends: ${_formatDate(season.endDate)}',
            style: MGTextStyles.body.copyWith(color: AppColors.textMediumEmphasis),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BPSeasonConfig season) {
    final currentLevel = _battlepass.currentLevel;
    final currentExp = _battlepass.currentExp;
    final expForLevel = season.expPerLevel;
    final progress = currentExp / expForLevel;

    return MGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $currentLevel', style: MGTextStyles.h3),
              Text(
                '$currentExp / $expForLevel XP',
                style: MGTextStyles.body.copyWith(color: AppColors.textMediumEmphasis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: MGLinearProgress(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.textMediumEmphasis.withValues(alpha: 0.2),
              valueColor: MGColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsSection() {
    final dailyMissions = _battlepass.dailyMissions;
    final weeklyMissions = _battlepass.weeklyMissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dailyMissions.isNotEmpty) ...[
          Text('Daily Missions', style: MGTextStyles.h3),
          const SizedBox(height: 8),
          ...dailyMissions.map((mission) => _buildMissionCard(mission)),
          const SizedBox(height: 16),
        ],
        if (weeklyMissions.isNotEmpty) ...[
          Text('Weekly Missions', style: MGTextStyles.h3),
          const SizedBox(height: 8),
          ...weeklyMissions.map((mission) => _buildMissionCard(mission)),
        ],
      ],
    );
  }

  Widget _buildMissionCard(BPMission mission) {
    final missionProgress = 0; // TODO: Get from mission progress tracker

    return MGCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.titleKr, style: MGTextStyles.body),
                const SizedBox(height: 4),
                Text(
                  '$missionProgress / ${mission.targetValue}',
                  style: MGTextStyles.caption.copyWith(color: AppColors.textMediumEmphasis),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 32,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: MGLinearProgress(
                value: (missionProgress / mission.targetValue).clamp(0.0, 1.0),
                backgroundColor: AppColors.textMediumEmphasis.withValues(alpha: 0.2),
                valueColor: MGColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumUpgradeButton(BPSeasonConfig season) {
    return MGButton(
      label: 'Upgrade to Premium',
      onPressed: _upgradeToPremium,
      width: double.infinity,
    );
  }

  void _upgradeToPremium() {
    _battlepass.purchasePremium();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Premium unlocked!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
