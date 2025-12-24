import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import '../../game/logic/cafe_manager.dart';
import '../../game/models/stage.dart';
import 'cafe_screen.dart';
import 'stage_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GoldManager _goldManager;
  late final CafeManager _cafeManager;
  late final StageManager _stageManager;

  @override
  void initState() {
    super.initState();
    _goldManager = GetIt.I<GoldManager>();
    _cafeManager = GetIt.I<CafeManager>();
    _stageManager = GetIt.I<StageManager>();

    _goldManager.addListener(_onUpdate);
    _cafeManager.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _goldManager.removeListener(_onUpdate);
    _cafeManager.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MGColors.primary.withOpacity(0.8),
              MGColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              _buildTopBar(),

              // Main Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(MGSpacing.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cafe Preview
                      _buildCafePreview(),

                      SizedBox(height: MGSpacing.xl),

                      // Main Buttons
                      _buildMainButton(
                        icon: Icons.play_arrow,
                        label: 'Play Stage',
                        color: MGColors.success,
                        onTap: () => _navigateToStageSelect(),
                      ),

                      SizedBox(height: MGSpacing.md),

                      _buildMainButton(
                        icon: Icons.store,
                        label: 'My Cafe',
                        color: MGColors.primary,
                        onTap: () => _navigateToCafe(),
                      ),

                      SizedBox(height: MGSpacing.md),

                      Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryButton(
                              icon: Icons.menu_book,
                              label: 'Menu',
                              onTap: () => _showMenuDialog(),
                            ),
                          ),
                          SizedBox(width: MGSpacing.sm),
                          Expanded(
                            child: _buildSecondaryButton(
                              icon: Icons.inventory_2,
                              label: 'Inventory',
                              onTap: () => _showInventoryDialog(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MGSpacing.md,
        vertical: MGSpacing.sm,
      ),
      child: Row(
        children: [
          // Stars
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MGSpacing.md,
              vertical: MGSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: MGColors.gold, size: 20),
                SizedBox(width: MGSpacing.xs),
                Text(
                  '${_stageManager.totalStars}',
                  style: MGTextStyles.hud.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),

          Spacer(),

          // Gold
          MGResourceBar(
            icon: Icons.monetization_on,
            value: '${_goldManager.currentGold}',
            iconColor: MGColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildCafePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cafe Background
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.brown.shade200,
                    Colors.brown.shade50,
                  ],
                ),
              ),
            ),
          ),

          // Cafe Name
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MGSpacing.md,
                  vertical: MGSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: MGColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'My Cozy Cafe',
                  style: MGTextStyles.title.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),

          // Level Badge
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MGSpacing.sm,
                vertical: MGSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.grade, color: MGColors.gold, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Lv.${_cafeManager.cafeReputationLevel}',
                    style: MGTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Rating Badge
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MGSpacing.sm,
                vertical: MGSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '4.8',
                    style: MGTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            SizedBox(width: MGSpacing.sm),
            Text(
              label,
              style: MGTextStyles.button.copyWith(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: MGColors.textPrimary,
          side: BorderSide(color: MGColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: MGSpacing.xs),
            Text(label, style: MGTextStyles.button),
          ],
        ),
      ),
    );
  }

  void _navigateToStageSelect() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StageSelectScreen()),
    );
  }

  void _navigateToCafe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CafeScreen()),
    );
  }

  void _showMenuDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _cafeManager.menus.map((menu) {
            return ListTile(
              leading: Icon(
                menu.isUnlocked ? Icons.coffee : Icons.lock,
                color: menu.isUnlocked ? MGColors.primary : Colors.grey,
              ),
              title: Text(menu.name),
              subtitle: Text('Price: ${menu.basePrice}G'),
              trailing: menu.isUnlocked
                  ? Text('Stock: ${menu.stock}')
                  : TextButton(
                      onPressed: () {
                        _cafeManager.unlockMenu(menu.id);
                        Navigator.pop(ctx);
                      },
                      child: Text('Unlock'),
                    ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInventoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ingredients'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _cafeManager.ingredients.entries.map((e) {
            return ListTile(
              leading: Icon(_getIngredientIcon(e.key)),
              title: Text(e.key.toUpperCase()),
              trailing: Text('${e.value}'),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getIngredientIcon(String type) {
    switch (type) {
      case 'bean':
        return Icons.grain;
      case 'milk':
        return Icons.water_drop;
      case 'sugar':
        return Icons.square;
      case 'cup':
        return Icons.coffee;
      case 'ice':
        return Icons.ac_unit;
      default:
        return Icons.inventory_2;
    }
  }
}
