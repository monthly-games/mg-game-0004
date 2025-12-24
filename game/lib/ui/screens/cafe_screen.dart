import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import '../../game/logic/cafe_manager.dart';
import '../../game/models/customer.dart';

class CafeScreen extends StatefulWidget {
  const CafeScreen({super.key});

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> with TickerProviderStateMixin {
  late final CafeManager _cafeManager;
  late final GoldManager _goldManager;
  late final CustomerManager _customerManager;

  @override
  void initState() {
    super.initState();
    _cafeManager = GetIt.I<CafeManager>();
    _goldManager = GetIt.I<GoldManager>();
    _customerManager = GetIt.I<CustomerManager>();

    _cafeManager.addListener(_onUpdate);
    _goldManager.addListener(_onUpdate);

    // Spawn initial customer
    _customerManager.spawnCustomer(
      availableMenus: _cafeManager.menus
          .where((m) => m.isUnlocked)
          .map((m) => m.id)
          .toList(),
    );
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cafeManager.removeListener(_onUpdate);
    _goldManager.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Cafe'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: MGSpacing.md),
            child: MGResourceBar(
              icon: Icons.monetization_on,
              value: '${_goldManager.currentGold}',
              iconColor: MGColors.gold,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown.shade100,
              Colors.brown.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // Cafe Stats
            _buildCafeStats(),

            // Customers
            Expanded(
              flex: 2,
              child: _buildCustomerArea(),
            ),

            // Kitchen / Crafting
            Expanded(
              flex: 3,
              child: _buildKitchenArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeStats() {
    return Container(
      margin: EdgeInsets.all(MGSpacing.sm),
      padding: EdgeInsets.all(MGSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.star,
            label: 'Rating',
            value: '${_customerManager.averageRating.toStringAsFixed(1)}',
            color: Colors.amber,
          ),
          _buildStatItem(
            icon: Icons.people,
            label: 'Served',
            value: '${_customerManager.totalCustomersServed}',
            color: MGColors.primary,
          ),
          _buildStatItem(
            icon: Icons.grade,
            label: 'Level',
            value: 'Lv.${_cafeManager.cafeReputationLevel}',
            color: MGColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: MGTextStyles.title.copyWith(
            color: MGColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: MGTextStyles.caption.copyWith(
            color: MGColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerArea() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: MGSpacing.sm),
      padding: EdgeInsets.all(MGSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.brown),
              SizedBox(width: MGSpacing.xs),
              Text('Customers', style: MGTextStyles.subtitle),
              Spacer(),
              TextButton.icon(
                onPressed: () {
                  _customerManager.spawnCustomer(
                    availableMenus: _cafeManager.menus
                        .where((m) => m.isUnlocked)
                        .map((m) => m.id)
                        .toList(),
                  );
                  setState(() {});
                },
                icon: Icon(Icons.add, size: 16),
                label: Text('Call'),
              ),
            ],
          ),
          Expanded(
            child: _customerManager.activeCustomers.isEmpty
                ? Center(
                    child: Text(
                      'No customers yet',
                      style: MGTextStyles.caption,
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _customerManager.activeCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _customerManager.activeCustomers[index];
                      return _buildCustomerCard(customer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Container(
      width: 120,
      margin: EdgeInsets.only(right: MGSpacing.sm),
      padding: EdgeInsets.all(MGSpacing.sm),
      decoration: BoxDecoration(
        color: _getMoodColor(customer.mood).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getMoodColor(customer.mood)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getMoodIcon(customer.mood),
            color: _getMoodColor(customer.mood),
            size: 28,
          ),
          SizedBox(height: 4),
          Text(
            customer.name,
            style: MGTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            customer.orders.first.menuName,
            style: MGTextStyles.caption.copyWith(fontSize: 10),
          ),
          SizedBox(height: 4),
          // Patience bar
          LinearProgressIndicator(
            value: customer.satisfactionRatio,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(_getMoodColor(customer.mood)),
          ),
          SizedBox(height: 4),
          // Serve button
          if (_cafeManager.menus.any(
            (m) => m.id == customer.orders.first.menuId && m.stock > 0,
          ))
            SizedBox(
              height: 24,
              child: ElevatedButton(
                onPressed: () => _serveCustomer(customer),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: MGColors.success,
                ),
                child: Text('Serve', style: TextStyle(fontSize: 10)),
              ),
            ),
        ],
      ),
    );
  }

  Color _getMoodColor(CustomerMood mood) {
    switch (mood) {
      case CustomerMood.happy:
        return Colors.green;
      case CustomerMood.neutral:
        return Colors.orange;
      case CustomerMood.impatient:
        return Colors.deepOrange;
      case CustomerMood.angry:
        return Colors.red;
    }
  }

  IconData _getMoodIcon(CustomerMood mood) {
    switch (mood) {
      case CustomerMood.happy:
        return Icons.sentiment_very_satisfied;
      case CustomerMood.neutral:
        return Icons.sentiment_neutral;
      case CustomerMood.impatient:
        return Icons.sentiment_dissatisfied;
      case CustomerMood.angry:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  void _serveCustomer(Customer customer) {
    final menuId = customer.orders.first.menuId;
    final menu = _cafeManager.menus.firstWhere((m) => m.id == menuId);

    if (menu.stock > 0) {
      menu.stock--;
      _customerManager.serveCustomer(customer.id, menuId);

      // Give gold
      final tip = customer.calculateTip(menu.basePrice);
      _goldManager.addGold(menu.basePrice + tip);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Served ${customer.name}! +${menu.basePrice + tip}G',
          ),
          duration: Duration(seconds: 1),
        ),
      );

      setState(() {});
    }
  }

  Widget _buildKitchenArea() {
    return Container(
      margin: EdgeInsets.all(MGSpacing.sm),
      padding: EdgeInsets.all(MGSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.kitchen, color: Colors.brown),
              SizedBox(width: MGSpacing.xs),
              Text('Kitchen', style: MGTextStyles.subtitle),
            ],
          ),
          SizedBox(height: MGSpacing.sm),

          // Ingredients
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _cafeManager.ingredients.entries.map((e) {
              return Column(
                children: [
                  Icon(_getIngredientIcon(e.key), size: 20),
                  Text('${e.value}', style: MGTextStyles.caption),
                ],
              );
            }).toList(),
          ),

          SizedBox(height: MGSpacing.sm),

          // Menu cards
          Expanded(
            child: ListView.builder(
              itemCount: _cafeManager.menus.length,
              itemBuilder: (context, index) {
                final menu = _cafeManager.menus[index];
                return _buildMenuCard(menu);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(CafeMenu menu) {
    final canCook = _cafeManager.canCook(menu.id);

    return Container(
      margin: EdgeInsets.only(bottom: MGSpacing.xs),
      padding: EdgeInsets.all(MGSpacing.sm),
      decoration: BoxDecoration(
        color: menu.isUnlocked ? Colors.brown.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: menu.isUnlocked ? Colors.brown.shade200 : Colors.grey,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Icon(
            Icons.coffee,
            color: menu.isUnlocked ? Colors.brown : Colors.grey,
          ),
          SizedBox(width: MGSpacing.sm),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  style: MGTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: menu.isUnlocked ? null : Colors.grey,
                  ),
                ),
                Text(
                  '${menu.basePrice}G | Stock: ${menu.stock}',
                  style: MGTextStyles.caption,
                ),
              ],
            ),
          ),

          // Action
          if (!menu.isUnlocked)
            TextButton(
              onPressed: () {
                _cafeManager.unlockMenu(menu.id);
                setState(() {});
              },
              child: Text('Unlock'),
            )
          else
            ElevatedButton(
              onPressed: canCook
                  ? () {
                      _cafeManager.cookMenu(menu.id);
                      setState(() {});
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canCook ? MGColors.primary : Colors.grey,
              ),
              child: Text('Cook'),
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
