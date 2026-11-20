import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/account_model.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

class CsvExporter {
  static String buildCsv({
    required List<SpendTransaction> transactions,
    required Map<String, SpendCategory> categoriesById,
    required Map<String, SpendAccount> accountsById,
  }) {
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final rows = <List<dynamic>>[
      [
        'Date',
        'Type',
        'Title',
        'Amount',
        'Category',
        'Account',
        'Shop',
        'Product Group',
        'Item Type',
        'Brand',
        'Pack Size',
        'Unit Price',
        'Unit Basis',
        'Quality Rating',
        'Experience Rating',
        'Receipt Note',
      ],
    ];

    for (final tx in transactions) {
      final cat = categoriesById[tx.categoryId]?.name ?? tx.categoryId;
      final acc = accountsById[tx.accountId]?.name ?? tx.accountId;
      final p = tx.product;
      rows.add([
        dateFmt.format(tx.date),
        tx.type.name,
        tx.title,
        tx.amount.toStringAsFixed(2),
        cat,
        acc,
        tx.shopName ?? '',
        p?.productGroup ?? '',
        p?.itemType ?? '',
        p?.brand ?? '',
        p?.packSummary ?? '',
        tx.normalizedUnitPrice?.toStringAsFixed(3) ?? '',
        p != null ? 'per ${p.normalizedUnitLabel}' : '',
        p?.qualityRating.toStringAsFixed(1) ?? '',
        p?.experienceRating.toStringAsFixed(1) ?? '',
        tx.receiptNote ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Works seamlessly across Android, iOS, and Web using in-memory XFile bytes.
  static Future<void> exportAndShare({
    required List<SpendTransaction> transactions,
    required Map<String, SpendCategory> categoriesById,
    required Map<String, SpendAccount> accountsById,
  }) async {
    final csvData = buildCsv(
      transactions: transactions,
      categoriesById: categoriesById,
      accountsById: accountsById,
    );
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final bytes = Uint8List.fromList(utf8.encode(csvData));
    final file = XFile.fromData(
      bytes,
      mimeType: 'text/csv',
      name: 'spendwise_export_$timestamp.csv',
    );
    await Share.shareXFiles([file], text: 'SpendWise Expense & Price Comparison Export');
  }
}
