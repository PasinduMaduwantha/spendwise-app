enum BudgetPeriod { weekly, monthly }

class CategoryBudget {
  final String id;
  final String categoryId;
  final double limitAmount;
  final BudgetPeriod period;
  final double alertThresholdPct; // e.g. 0.80 triggers warning at 80%

  const CategoryBudget({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    this.period = BudgetPeriod.monthly,
    this.alertThresholdPct = 0.80,
  });

  CategoryBudget copyWith({
    double? limitAmount,
    BudgetPeriod? period,
    double? alertThresholdPct,
  }) =>
      CategoryBudget(
        id: id,
        categoryId: categoryId,
        limitAmount: limitAmount ?? this.limitAmount,
        period: period ?? this.period,
        alertThresholdPct: alertThresholdPct ?? this.alertThresholdPct,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'limitAmount': limitAmount,
        'period': period.name,
        'alertThresholdPct': alertThresholdPct,
      };

  factory CategoryBudget.fromMap(Map<String, dynamic> map) => CategoryBudget(
        id: map['id'] as String,
        categoryId: map['categoryId'] as String,
        limitAmount: (map['limitAmount'] as num).toDouble(),
        period: BudgetPeriod.values.byName(map['period'] as String? ?? 'monthly'),
        alertThresholdPct: (map['alertThresholdPct'] as num?)?.toDouble() ?? 0.80,
      );
}
