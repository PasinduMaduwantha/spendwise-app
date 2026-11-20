import '../../models/comparison_models.dart';
import '../../models/transaction_model.dart';

class ValueCalculator {
  /// Compares different brands for the same [productGroup] (and optional [itemType])
  /// sorted from lowest normalized unit price (e.g. per 100g / 100ml) to highest.
  static List<BrandComparisonRow> compareBrands({
    required List<SpendTransaction> transactions,
    required String productGroup,
    String? itemType,
  }) {
    final matching = transactions.where((tx) {
      final p = tx.product;
      if (p == null) return false;
      if (p.productGroup.toLowerCase() != productGroup.toLowerCase()) return false;
      if (itemType != null &&
          itemType.isNotEmpty &&
          p.itemType.toLowerCase() != itemType.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    if (matching.isEmpty) return [];

    // Group by brand + itemType so users see exact variants clearly.
    final Map<String, List<SpendTransaction>> grouped = {};
    for (final tx in matching) {
      final p = tx.product!;
      final key = '${p.brand.toLowerCase()}||${p.itemType.toLowerCase()}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final List<BrandComparisonRow> rows = [];
    double maxAvgUnitPrice = 0;

    final tempStats = <({
      String brand,
      String itemType,
      double latestUnitPrice,
      double avgUnitPrice,
      double minUnitPrice,
      String unitLabel,
      String bestShop,
      double avgRating,
      int count,
    })>[];

    for (final entry in grouped.entries) {
      final items = [...entry.value]..sort((a, b) => b.date.compareTo(a.date));
      final firstProd = items.first.product!;
      final unitPrices = items.map((e) => e.normalizedUnitPrice ?? 0).toList();
      final avgUnit = unitPrices.reduce((a, b) => a + b) / unitPrices.length;
      if (avgUnit > maxAvgUnitPrice) maxAvgUnitPrice = avgUnit;

      SpendTransaction cheapestTx = items.first;
      for (final tx in items) {
        if ((tx.normalizedUnitPrice ?? double.infinity) <
            (cheapestTx.normalizedUnitPrice ?? double.infinity)) {
          cheapestTx = tx;
        }
      }

      final avgRating =
          items.map((e) => e.product!.combinedRating).reduce((a, b) => a + b) / items.length;

      tempStats.add((
        brand: firstProd.brand,
        itemType: firstProd.itemType,
        latestUnitPrice: items.first.normalizedUnitPrice ?? 0,
        avgUnitPrice: avgUnit,
        minUnitPrice: cheapestTx.normalizedUnitPrice ?? 0,
        unitLabel: firstProd.normalizedUnitLabel,
        bestShop: cheapestTx.shopName ?? 'Unknown Shop',
        avgRating: avgRating,
        count: items.length,
      ));
    }

    for (final stat in tempStats) {
      final savingsVsMax = maxAvgUnitPrice > 0
          ? ((maxAvgUnitPrice - stat.avgUnitPrice) / maxAvgUnitPrice) * 100.0
          : 0.0;
      rows.add(
        BrandComparisonRow(
          brand: stat.brand,
          itemType: stat.itemType,
          latestUnitPrice: stat.latestUnitPrice,
          avgUnitPrice: stat.avgUnitPrice,
          minUnitPrice: stat.minUnitPrice,
          unitLabel: stat.unitLabel,
          bestShop: stat.bestShop,
          avgRating: stat.avgRating,
          purchaseCount: stat.count,
          savingsPctVsMax: savingsVsMax,
        ),
      );
    }

    rows.sort((a, b) => a.avgUnitPrice.compareTo(b.avgUnitPrice));
    return rows;
  }

  /// Finds the cheapest shops for a given [categoryId] (or all categories if null)
  /// using a normalized Category Price Index (basket ratio vs cross-shop average).
  static List<ShopCategoryRanking> rankShopsByCategory({
    required List<SpendTransaction> transactions,
    String? categoryId,
  }) {
    final matching = transactions.where((tx) {
      if (tx.product == null) return false;
      if (tx.shopName == null || tx.shopName!.trim().isEmpty) return false;
      if (categoryId != null && categoryId.isNotEmpty && tx.categoryId != categoryId) {
        return false;
      }
      return true;
    }).toList();

    if (matching.isEmpty) return [];

    // Compute cross-shop market average unit price per product key (group + type + brand).
    // Fallback to group + type if brand is only bought at one shop so cross-shop comparison stays rich.
    final Map<String, List<double>> productPricesByExactKey = {};
    final Map<String, List<double>> productPricesByGroupType = {};

    for (final tx in matching) {
      final p = tx.product!;
      final unitPrice = tx.normalizedUnitPrice ?? 0;
      if (unitPrice <= 0) continue;
      final exactKey = '${p.productGroup}|${p.itemType}|${p.brand}'.toLowerCase();
      final groupTypeKey = '${p.productGroup}|${p.itemType}'.toLowerCase();
      productPricesByExactKey.putIfAbsent(exactKey, () => []).add(unitPrice);
      productPricesByGroupType.putIfAbsent(groupTypeKey, () => []).add(unitPrice);
    }

    final Map<String, List<SpendTransaction>> byShop = {};
    for (final tx in matching) {
      final shop = tx.shopName!.trim();
      byShop.putIfAbsent(shop, () => []).add(tx);
    }

    final List<ShopCategoryRanking> rankings = [];

    for (final entry in byShop.entries) {
      final shopName = entry.key;
      final shopTxs = entry.value;

      // Aggregate per product within this shop
      final Map<String, List<SpendTransaction>> shopProducts = {};
      double totalSpend = 0;
      for (final tx in shopTxs) {
        totalSpend += tx.amount;
        final p = tx.product!;
        final key = '${p.productGroup}|${p.itemType}|${p.brand}'.toLowerCase();
        shopProducts.putIfAbsent(key, () => []).add(tx);
      }

      final List<double> ratios = [];
      final List<ShopDealHighlight> highlights = [];

      for (final prodEntry in shopProducts.entries) {
        final txs = prodEntry.value;
        final sampleProd = txs.first.product!;
        final shopAvgUnit =
            txs.map((e) => e.normalizedUnitPrice ?? 0).reduce((a, b) => a + b) / txs.length;

        final exactPrices = productPricesByExactKey[prodEntry.key] ?? [];
        final groupTypeKey =
            '${sampleProd.productGroup}|${sampleProd.itemType}'.toLowerCase();
        final groupPrices = productPricesByGroupType[groupTypeKey] ?? [];

        // Prefer exact brand benchmark when sold at >1 observations, else group+type benchmark
        final benchmarkList = exactPrices.length > 1 ? exactPrices : groupPrices;
        final marketAvg = benchmarkList.isNotEmpty
            ? benchmarkList.reduce((a, b) => a + b) / benchmarkList.length
            : shopAvgUnit;

        if (marketAvg > 0) {
          ratios.add(shopAvgUnit / marketAvg);
          highlights.add(
            ShopDealHighlight(
              productLabel: '${sampleProd.brand} ${sampleProd.itemType}',
              shopUnitPrice: shopAvgUnit,
              marketAvgUnitPrice: marketAvg,
              unitLabel: sampleProd.normalizedUnitLabel,
            ),
          );
        }
      }

      if (ratios.isEmpty) continue;
      final index = ratios.reduce((a, b) => a + b) / ratios.length;
      highlights.sort((a, b) => a.diffPct.compareTo(b.diffPct));

      rankings.add(
        ShopCategoryRanking(
          shopName: shopName,
          priceIndex: index,
          comparedProductsCount: ratios.length,
          totalTrackedSpend: totalSpend,
          topDeals: highlights.take(3).toList(),
        ),
      );
    }

    rankings.sort((a, b) => a.priceIndex.compareTo(b.priceIndex));
    return rankings;
  }

  /// Evaluates all item types and brands within a [productGroup] (e.g., "Biscuits":
  /// Digestive vs Marie vs Cream Cracker vs Chocolate Chip across brands)
  /// combining normalized unit price + user quality & experience rating into a 0-100 Value Score.
  static ValueComparisonReport evaluateGroupValue({
    required List<SpendTransaction> transactions,
    required String productGroup,
    double priceWeight = 0.50,
  }) {
    final clampedWeight = priceWeight.clamp(0.0, 1.0);
    final matching = transactions.where((tx) {
      final p = tx.product;
      return p != null && p.productGroup.toLowerCase() == productGroup.toLowerCase();
    }).toList();

    if (matching.isEmpty) {
      return ValueComparisonReport(
        productGroup: productGroup,
        priceWeight: clampedWeight,
        rankedItems: const [],
        rankedTypes: const [],
        rankedBrands: const [],
      );
    }

    // Group by (itemType, brand)
    final Map<String, List<SpendTransaction>> grouped = {};
    for (final tx in matching) {
      final p = tx.product!;
      final key = '${p.itemType.toLowerCase()}||${p.brand.toLowerCase()}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final rawItems = <({
      String itemType,
      String brand,
      String bestShop,
      double avgUnitPrice,
      String unitLabel,
      double avgQuality,
      double avgExperience,
      double combinedRating,
      int count,
    })>[];

    double minUnitPrice = double.infinity;

    for (final entry in grouped.entries) {
      final list = entry.value;
      final first = list.first.product!;
      final avgUnit =
          list.map((e) => e.normalizedUnitPrice ?? 0).reduce((a, b) => a + b) / list.length;
      if (avgUnit > 0 && avgUnit < minUnitPrice) {
        minUnitPrice = avgUnit;
      }

      SpendTransaction cheapest = list.first;
      for (final tx in list) {
        if ((tx.normalizedUnitPrice ?? double.infinity) <
            (cheapest.normalizedUnitPrice ?? double.infinity)) {
          cheapest = tx;
        }
      }

      final avgQuality =
          list.map((e) => e.product!.qualityRating).reduce((a, b) => a + b) / list.length;
      final avgExp =
          list.map((e) => e.product!.experienceRating).reduce((a, b) => a + b) / list.length;

      rawItems.add((
        itemType: first.itemType,
        brand: first.brand,
        bestShop: cheapest.shopName ?? 'Unknown Shop',
        avgUnitPrice: avgUnit,
        unitLabel: first.normalizedUnitLabel,
        avgQuality: avgQuality,
        avgExperience: avgExp,
        combinedRating: (avgQuality + avgExp) / 2.0,
        count: list.length,
      ));
    }

    final List<ValueItemScore> scored = rawItems.map((item) {
      final priceScore =
          (item.avgUnitPrice > 0 && minUnitPrice < double.infinity)
              ? (minUnitPrice / item.avgUnitPrice) * 100.0
              : 0.0;
      final qualityScore = (item.combinedRating / 5.0) * 100.0;
      final valueScore = (clampedWeight * priceScore) + ((1.0 - clampedWeight) * qualityScore);

      return ValueItemScore(
        productGroup: productGroup,
        itemType: item.itemType,
        brand: item.brand,
        bestShop: item.bestShop,
        avgUnitPrice: item.avgUnitPrice,
        unitLabel: item.unitLabel,
        avgQualityRating: item.avgQuality,
        avgExperienceRating: item.avgExperience,
        combinedRating: item.combinedRating,
        priceScore: priceScore,
        qualityScore: qualityScore,
        valueScore: valueScore,
        sampleCount: item.count,
      );
    }).toList()
      ..sort((a, b) => b.valueScore.compareTo(a.valueScore));

    // Roll up best Sub-Type and best Brand summaries
    List<GroupValueSummary> summarizeBy(String Function(ValueItemScore) keyFn) {
      final Map<String, List<ValueItemScore>> map = {};
      for (final item in scored) {
        map.putIfAbsent(keyFn(item), () => []).add(item);
      }
      final summaries = map.entries.map((e) {
        final items = e.value;
        return GroupValueSummary(
          label: e.key,
          avgValueScore:
              items.map((x) => x.valueScore).reduce((a, b) => a + b) / items.length,
          avgUnitPrice:
              items.map((x) => x.avgUnitPrice).reduce((a, b) => a + b) / items.length,
          avgRating:
              items.map((x) => x.combinedRating).reduce((a, b) => a + b) / items.length,
          unitLabel: items.first.unitLabel,
          variantCount: items.length,
        );
      }).toList()
        ..sort((a, b) => b.avgValueScore.compareTo(a.avgValueScore));
      return summaries;
    }

    return ValueComparisonReport(
      productGroup: productGroup,
      priceWeight: clampedWeight,
      rankedItems: scored,
      rankedTypes: summarizeBy((i) => i.itemType),
      rankedBrands: summarizeBy((i) => i.brand),
    );
  }
}
