import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'package:mg_common_game/systems/gacha/gacha_config.dart';

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
      backgroundColor: MGColors.background,
      appBar: AppBar(
        title: const Text('Gacha'),
        backgroundColor: MGColors.primary,
      ),
      body: ListenableBuilder(
        listenable: _gacha,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pool header
                _buildPoolHeader(),
                const SizedBox(height: 24),

                // Pity counter
                _buildPityCounter(),
                const SizedBox(height: 24),

                // Pull buttons
                _buildPullButtons(),
                const SizedBox(height: 24),

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
          const SizedBox(height: 8),
          Text(
            'Collect decorations to customize your cafe',
            style: MGTextStyles.body.copyWith(color: AppColors.textMediumEmphasis),
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
              color: pityRemaining <= 10 ? MGColors.warning : AppColors.textMediumEmphasis,
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
          label: 'Pull x1',
          onPressed: _pullSingle,
          width: double.infinity,
        ),
        const SizedBox(height: 8),
        MGButton(
          label: 'Pull x10',
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
          const SizedBox(height: 8),
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
          const SizedBox(width: 8),
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
      case GachaRarity.ultraRare:
        return MGColors.error;
      case GachaRarity.superSuperRare:
        return MGColors.warning;
      case GachaRarity.superRare:
        return MGColors.info;
      case GachaRarity.rare:
        return MGColors.success;
      default:
        return AppColors.textMediumEmphasis;
    }
  }

  String _getRarityLabel(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.ultraRare:
        return 'UR';
      case GachaRarity.superSuperRare:
        return 'SSR';
      case GachaRarity.superRare:
        return 'SR';
      case GachaRarity.rare:
        return 'R';
      default:
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
          content: Text('Got: ${result.name}!'),
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
        content: Text('Got ${results.length} items!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
