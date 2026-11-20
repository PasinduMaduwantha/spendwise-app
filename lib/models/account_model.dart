enum AccountType { cash, debitCard, creditCard, bank, digitalWallet }

class SpendAccount {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final int colorValue;

  const SpendAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.colorValue,
  });

  String get typeLabel {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.debitCard:
        return 'Debit Card';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.digitalWallet:
        return 'Digital Wallet';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'initialBalance': initialBalance,
        'colorValue': colorValue,
      };

  factory SpendAccount.fromMap(Map<String, dynamic> map) => SpendAccount(
        id: map['id'] as String,
        name: map['name'] as String,
        type: AccountType.values.byName(map['type'] as String? ?? 'cash'),
        initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
        colorValue: map['colorValue'] as int? ?? 0xFF0EA5E9,
      );
}
