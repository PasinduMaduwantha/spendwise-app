import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../models/account_model.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../models/recurring_rule_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_providers.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final budgets = ref.watch(budgetsStreamProvider).valueOrNull ?? const [];
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? const [];
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? const [];
    final rules = ref.watch(recurringRulesStreamProvider).valueOrNull ?? const [];
    final balances = ref.watch(accountBalancesProvider);
    final periodTxs = ref.watch(periodTransactionsProvider);

    final catById = {for (final c in categories) c.id: c};
    final Map<String, double> spentByCat = {};
    for (final tx in periodTxs) {
      if (tx.type == TransactionType.expense) {
        spentByCat[tx.categoryId] = (spentByCat[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan & Accounts', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Reset All Data',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          // Section 1: Category Budgets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Category Budgets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () => _showBudgetDialog(context, ref, categories),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Set Limit'),
              ),
            ],
          ),
          if (budgets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No budgets set yet. Tap "Set Limit" to add a monthly category budget.'),
              ),
            )
          else
            for (final b in budgets) ...[
              Builder(builder: (context) {
                final cat = catById[b.categoryId];
                final spent = spentByCat[b.categoryId] ?? 0;
                final ratio = b.limitAmount > 0 ? (spent / b.limitAmount) : 0.0;
                final barColor = ratio >= 1.0
                    ? AppTheme.expenseColor
                    : (ratio >= b.alertThresholdPct
                        ? AppTheme.warningColor
                        : AppTheme.incomeColor);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat?.name ?? b.categoryId,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '$currency${spent.toStringAsFixed(2)} / $currency${b.limitAmount.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.w700, color: barColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.0, 1.0),
                            color: barColor,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

          // Section 2: Recurring Expenses & Bills
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recurring Bills & Subscriptions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () => _showAddRecurringDialog(context, ref, categories, accounts),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Bill'),
              ),
            ],
          ),
          if (rules.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No recurring bills yet. Tap "Add Bill" to track rent or subscriptions.'),
              ),
            )
          else
            for (final rule in rules) ...[
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
                    child: const Icon(Icons.autorenew_rounded),
                  ),
                  title: Text(rule.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${rule.frequency.name.toUpperCase()} • Next due ${DateFormat('MMM d').format(rule.nextDueDate)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency${rule.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      GestureDetector(
                        onTap: () {
                          final tx = SpendTransaction(
                            id: const Uuid().v4(),
                            title: rule.title,
                            amount: rule.amount,
                            type: rule.type,
                            categoryId: rule.categoryId,
                            accountId: rule.accountId,
                            date: DateTime.now(),
                            receiptNote: rule.note ?? 'Logged from recurring bill',
                          );
                          ref.read(spendRepositoryProvider).logRecurringRuleNow(rule, tx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Logged "${rule.title}" & scheduled next cycle')),
                          );
                        },
                        child: Text(
                          'Log now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

          // Section 3: Wallets & Payment Accounts
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Accounts & Wallets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              TextButton.icon(
                onPressed: () => _showAddAccountDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Account'),
              ),
            ],
          ),
          for (final acc in accounts) ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(acc.colorValue).withValues(alpha: 0.18),
                  child: Icon(Icons.account_balance_wallet_outlined, color: Color(acc.colorValue)),
                ),
                title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(acc.typeLabel),
                trailing: Text(
                  '$currency${(balances[acc.id] ?? acc.initialBalance).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This clears all transactions, budgets, and recurring bills so you can start completely fresh.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(spendRepositoryProvider).clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared — fresh start ready!')),
        );
      }
    }
  }

  Future<void> _showBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    List<SpendCategory> categories,
  ) async {
    final expenseCats = categories.where((c) => c.type == TransactionType.expense).toList();
    if (expenseCats.isEmpty) return;
    String selectedCatId = expenseCats.first.id;
    final limitCtrl = TextEditingController(text: '100');

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCatId,
                items: expenseCats
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCatId = v ?? selectedCatId),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monthly Limit'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(limitCtrl.text.trim()) ?? 0;
                if (amount > 0) {
                  ref.read(spendRepositoryProvider).upsertBudget(
                        CategoryBudget(
                          id: 'bud_$selectedCatId',
                          categoryId: selectedCatId,
                          limitAmount: amount,
                        ),
                      );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddRecurringDialog(
    BuildContext context,
    WidgetRef ref,
    List<SpendCategory> categories,
    List<SpendAccount> accounts,
  ) async {
    final expenseCats = categories.where((c) => c.type == TransactionType.expense).toList();
    if (expenseCats.isEmpty || accounts.isEmpty) return;

    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCatId = expenseCats.first.id;
    String selectedAccId = accounts.first.id;
    RecurrenceFrequency freq = RecurrenceFrequency.monthly;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Recurring Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title (e.g., Rent, Internet)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedCatId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: expenseCats
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCatId = v ?? selectedCatId),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedAccId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: accounts
                      .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedAccId = v ?? selectedAccId),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: freq,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: RecurrenceFrequency.values
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.name.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setState(() => freq = v ?? RecurrenceFrequency.monthly),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (titleCtrl.text.trim().isNotEmpty && amount > 0) {
                  ref.read(spendRepositoryProvider).addRecurringRule(
                        RecurringRule(
                          id: 'rec_${const Uuid().v4().substring(0, 8)}',
                          title: titleCtrl.text.trim(),
                          amount: amount,
                          type: TransactionType.expense,
                          categoryId: selectedCatId,
                          accountId: selectedAccId,
                          frequency: freq,
                          nextDueDate: DateTime.now().add(const Duration(days: 7)),
                        ),
                      );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAccountDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');
    AccountType type = AccountType.debitCard;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Account Name (e.g., Savings)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<AccountType>(
                initialValue: type,
                items: AccountType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.typeLabel)))
                    .toList(),
                onChanged: (v) => setState(() => type = v ?? AccountType.cash),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: balCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Opening Balance'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  ref.read(spendRepositoryProvider).addAccount(
                        SpendAccount(
                          id: 'acc_${const Uuid().v4().substring(0, 8)}',
                          name: nameCtrl.text.trim(),
                          type: type,
                          initialBalance: double.tryParse(balCtrl.text.trim()) ?? 0,
                          colorValue: 0xFF0EA5E9,
                        ),
                      );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on AccountType {
  String get typeLabel {
    switch (this) {
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
}
