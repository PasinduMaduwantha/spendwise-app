import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../providers/app_providers.dart';

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Compare', style: TextStyle(fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Brands /100g'),
              Tab(text: 'Cheapest Shops'),
              Tab(text: 'Best Value'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BrandComparisonTab(),
            _ShopComparisonTab(),
            _ValueScoreTab(),
          ],
        ),
      ),
    );
  }
}

class _BrandComparisonTab extends ConsumerWidget {
  const _BrandComparisonTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final groups = ref.watch(productGroupsProvider);
    final selectedGroup = ref.watch(activeProductGroupProvider);
    final rows = ref.watch(brandComparisonProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        const Text(
          'Compare Brands by Unit Price (per 100g / 100ml)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: groups.map((g) {
            return ChoiceChip(
              label: Text(g),
              selected: selectedGroup == g,
              onSelected: (_) => ref.read(selectedProductGroupProvider.notifier).state = g,
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Log purchases with pack sizes (g, kg, ml, L) to compare brands.'),
            ),
          )
        else
          for (var i = 0; i < rows.length; i++) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: i == 0
                          ? AppTheme.incomeColor.withOpacity(0.18)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        '#${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: i == 0 ? AppTheme.incomeColor : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${rows[i].brand} · ${rows[i].itemType}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Best at ${rows[i].bestShop} • ★ ${rows[i].avgRating.toStringAsFixed(1)} • ${rows[i].purchaseCount} buy(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currency${rows[i].avgUnitPrice.toStringAsFixed(2)}/${rows[i].unitLabel}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        if (rows[i].savingsPctVsMax > 0.5)
                          Text(
                            'Save ${rows[i].savingsPctVsMax.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.incomeColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ShopComparisonTab extends ConsumerWidget {
  const _ShopComparisonTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final categories = (ref.watch(categoriesStreamProvider).valueOrNull ?? const [])
        .where((c) => c.type == TransactionType.expense)
        .toList();
    final selectedCat = ref.watch(selectedShopCategoryProvider);
    final rankings = ref.watch(shopRankingProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        const Text(
          'Cheapest Shops by Category',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          'Ranked using a normalized Category Price Index (lower index = cheaper basket).',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Categories'),
                selected: selectedCat == null,
                onSelected: (_) => ref.read(selectedShopCategoryProvider.notifier).state = null,
              ),
              const SizedBox(width: 8),
              for (final c in categories) ...[
                ChoiceChip(
                  label: Text(c.name),
                  selected: selectedCat == c.id,
                  onSelected: (_) => ref.read(selectedShopCategoryProvider.notifier).state = c.id,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (rankings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No product purchases logged with shop names for this category yet.'),
            ),
          )
        else
          for (var i = 0; i < rankings.length; i++) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          i == 0 ? Icons.emoji_events_rounded : Icons.storefront_rounded,
                          color: i == 0 ? AppTheme.incomeColor : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rankings[i].shopName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              Text(
                                '${rankings[i].comparedProductsCount} product(s) compared • Total $currency${rankings[i].totalTrackedSpend.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (rankings[i].savingsVsAveragePct >= 0
                                    ? AppTheme.incomeColor
                                    : AppTheme.expenseColor)
                                .withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            rankings[i].savingsVsAveragePct >= 0
                                ? '${rankings[i].savingsVsAveragePct.toStringAsFixed(1)}% cheaper'
                                : '${rankings[i].savingsVsAveragePct.abs().toStringAsFixed(1)}% above avg',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: rankings[i].savingsVsAveragePct >= 0
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (rankings[i].topDeals.isNotEmpty) ...[
                      const Divider(height: 18),
                      for (final deal in rankings[i].topDeals)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  deal.productLabel,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$currency${deal.shopUnitPrice.toStringAsFixed(2)}/${deal.unitLabel}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ValueScoreTab extends ConsumerWidget {
  const _ValueScoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final groups = ref.watch(productGroupsProvider);
    final selectedGroup = ref.watch(activeProductGroupProvider);
    final weight = ref.watch(priceWeightProvider);
    final report = ref.watch(valueReportProvider);

    final pricePct = (weight * 100).round();
    final qualityPct = 100 - pricePct;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        const Text(
          'Best Value Finder (Price + Quality & Experience)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty || report == null || report.rankedItems.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No rated products logged yet. Tap "+ Add", enable "Track Product", enter pack size (g/kg/ml/L) and Quality + Experience ratings to find the best value type & brand!',
              ),
            ),
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: groups.map((g) {
              return ChoiceChip(
                label: Text(g),
                selected: selectedGroup == g,
                onSelected: (_) => ref.read(selectedProductGroupProvider.notifier).state = g,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Price vs Quality Preference Slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Price Weight: $pricePct%',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('Quality & Exp: $qualityPct%',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  Slider(
                    value: weight,
                    min: 0.1,
                    max: 0.9,
                    divisions: 8,
                    onChanged: (v) => ref.read(priceWeightProvider.notifier).state = v,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Winner Summary Cards: Best Type & Best Brand
          if (report.bestType != null && report.bestBrand != null) ...[
            Row(
              children: [
                Expanded(
                  child: _WinnerCard(
                    label: 'Most Valuable Type',
                    title: report.bestType!.label,
                    subtitle:
                        'Score ${report.bestType!.avgValueScore.toStringAsFixed(0)}/100 • ★ ${report.bestType!.avgRating.toStringAsFixed(1)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WinnerCard(
                    label: 'Most Valuable Brand',
                    title: report.bestBrand!.label,
                    subtitle:
                        'Score ${report.bestBrand!.avgValueScore.toStringAsFixed(0)}/100 • $currency${report.bestBrand!.avgUnitPrice.toStringAsFixed(2)}/${report.bestBrand!.unitLabel}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Ranked Items
          for (var i = 0; i < report.rankedItems.length; i++) ...[
            Builder(builder: (context) {
              final item = report.rankedItems[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${i + 1}  ${item.brand} · ${item.itemType}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currency${item.avgUnitPrice.toStringAsFixed(2)}/${item.unitLabel} • Best at ${item.bestShop}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.valueScore.toStringAsFixed(0)} / 100',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (item.valueScore / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Price Score: ${item.priceScore.toStringAsFixed(0)}  •  Quality: ${item.avgQualityRating.toStringAsFixed(1)}★  •  Experience: ${item.avgExperienceRating.toStringAsFixed(1)}★',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;

  const _WinnerCard({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
