import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/csv_exporter.dart';
import '../../models/category_model.dart';
import '../../providers/app_providers.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final txs = ref.watch(filteredTransactionsProvider);
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? const [];
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? const [];
    final selectedCat = ref.watch(selectedCategoryFilterProvider);
    final selectedAcc = ref.watch(selectedAccountFilterProvider);

    final catById = {for (final c in categories) c.id: c};
    final accById = {for (final a in accounts) a.id: a};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download_rounded),
            onPressed: txs.isEmpty
                ? null
                : () async {
                    await CsvExporter.exportAndShare(
                      transactions: txs,
                      categoriesById: catById,
                      accountsById: accById,
                    );
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search title, brand, shop, or note...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
            ),
          ),

          // Category & Account Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Categories'),
                  selected: selectedCat == null,
                  onSelected: (_) => ref.read(selectedCategoryFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                for (final c in categories) ...[
                  FilterChip(
                    label: Text(c.name),
                    selected: selectedCat == c.id,
                    onSelected: (_) => ref.read(selectedCategoryFilterProvider.notifier).state =
                        selectedCat == c.id ? null : c.id,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Accounts'),
                  selected: selectedAcc == null,
                  onSelected: (_) => ref.read(selectedAccountFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                for (final a in accounts) ...[
                  FilterChip(
                    label: Text(a.name),
                    selected: selectedAcc == a.id,
                    onSelected: (_) => ref.read(selectedAccountFilterProvider.notifier).state =
                        selectedAcc == a.id ? null : a.id,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Transaction List
          Expanded(
            child: txs.isEmpty
                ? const Center(child: Text('No matching transactions found.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: txs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = txs[index];
                      final cat = catById[tx.categoryId];
                      final acc = accById[tx.accountId];
                      final p = tx.product;

                      return Dismissible(
                        key: ValueKey(tx.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.expenseColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(spendRepositoryProvider).deleteTransaction(tx.id);
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: (cat?.color ?? Colors.teal).withOpacity(0.15),
                                      child: Icon(
                                        cat?.icon ?? Icons.receipt_long,
                                        color: cat?.color ?? Colors.teal,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.title,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            [
                                              cat?.name ?? '',
                                              acc?.name ?? '',
                                              DateFormat('MMM d, y').format(tx.date),
                                            ].where((e) => e.isNotEmpty).join(' • '),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${tx.type == TransactionType.income ? '+' : '-'}$currency${tx.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: tx.type == TransactionType.income
                                            ? AppTheme.incomeColor
                                            : AppTheme.expenseColor,
                                      ),
                                    ),
                                  ],
                                ),
                                if (p != null || tx.shopName != null || tx.receiptNote != null) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (tx.shopName != null && tx.shopName!.isNotEmpty)
                                        _InfoTag(Icons.storefront_outlined, tx.shopName!),
                                      if (p != null)
                                        _InfoTag(
                                          Icons.scale_outlined,
                                          '${p.brand} (${p.itemType}) • ${p.packSummary} • '
                                          '$currency${tx.normalizedUnitPrice!.toStringAsFixed(2)}/${p.normalizedUnitLabel}',
                                        ),
                                      if (p != null)
                                        _InfoTag(
                                          Icons.star_rounded,
                                          '${p.combinedRating.toStringAsFixed(1)}/5',
                                        ),
                                      if (tx.receiptImagePath != null)
                                        const _InfoTag(Icons.photo_outlined, 'Receipt attached'),
                                    ],
                                  ),
                                  if (tx.receiptNote != null && tx.receiptNote!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      tx.receiptNote!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTag(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
