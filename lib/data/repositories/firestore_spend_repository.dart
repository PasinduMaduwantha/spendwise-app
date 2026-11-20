import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/account_model.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../models/recurring_rule_model.dart';
import '../../models/transaction_model.dart';
import 'spend_repository.dart';

/// Production Cloud Firestore + Firebase Storage repository.
///
/// Data Layout:
/// - `users/{uid}/transactions/{txId}`      (private ledger + product details)
/// - `users/{uid}/categories/{catId}`       (custom & default categories)
/// - `users/{uid}/accounts/{accId}`         (wallets, cards, bank accounts)
/// - `users/{uid}/budgets/{budgetId}`       (category spending limits)
/// - `users/{uid}/recurring_rules/{ruleId}` (bills & scheduled entries)
/// - `community_observations/{txId}`        (opt-in anonymized price & rating data for future community comparisons)
class FirestoreSpendRepository implements SpendRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String uid;

  FirestoreSpendRepository({
    required this.uid,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _txCol => _userDoc.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _catCol => _userDoc.collection('categories');
  CollectionReference<Map<String, dynamic>> get _accCol => _userDoc.collection('accounts');
  CollectionReference<Map<String, dynamic>> get _budCol => _userDoc.collection('budgets');
  CollectionReference<Map<String, dynamic>> get _recCol => _userDoc.collection('recurring_rules');
  CollectionReference<Map<String, dynamic>> get _communityCol =>
      _firestore.collection('community_observations');

  @override
  Stream<List<SpendTransaction>> watchTransactions() => _txCol
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => SpendTransaction.fromMap(d.data())).toList());

  @override
  Stream<List<SpendCategory>> watchCategories() => _catCol
      .snapshots()
      .map((snap) => snap.docs.map((d) => SpendCategory.fromMap(d.data())).toList());

  @override
  Stream<List<SpendAccount>> watchAccounts() => _accCol
      .snapshots()
      .map((snap) => snap.docs.map((d) => SpendAccount.fromMap(d.data())).toList());

  @override
  Stream<List<CategoryBudget>> watchBudgets() => _budCol
      .snapshots()
      .map((snap) => snap.docs.map((d) => CategoryBudget.fromMap(d.data())).toList());

  @override
  Stream<List<RecurringRule>> watchRecurringRules() => _recCol
      .orderBy('nextDueDate')
      .snapshots()
      .map((snap) => snap.docs.map((d) => RecurringRule.fromMap(d.data())).toList());

  @override
  Future<void> addTransaction(SpendTransaction tx) async {
    String? remoteReceiptUrl = tx.receiptImagePath;

    // If a local receipt image was picked, upload its bytes to Firebase Storage.
    if (remoteReceiptUrl != null && !remoteReceiptUrl.startsWith('http')) {
      try {
        final bytes = await XFile(remoteReceiptUrl).readAsBytes();
        final ref = _storage.ref('users/$uid/receipts/${tx.id}.jpg');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        remoteReceiptUrl = await ref.getDownloadURL();
      } catch (_) {
        // Keep local path reference if upload is unavailable offline.
      }
    }

    final payload = tx.toMap()..['receiptImagePath'] = remoteReceiptUrl;
    final batch = _firestore.batch();
    batch.set(_txCol.doc(tx.id), payload);

    // Mirror anonymized price + quality rating observation if user opted in.
    final product = tx.product;
    if (product != null && product.isPublicShared) {
      batch.set(_communityCol.doc(tx.id), {
        'authorUid': uid,
        'productGroup': product.productGroup,
        'itemType': product.itemType,
        'brand': product.brand,
        'shopName': tx.shopName ?? '',
        'normalizedUnitPrice': tx.normalizedUnitPrice ?? 0,
        'normalizedUnitLabel': product.normalizedUnitLabel,
        'qualityRating': product.qualityRating,
        'experienceRating': product.experienceRating,
        'recordedAt': tx.date.toIso8601String(),
      });
    }

    await batch.commit();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final batch = _firestore.batch();
    batch.delete(_txCol.doc(id));
    batch.delete(_communityCol.doc(id));
    await batch.commit();
  }

  @override
  Future<void> addCategory(SpendCategory category) =>
      _catCol.doc(category.id).set(category.toMap());

  @override
  Future<void> addAccount(SpendAccount account) =>
      _accCol.doc(account.id).set(account.toMap());

  @override
  Future<void> upsertBudget(CategoryBudget budget) =>
      _budCol.doc(budget.categoryId).set(budget.toMap());

  @override
  Future<void> addRecurringRule(RecurringRule rule) =>
      _recCol.doc(rule.id).set(rule.toMap());

  @override
  Future<void> logRecurringRuleNow(RecurringRule rule, SpendTransaction tx) async {
    final batch = _firestore.batch();
    batch.set(_txCol.doc(tx.id), tx.toMap());
    batch.set(
      _recCol.doc(rule.id),
      rule.copyWith(nextDueDate: rule.computeNextDate()).toMap(),
    );
    await batch.commit();
  }

  @override
  Future<void> clearAllData() async {
    for (final col in [_txCol, _budCol, _recCol]) {
      final snap = await col.get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
