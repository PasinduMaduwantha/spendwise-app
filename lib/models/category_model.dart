import 'package:flutter/material.dart';

enum TransactionType { expense, income }

class SpendCategory {
  final String id;
  final String name;
  final TransactionType type;
  final int iconCodePoint;
  final int colorValue;
  final bool isDefault;

  const SpendCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    required this.colorValue,
    this.isDefault = false,
  });

  /// Const icon registry so Flutter release builds can tree-shake Material Icons cleanly.
  static final Map<int, IconData> _iconRegistry = {
    Icons.cookie.codePoint: Icons.cookie,
    Icons.local_drink.codePoint: Icons.local_drink,
    Icons.shopping_basket.codePoint: Icons.shopping_basket,
    Icons.coffee.codePoint: Icons.coffee,
    Icons.restaurant.codePoint: Icons.restaurant,
    Icons.home.codePoint: Icons.home,
    Icons.directions_car.codePoint: Icons.directions_car,
    Icons.account_balance_wallet.codePoint: Icons.account_balance_wallet,
    Icons.work.codePoint: Icons.work,
    Icons.label_outline.codePoint: Icons.label_outline,
    Icons.category.codePoint: Icons.category,
  };

  Color get color => Color(colorValue);

  IconData get icon => _iconRegistry[iconCodePoint] ?? Icons.category;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'isDefault': isDefault,
      };

  factory SpendCategory.fromMap(Map<String, dynamic> map) => SpendCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        type: TransactionType.values.byName(map['type'] as String? ?? 'expense'),
        iconCodePoint: map['iconCodePoint'] as int? ?? Icons.category.codePoint,
        colorValue: map['colorValue'] as int? ?? 0xFF0F766E,
        isDefault: map['isDefault'] as bool? ?? false,
      );
}
