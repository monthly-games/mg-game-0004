import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'package:mg_common_game/systems/gacha/gacha_pool.dart';import 'package:mg_common_game/l10n/localization.dart';


import '../../features/gacha/gacha_adapter.dart' as gacha_adapter;

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  late final gacha_adapter.DecorationGachaAdapter _gacha;
  List<gacha_adapter.Decoration> _pullResults = [];

  @override
  void initState() {
    super.initState();
    _gacha = GetIt.I<gacha_adapter.DecorationGachaAdapter>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MGColors.surface,
      appBar: AppBar(
        title: const Text("Gacha"),
        backgroundColor: MGColors.primaryAction,
      ),
      body: ListenableBuilder(
        listenable: _gacha,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(MGSpacing.md),
            child: Column(
              children: [
                // Pool header
                _buildPoolHeader(),
                const SizedBox(height: MGSpacing.lg),

                // Pity counter
                _buildPityCounter(),
                const SizedBox(height: MGSpacing.lg),

                // Pull buttons
                _buildPullButtons(),
                const SizedBox(height: MGSpacing.lg),

                // Pull results
                if (_pullResults.isNotEmpty) _buildPullResults(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPoolHeader() {
    return MGCard(
      child: Column(
        children: [
          Text('Cafe Match Tycoon Gacha', style: MGTextStyles.h2),
          const SizedBox(height: MGSpacing.xs),
          Text(
            'Collect decorations to customize your cafe',
            style: MGTextStyles.body.copyWith(color: MGColors.textMediumEmphasis),
          ),
        ],
      ),
    );
  }

  Widget _buildPityCounter() {
    final pityRemaining = _gacha.pullsUntilPity;

    return MGCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Pity Counter', style: MGTextStyles.body),
          Text(
            '$pityRemaining pulls until guaranteed',
            style: MGTextStyles.body.copyWith(
              color: pityRemaining <= 10 ? MGColors.warning : MGColors.textMediumEmphasis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPullButtons() {
    return Column(
      children: [
        MGButton(
          label: "Pull x1",
          onPressed: _pullSingle,
          width: double.infinity,
        ),
        const SizedBox(height: MGSpacing.xs),
        MGButton(
          label: "Pull x10",
          onPressed: _pullTen,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildPullResults() {
    return MGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last Pull Results', style: MGTextStyles.h3),
          const SizedBox(height: MGSpacing.xs),
          ..._pullResults.map((item) => _buildResultItem(item)),
        ],
      ),
    );
  }

  Widget _buildResultItem(gacha_adapter.Decoration item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.star, color: _getRarityColor(item.rarity), size: 20),
          const SizedBox(width: MGSpacing.xs),
          Expanded(
            child: Text(item.name, style: MGTextStyles.body),
          ),
          Text(
            _getRarityLabel(item.rarity),
            style: MGTextStyles.caption.copyWith(
              color: _getRarityColor(item.rarity),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.legendary:
        return MGColors.error;
      case GachaRarity.ultraRare:
        return MGColors.warning;
      case GachaRarity.superRare:
        return MGColors.info;
      case GachaRarity.rare:
        return MGColors.success;
      case GachaRarity.normal:
        return MGColors.textMediumEmphasis;
    }
  }

  String _getRarityLabel(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.legendary:
        return 'UR';
      case GachaRarity.ultraRare:
        return 'SSR';
      case GachaRarity.superRare:
        return 'SR';
      case GachaRarity.rare:
        return 'R';
      case GachaRarity.normal:
        return 'N';
    }
  }

  void _pullSingle() {
    final result = _gacha.pullSingle();
    if (result != null) {
      setState(() {
        _pullResults = [result];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Got"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _pullTen() {
    final results = _gacha.pullTen();
    setState(() {
      _pullResults = results;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("items"),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
