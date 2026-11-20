import 'category_model.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class RecurringRule {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final RecurrenceFrequency frequency;
  final DateTime nextDueDate;
  final bool isActive;
  final String? note;

  const RecurringRule({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    required this.nextDueDate,
    this.isActive = true,
    this.note,
  });

  DateTime computeNextDate() {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return nextDueDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return nextDueDate.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
      case RecurrenceFrequency.yearly:
        return DateTime(nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
    }
  }

  RecurringRule copyWith({
    DateTime? nextDueDate,
    bool? isActive,
  }) =>
      RecurringRule(
        id: id,
        title: title,
        amount: amount,
        type: type,
        categoryId: categoryId,
        accountId: accountId,
        frequency: frequency,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        isActive: isActive ?? this.isActive,
        note: note,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'accountId': accountId,
        'frequency': frequency.name,
        'nextDueDate': nextDueDate.toIso8601String(),
        'isActive': isActive,
        'note': note,
      };

  factory RecurringRule.fromMap(Map<String, dynamic> map) => RecurringRule(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: TransactionType.values.byName(map['type'] as String? ?? 'expense'),
        categoryId: map['categoryId'] as String,
        accountId: map['accountId'] as String,
        frequency:
            RecurrenceFrequency.values.byName(map['frequency'] as String? ?? 'monthly'),
        nextDueDate: DateTime.parse(map['nextDueDate'] as String),
        isActive: map['isActive'] as bool? ?? true,
        note: map['note'] as String?,
      );
}
