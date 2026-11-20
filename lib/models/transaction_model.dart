import 'category_model.dart';
import '../core/utils/unit_normalizer.dart';

enum MeasureUnit { g, kg, ml, l, pcs }

class ProductPurchaseDetails {
  final String productGroup; // e.g. "Biscuits", "Fresh Milk", "Basmati Rice"
  final String itemType; // e.g. "Digestive", "Cream Cracker", "Marie", "Full Cream"
  final String brand; // e.g. "Munchee", "Maliban", "McVitie's"
  final double unitSize; // e.g. 250 (in [unit])
  final int packCount; // e.g. 1 (or 2 for a twin-pack)
  final MeasureUnit unit;
  final double qualityRating; // 1.0 - 5.0
  final double experienceRating; // 1.0 - 5.0
  final bool isPublicShared; // Ready for future anonymized community comparison

  const ProductPurchaseDetails({
    required this.productGroup,
    required this.itemType,
    required this.brand,
    required this.unitSize,
    this.packCount = 1,
    required this.unit,
    this.qualityRating = 4.0,
    this.experienceRating = 4.0,
    this.isPublicShared = false,
  });

  double get combinedRating => (qualityRating + experienceRating) / 2.0;

  double normalizedUnitPrice(double totalPrice) => UnitNormalizer.normalizePrice(
        totalPrice: totalPrice,
        unitSize: unitSize,
        packCount: packCount,
        unit: unit,
      );

  String get normalizedUnitLabel => UnitNormalizer.normalizedUnitLabel(unit);

  String get packSummary {
    final prefix = packCount > 1 ? '$packCount × ' : '';
    final formattedSize =
        unitSize == unitSize.truncateToDouble() ? unitSize.toInt().toString() : unitSize.toStringAsFixed(1);
    return '$prefix$formattedSize${UnitNormalizer.shortUnitLabel(unit)}';
  }

  Map<String, dynamic> toMap() => {
        'productGroup': productGroup,
        'itemType': itemType,
        'brand': brand,
        'unitSize': unitSize,
        'packCount': packCount,
        'unit': unit.name,
        'qualityRating': qualityRating,
        'experienceRating': experienceRating,
        'isPublicShared': isPublicShared,
      };

  factory ProductPurchaseDetails.fromMap(Map<String, dynamic> map) => ProductPurchaseDetails(
        productGroup: map['productGroup'] as String? ?? '',
        itemType: map['itemType'] as String? ?? '',
        brand: map['brand'] as String? ?? '',
        unitSize: (map['unitSize'] as num?)?.toDouble() ?? 100.0,
        packCount: (map['packCount'] as num?)?.toInt() ?? 1,
        unit: MeasureUnit.values.byName(map['unit'] as String? ?? 'g'),
        qualityRating: (map['qualityRating'] as num?)?.toDouble() ?? 4.0,
        experienceRating: (map['experienceRating'] as num?)?.toDouble() ?? 4.0,
        isPublicShared: map['isPublicShared'] as bool? ?? false,
      );
}

class SpendTransaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final DateTime date;
  final String? shopName;
  final String? receiptNote;
  final String? receiptImagePath; // Local file path or Firebase Storage URL
  final ProductPurchaseDetails? product;

  const SpendTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.date,
    this.shopName,
    this.receiptNote,
    this.receiptImagePath,
    this.product,
  });

  double? get normalizedUnitPrice => product?.normalizedUnitPrice(amount);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'accountId': accountId,
        'date': date.toIso8601String(),
        'shopName': shopName,
        'receiptNote': receiptNote,
        'receiptImagePath': receiptImagePath,
        'product': product?.toMap(),
      };

  factory SpendTransaction.fromMap(Map<String, dynamic> map) => SpendTransaction(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: TransactionType.values.byName(map['type'] as String? ?? 'expense'),
        categoryId: map['categoryId'] as String,
        accountId: map['accountId'] as String,
        date: DateTime.parse(map['date'] as String),
        shopName: map['shopName'] as String?,
        receiptNote: map['receiptNote'] as String?,
        receiptImagePath: map['receiptImagePath'] as String?,
        product: map['product'] != null
            ? ProductPurchaseDetails.fromMap(Map<String, dynamic>.from(map['product'] as Map))
            : null,
      );
}
