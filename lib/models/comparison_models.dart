class BrandComparisonRow {
  final String brand;
  final String itemType;
  final double latestUnitPrice;
  final double avgUnitPrice;
  final double minUnitPrice;
  final String unitLabel;
  final String bestShop;
  final double avgRating;
  final int purchaseCount;
  final double savingsPctVsMax;

  const BrandComparisonRow({
    required this.brand,
    required this.itemType,
    required this.latestUnitPrice,
    required this.avgUnitPrice,
    required this.minUnitPrice,
    required this.unitLabel,
    required this.bestShop,
    required this.avgRating,
    required this.purchaseCount,
    required this.savingsPctVsMax,
  });
}

class ShopDealHighlight {
  final String productLabel;
  final double shopUnitPrice;
  final double marketAvgUnitPrice;
  final String unitLabel;

  const ShopDealHighlight({
    required this.productLabel,
    required this.shopUnitPrice,
    required this.marketAvgUnitPrice,
    required this.unitLabel,
  });

  double get diffPct =>
      marketAvgUnitPrice > 0 ? ((shopUnitPrice - marketAvgUnitPrice) / marketAvgUnitPrice) * 100 : 0;
}

class ShopCategoryRanking {
  final String shopName;
  final double priceIndex; // < 1.0 means cheaper than cross-shop average
  final int comparedProductsCount;
  final double totalTrackedSpend;
  final List<ShopDealHighlight> topDeals;

  const ShopCategoryRanking({
    required this.shopName,
    required this.priceIndex,
    required this.comparedProductsCount,
    required this.totalTrackedSpend,
    required this.topDeals,
  });

  /// Positive percentage means cheaper than average (e.g., +9.5% savings).
  double get savingsVsAveragePct => (1.0 - priceIndex) * 100.0;
}

class ValueItemScore {
  final String productGroup;
  final String itemType;
  final String brand;
  final String bestShop;
  final double avgUnitPrice;
  final String unitLabel;
  final double avgQualityRating;
  final double avgExperienceRating;
  final double combinedRating;
  final double priceScore; // 0 - 100 (100 = cheapest unit price in group)
  final double qualityScore; // 0 - 100 (100 = 5.0 stars)
  final double valueScore; // Weighted combination of priceScore and qualityScore
  final int sampleCount;

  const ValueItemScore({
    required this.productGroup,
    required this.itemType,
    required this.brand,
    required this.bestShop,
    required this.avgUnitPrice,
    required this.unitLabel,
    required this.avgQualityRating,
    required this.avgExperienceRating,
    required this.combinedRating,
    required this.priceScore,
    required this.qualityScore,
    required this.valueScore,
    required this.sampleCount,
  });
}

class GroupValueSummary {
  final String label; // Either an itemType (e.g., "Digestive") or a brand (e.g., "Munchee")
  final double avgValueScore;
  final double avgUnitPrice;
  final double avgRating;
  final String unitLabel;
  final int variantCount;

  const GroupValueSummary({
    required this.label,
    required this.avgValueScore,
    required this.avgUnitPrice,
    required this.avgRating,
    required this.unitLabel,
    required this.variantCount,
  });
}

class ValueComparisonReport {
  final String productGroup;
  final double priceWeight;
  final List<ValueItemScore> rankedItems;
  final List<GroupValueSummary> rankedTypes;
  final List<GroupValueSummary> rankedBrands;

  const ValueComparisonReport({
    required this.productGroup,
    required this.priceWeight,
    required this.rankedItems,
    required this.rankedTypes,
    required this.rankedBrands,
  });

  ValueItemScore? get bestOverall => rankedItems.isNotEmpty ? rankedItems.first : null;
  GroupValueSummary? get bestType => rankedTypes.isNotEmpty ? rankedTypes.first : null;
  GroupValueSummary? get bestBrand => rankedBrands.isNotEmpty ? rankedBrands.first : null;
}
