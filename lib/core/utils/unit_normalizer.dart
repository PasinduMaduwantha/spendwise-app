import '../../models/transaction_model.dart';

class UnitNormalizer {
  /// Normalizes any package price into a comparable standard unit:
  /// - Mass (g / kg)   -> price per 100g
  /// - Volume (ml / L) -> price per 100ml
  /// - Count (pcs)     -> price per 1 piece
  static double normalizePrice({
    required double totalPrice,
    required double unitSize,
    required int packCount,
    required MeasureUnit unit,
  }) {
    final totalQuantity = unitSize * (packCount <= 0 ? 1 : packCount);
    if (totalQuantity <= 0 || totalPrice < 0) return 0;

    switch (unit) {
      case MeasureUnit.g:
        return (totalPrice / totalQuantity) * 100.0;
      case MeasureUnit.kg:
        return (totalPrice / (totalQuantity * 1000.0)) * 100.0;
      case MeasureUnit.ml:
        return (totalPrice / totalQuantity) * 100.0;
      case MeasureUnit.l:
        return (totalPrice / (totalQuantity * 1000.0)) * 100.0;
      case MeasureUnit.pcs:
        return totalPrice / totalQuantity;
    }
  }

  static String normalizedUnitLabel(MeasureUnit unit) {
    switch (unit) {
      case MeasureUnit.g:
      case MeasureUnit.kg:
        return '100g';
      case MeasureUnit.ml:
      case MeasureUnit.l:
        return '100ml';
      case MeasureUnit.pcs:
        return 'pc';
    }
  }

  static String shortUnitLabel(MeasureUnit unit) {
    switch (unit) {
      case MeasureUnit.g:
        return 'g';
      case MeasureUnit.kg:
        return 'kg';
      case MeasureUnit.ml:
        return 'ml';
      case MeasureUnit.l:
        return 'L';
      case MeasureUnit.pcs:
        return 'pcs';
    }
  }
}
