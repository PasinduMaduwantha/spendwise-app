import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/value_calculator.dart';
import '../data/repositories/spend_repository.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/comparison_models.dart';
import '../models/recurring_rule_model.dart';
import '../models/transaction_model.dart';

enum TimePeriod { week, month, quarter, year, all, custom }

/// Override this provider in `main.dart` with `FirestoreSpendRepository` once Firebase Auth is active.
final spendRepositoryProvider = Provider<SpendRepository>((ref) {
  return LocalSpendRepository();
});

final currencySymbolProvider = StateProvider<String>((ref) => '\$');

final selectedPeriodProvider = StateProvider<TimePeriod>((ref) => TimePeriod.month);
final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
final selectedAccountFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Value comparison controls (0.50 = 50% Price + 50% Quality/Experience rating)
final priceWeightProvider = StateProvider<double>((ref) => 0.50);
final selectedProductGroupProvider = StateProvider<String?>((ref) => null);
final selectedShopCategoryProvider = StateProvider<String?>((ref) => null);

final transactionsStreamProvider = StreamProvider<List<SpendTransaction>>((ref) {
  return ref.watch(spendRepositoryProvider).watchTransactions();
});

final categoriesStreamProvider = StreamProvider<List<SpendCategory>>((ref) {
  return ref.watch(spendRepositoryProvider).watchCategories();
});

final accountsStreamProvider = StreamProvider<List<SpendAccount>>((ref) {
  return ref.watch(spendRepositoryProvider).watchAccounts();
});

final budgetsStreamProvider = StreamProvider<List<CategoryBudget>>((ref) {
  return ref.watch(spendRepositoryProvider).watchBudgets();
});

final recurringRulesStreamProvider = StreamProvider<List<RecurringRule>>((ref) {
  return ref.watch(spendRepositoryProvider).watchRecurringRules();
});

DateTimeRange? _rangeForPeriod(TimePeriod period, DateTimeRange? custom) {
  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
  switch (period) {
    case TimePeriod.week:
      return DateTimeRange(start: endOfToday.subtract(const Duration(days: 7)), end: endOfToday);
    case TimePeriod.month:
      return DateTimeRange(start: DateTime(now.year, now.month, 1), end: endOfToday);
    case TimePeriod.quarter:
      return DateTimeRange(start: endOfToday.subtract(const Duration(days: 90)), end: endOfToday);
    case TimePeriod.year:
      return DateTimeRange(start: DateTime(now.year, 1, 1), end: endOfToday);
    case TimePeriod.all:
      return null;
    case TimePeriod.custom:
      return custom;
  }
}

final periodTransactionsProvider = Provider<List<SpendTransaction>>((ref) {
  final all = ref.watch(transactionsStreamProvider).valueOrNull ?? const [];
  final period = ref.watch(selectedPeriodProvider);
  final custom = ref.watch(customDateRangeProvider);
  final range = _rangeForPeriod(period, custom);
  if (range == null) return all;

  return all
      .where((tx) => !tx.date.isBefore(range.start) && !tx.date.isAfter(range.end))
      .toList();
});

final filteredTransactionsProvider = Provider<List<SpendTransaction>>((ref) {
  final periodTxs = ref.watch(periodTransactionsProvider);
  final catId = ref.watch(selectedCategoryFilterProvider);
  final accId = ref.watch(selectedAccountFilterProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return periodTxs.where((tx) {
    if (catId != null && tx.categoryId != catId) return false;
    if (accId != null && tx.accountId != accId) return false;
    if (query.isNotEmpty) {
      final hay = [
        tx.title,
        tx.shopName ?? '',
        tx.receiptNote ?? '',
        tx.product?.brand ?? '',
        tx.product?.itemType ?? '',
        tx.product?.productGroup ?? '',
      ].join(' ').toLowerCase();
      if (!hay.contains(query)) return false;
    }
    return true;
  }).toList();
});

final accountBalancesProvider = Provider<Map<String, double>>((ref) {
  final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? const [];
  final allTxs = ref.watch(transactionsStreamProvider).valueOrNull ?? const [];
  final Map<String, double> balances = {
    for (final acc in accounts) acc.id: acc.initialBalance,
  };
  for (final tx in allTxs) {
    final delta = tx.type == TransactionType.income ? tx.amount : -tx.amount;
    balances[tx.accountId] = (balances[tx.accountId] ?? 0) + delta;
  }
  return balances;
});

final productGroupsProvider = Provider<List<String>>((ref) {
  final allTxs = ref.watch(transactionsStreamProvider).valueOrNull ?? const [];
  final groups = <String>{};
  for (final tx in allTxs) {
    final g = tx.product?.productGroup.trim();
    if (g != null && g.isNotEmpty) groups.add(g);
  }
  final list = groups.toList()..sort();
  return list;
});

final activeProductGroupProvider = Provider<String?>((ref) {
  final groups = ref.watch(productGroupsProvider);
  if (groups.isEmpty) return null;
  final selected = ref.watch(selectedProductGroupProvider);
  if (selected != null && groups.contains(selected)) return selected;
  return groups.first;
});

final brandComparisonProvider = Provider<List<BrandComparisonRow>>((ref) {
  final allTxs = ref.watch(transactionsStreamProvider).valueOrNull ?? const [];
  final group = ref.watch(activeProductGroupProvider);
  if (group == null) return const [];
  return ValueCalculator.compareBrands(transactions: allTxs, productGroup: group);
});

final shopRankingProvider = Provider<List<ShopCategoryRanking>>((ref) {
  final allTxs = ref.watch(transactionsStreamProvider).valueOrNull ?? const [];
  final categoryId = ref.watch(selectedShopCategoryProvider);
  return ValueCalculator.rankShopsByCategory(transactions: allTxs, categoryId: categoryId);
});

final valueReportProvider = Provider<ValueComparisonReport?>((ref) {
  final allTxs = ref.watch(transactionsStreamProvider).valueOrNull ?? const [];
  final group = ref.watch(activeProductGroupProvider);
  if (group == null) return null;
  final weight = ref.watch(priceWeightProvider);
  return ValueCalculator.evaluateGroupValue(
    transactions: allTxs,
    productGroup: group,
    priceWeight: weight,
  );
});
