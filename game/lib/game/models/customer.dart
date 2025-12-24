/// Customer system for Cafe Match Tycoon
library;

import 'dart:math';

enum CustomerMood {
  happy,
  neutral,
  impatient,
  angry,
}

enum CustomerType {
  regular,
  student,
  businessman,
  artist,
  tourist,
  vip,
}

class CustomerOrder {
  final String menuId;
  final String menuName;
  final int quantity;
  bool isFulfilled;

  CustomerOrder({
    required this.menuId,
    required this.menuName,
    this.quantity = 1,
    this.isFulfilled = false,
  });
}

class Customer {
  final String id;
  final String name;
  final CustomerType type;
  final List<CustomerOrder> orders;
  final int patienceSeconds;

  CustomerMood mood;
  int waitedSeconds;
  bool hasLeft;
  int tipAmount;

  Customer({
    required this.id,
    required this.name,
    required this.type,
    required this.orders,
    this.patienceSeconds = 60,
    this.mood = CustomerMood.happy,
    this.waitedSeconds = 0,
    this.hasLeft = false,
    this.tipAmount = 0,
  });

  double get satisfactionRatio =>
      1.0 - (waitedSeconds / patienceSeconds).clamp(0.0, 1.0);

  void tick() {
    if (hasLeft) return;

    waitedSeconds++;

    if (waitedSeconds > patienceSeconds * 0.3) {
      mood = CustomerMood.neutral;
    }
    if (waitedSeconds > patienceSeconds * 0.6) {
      mood = CustomerMood.impatient;
    }
    if (waitedSeconds > patienceSeconds * 0.9) {
      mood = CustomerMood.angry;
    }
    if (waitedSeconds >= patienceSeconds) {
      hasLeft = true;
    }
  }

  bool get allOrdersFulfilled => orders.every((o) => o.isFulfilled);

  int calculateTip(int basePrice) {
    if (mood == CustomerMood.happy) return (basePrice * 0.2).round();
    if (mood == CustomerMood.neutral) return (basePrice * 0.1).round();
    return 0;
  }

  int calculateReviewStars() {
    switch (mood) {
      case CustomerMood.happy:
        return 5;
      case CustomerMood.neutral:
        return 4;
      case CustomerMood.impatient:
        return 3;
      case CustomerMood.angry:
        return 1;
    }
  }
}

class CustomerManager {
  final List<Customer> activeCustomers = [];
  final List<Customer> servedCustomers = [];
  final Random _rng = Random();

  int totalCustomersServed = 0;
  int totalReviewStars = 0;
  int reviewCount = 0;

  double get averageRating =>
      reviewCount > 0 ? totalReviewStars / reviewCount : 5.0;

  final List<String> _names = [
    'Alex', 'Jordan', 'Sam', 'Casey', 'Morgan',
    'Riley', 'Taylor', 'Quinn', 'Avery', 'Parker',
    'Kim', 'Lee', 'Chen', 'Park', 'Yamamoto',
  ];

  final Map<CustomerType, List<String>> _preferredMenus = {
    CustomerType.regular: ['espresso', 'americano'],
    CustomerType.student: ['americano', 'latte'],
    CustomerType.businessman: ['espresso', 'macchiato'],
    CustomerType.artist: ['latte', 'macchiato'],
    CustomerType.tourist: ['latte', 'espresso'],
    CustomerType.vip: ['macchiato', 'latte'],
  };

  final Map<String, String> _menuNames = {
    'espresso': 'Espresso',
    'latte': 'Latte',
    'americano': 'Americano',
    'macchiato': 'Macchiato',
  };

  Customer? spawnCustomer({List<String>? availableMenus}) {
    if (activeCustomers.length >= 5) return null;

    final type = CustomerType.values[_rng.nextInt(CustomerType.values.length)];
    final name = _names[_rng.nextInt(_names.length)];

    // Pick a menu this customer type prefers
    final preferred = _preferredMenus[type] ?? ['espresso'];
    String menuId = preferred[_rng.nextInt(preferred.length)];

    // If menu not available, default to espresso
    if (availableMenus != null && !availableMenus.contains(menuId)) {
      menuId = availableMenus.isNotEmpty ? availableMenus.first : 'espresso';
    }

    final customer = Customer(
      id: 'customer_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      orders: [
        CustomerOrder(
          menuId: menuId,
          menuName: _menuNames[menuId] ?? menuId,
        ),
      ],
      patienceSeconds: 45 + _rng.nextInt(30),
    );

    activeCustomers.add(customer);
    return customer;
  }

  void tick() {
    for (final customer in activeCustomers.toList()) {
      customer.tick();
      if (customer.hasLeft && !customer.allOrdersFulfilled) {
        // Customer left unhappy
        activeCustomers.remove(customer);
        _addReview(customer);
      }
    }
  }

  bool serveCustomer(String customerId, String menuId) {
    final customer = activeCustomers.firstWhere(
      (c) => c.id == customerId,
      orElse: () => throw Exception('Customer not found'),
    );

    for (final order in customer.orders) {
      if (order.menuId == menuId && !order.isFulfilled) {
        order.isFulfilled = true;
        break;
      }
    }

    if (customer.allOrdersFulfilled) {
      activeCustomers.remove(customer);
      servedCustomers.add(customer);
      totalCustomersServed++;
      _addReview(customer);
      return true;
    }

    return false;
  }

  void _addReview(Customer customer) {
    final stars = customer.calculateReviewStars();
    totalReviewStars += stars;
    reviewCount++;
  }

  void clear() {
    activeCustomers.clear();
  }
}
