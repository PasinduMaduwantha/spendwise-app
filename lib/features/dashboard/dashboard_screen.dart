import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final period = ref.watch(selectedPeriodProvider);
    final txs = ref.watch(periodTransactionsProvider);
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? const [];
    final budgets = ref.watch(budgetsStreamProvider).valueOrNull ?? const [];
    final balances = ref.watch(accountBalancesProvider);

    final catById = {for (final c in categories) c.id: c};

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> spendByCategory = {};

    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        spendByCategory[tx.categoryId] = (spendByCategory[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    final totalNetWorth = balances.values.fold<double>(0, (sum, v) => sum + v);
    final periodNet = totalIncome - totalExpense;
    final sortedCategories = spendByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Identify budgets at or above alert threshold
    final budgetAlerts = budgets.where((b) {
      final spent = spendByCategory[b.categoryId] ?? 0;
      return b.limitAmount > 0 && (spent / b.limitAmount) >= b.alertThresholdPct;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SpendWise', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              'Track spending & best-value goods',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Select Currency',
            initialValue: currency,
            onSelected: (val) => ref.read(currencySymbolProvider.notifier).state = val,
            itemBuilder: (_) => const [
              PopupMenuItem(value: '\$', child: Text('USD (\$)')),
              PopupMenuItem(value: 'Rs ', child: Text('LKR (Rs)')),
              PopupMenuItem(value: '€', child: Text('EUR (€)')),
              PopupMenuItem(value: '£', child: Text('GBP (£)')),
              PopupMenuItem(value: '₹', child: Text('INR (₹)')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Chip(
                label: Text(currency.trim(), style: const TextStyle(fontWeight: FontWeight.w700)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          // Time Period Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in [
                  TimePeriod.week,
                  TimePeriod.month,
                  TimePeriod.quarter,
                  TimePeriod.year,
                  TimePeriod.all,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_periodLabel(p)),
                      selected: period == p,
                      onSelected: (_) => ref.read(selectedPeriodProvider.notifier).state = p,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Net Balance & Income/Expense Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance across Accounts',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$currency${totalNetWorth.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricPill(
                        label: 'Income',
                        value: '+$currency${totalIncome.toStringAsFixed(2)}',
                        icon: Icons.arrow_downward_rounded,
                        accent: AppTheme.incomeColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricPill(
                        label: 'Expenses',
                        value: '-$currency${totalExpense.toStringAsFixed(2)}',
                        icon: Icons.arrow_upward_rounded,
                        accent: AppTheme.expenseColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Period Net Cashflow: ${periodNet >= 0 ? '+' : '-'}$currency${periodNet.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Budget Alert Banner(s)
          if (budgetAlerts.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final b in budgetAlerts) ...[
              Builder(builder: (context) {
                final spent = spendByCategory[b.categoryId] ?? 0;
                final pct = (spent / b.limitAmount * 100).round();
                final isOver = spent > b.limitAmount;
                final catName = catById[b.categoryId]?.name ?? 'Category';
                return Card(
                  color: (isOver ? AppTheme.expenseColor : AppTheme.warningColor).withOpacity(0.12),
                  child: ListTile(
                    leading: Icon(
                      isOver ? Icons.warning_rounded : Icons.notifications_active_rounded,
                      color: isOver ? AppTheme.expenseColor : AppTheme.warningColor,
                    ),
                    title: Text(
                      isOver
                          ? '$catName budget exceeded ($pct%)'
                          : '$catName nearing limit ($pct%)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '$currency${spent.toStringAsFixed(2)} of $currency${b.limitAmount.toStringAsFixed(2)}',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ],

          // Category Breakdown Chart
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spending by Category (${_periodLabel(period)})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (sortedCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No expenses recorded in this period.')),
                    )
                  else ...[
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 46,
                          sections: sortedCategories.map((entry) {
                            final cat = catById[entry.key];
                            final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0;
                            return PieChartSectionData(
                              value: entry.value,
                              color: cat?.color ?? Colors.teal,
                              radius: 44,
                              title: pct >= 10 ? '${pct.toStringAsFixed(0)}%' : '',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final entry in sortedCategories) ...[
                      Builder(builder: (context) {
                        final cat = catById[entry.key];
                        final pct = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: (cat?.color ?? Colors.teal).withOpacity(0.15),
                                child: Icon(
                                  cat?.icon ?? Icons.category,
                                  size: 16,
                                  color: cat?.color ?? Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cat?.name ?? entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$currency${entry.value.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Recent Activity
          const SizedBox(height: 16),
          const Text(
            'Recent Activity',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (txs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No transactions yet. Tap "+ Add" below to log your first expense or income.',
                ),
              ),
            )
          else
            for (final tx in txs.take(5)) ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (catById[tx.categoryId]?.color ?? Colors.teal).withOpacity(0.15),
                  child: Icon(
                    catById[tx.categoryId]?.icon ?? Icons.receipt_long,
                    color: catById[tx.categoryId]?.color ?? Colors.teal,
                    size: 20,
                  ),
                ),
                title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [
                    catById[tx.categoryId]?.name ?? '',
                    if (tx.shopName != null) tx.shopName!,
                    if (tx.product != null)
                      '$currency${tx.normalizedUnitPrice!.toStringAsFixed(2)}/${tx.product!.normalizedUnitLabel}',
                    DateFormat('MMM d').format(tx.date),
                  ].where((e) => e.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${tx.type == TransactionType.income ? '+' : '-'}$currency${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: tx.type == TransactionType.income
                        ? AppTheme.incomeColor
                        : AppTheme.expenseColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  String _periodLabel(TimePeriod p) {
    switch (p) {
      case TimePeriod.week:
        return 'This Week';
      case TimePeriod.month:
        return 'This Month';
      case TimePeriod.quarter:
        return '90 Days';
      case TimePeriod.year:
        return 'This Year';
      case TimePeriod.all:
        return 'All Time';
      case TimePeriod.custom:
        return 'Custom';
    }
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: accent.withOpacity(0.2),
            child: Icon(icon, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
