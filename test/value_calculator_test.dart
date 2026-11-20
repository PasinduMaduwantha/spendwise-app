import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/core/utils/unit_normalizer.dart';
import 'package:spendwise/core/utils/value_calculator.dart';
import 'package:spendwise/data/repositories/spend_repository.dart';
import 'package:spendwise/data/seed_data.dart';
import 'package:spendwise/models/transaction_model.dart';

void main() {
  group('UnitNormalizer', () {
    test('normalizes grams and kilograms to price per 100g', () {
      expect(
        UnitNormalizer.normalizePrice(
          totalPrice: 2.20,
          unitSize: 400,
          packCount: 1,
          unit: MeasureUnit.g,
        ),
        closeTo(0.55, 0.0001),
      );
      expect(
        UnitNormalizer.normalizePrice(
          totalPrice: 6.40,
          unitSize: 2.0,
          packCount: 1,
          unit: MeasureUnit.kg,
        ),
        closeTo(0.32, 0.0001),
      );
    });

    test('normalizes ml and liters with multi-pack counts to price per 100ml', () {
      expect(
        UnitNormalizer.normalizePrice(
          totalPrice: 3.60,
          unitSize: 500,
          packCount: 2,
          unit: MeasureUnit.ml,
        ),
        closeTo(0.36, 0.0001),
      );
    });
  });

  group('ValueCalculator', () {
    final txs = SeedData.transactions();

    test('ranks biscuit brands by lowest normalized unit price', () {
      final rows = ValueCalculator.compareBrands(
        transactions: txs,
        productGroup: 'Biscuits',
      );
      expect(rows, isNotEmpty);
      expect(rows.first.brand, equals('GoldenCrisp'));
      expect(rows.first.itemType, equals('Marie'));
      expect(rows.first.avgUnitPrice, lessThan(rows.last.avgUnitPrice));
    });

    test('identifies ValueGrocer as cheapest shop overall', () {
      final shops = ValueCalculator.rankShopsByCategory(transactions: txs);
      expect(shops, isNotEmpty);
      expect(shops.first.shopName, equals('ValueGrocer'));
      expect(shops.first.priceIndex, lessThan(1.0));
    });

    test('balances price and quality rating to find most valuable biscuit type & brand', () {
      final balanced = ValueCalculator.evaluateGroupValue(
        transactions: txs,
        productGroup: 'Biscuits',
        priceWeight: 0.50,
      );
      expect(balanced.bestOverall, isNotNull);
      expect(balanced.bestOverall!.brand, equals('SunBake'));
      expect(balanced.bestOverall!.itemType, equals('Digestive'));
      expect(balanced.bestType!.label, equals('Marie'));
      expect(balanced.bestBrand!.label, equals('SunBake'));

      // Shifting weight toward quality (25% price / 75% quality) promotes Digestive as #1 type
      final qualityFirst = ValueCalculator.evaluateGroupValue(
        transactions: txs,
        productGroup: 'Biscuits',
        priceWeight: 0.25,
      );
      expect(qualityFirst.bestType!.label, equals('Digestive'));
    });
  });

  group('Fresh Start Repository', () {
    test('starts with zero dummy transactions, budgets, recurring bills, and zero balances', () async {
      final repo = LocalSpendRepository(seedDemoData: false);
      final txs = await repo.watchTransactions().first;
      final budgets = await repo.watchBudgets().first;
      final rules = await repo.watchRecurringRules().first;
      final accounts = await repo.watchAccounts().first;
      final categories = await repo.watchCategories().first;

      expect(txs, isEmpty);
      expect(budgets, isEmpty);
      expect(rules, isEmpty);
      expect(categories, isNotEmpty);
      expect(accounts, isNotEmpty);
      expect(accounts.every((a) => a.initialBalance == 0.0), isTrue);
    });
  });
}
