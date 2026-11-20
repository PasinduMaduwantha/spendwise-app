import 'dart:async';
import 'dart:convert';
import '../../models/account_model.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../models/recurring_rule_model.dart';
import '../../models/transaction_model.dart';
import '../seed_data.dart';
import 'local_storage.dart';

abstract class SpendRepository {
  Stream<List<SpendTransaction>> watchTransactions();
  Stream<List<SpendCategory>> watchCategories();
  Stream<List<SpendAccount>> watchAccounts();
  Stream<List<CategoryBudget>> watchBudgets();
  Stream<List<RecurringRule>> watchRecurringRules();

  Future<void> addTransaction(SpendTransaction tx);
  Future<void> deleteTransaction(String id);
  Future<void> addCategory(SpendCategory category);
  Future<void> addAccount(SpendAccount account);
  Future<void> upsertBudget(CategoryBudget budget);
  Future<void> addRecurringRule(RecurringRule rule);
  Future<void> logRecurringRuleNow(RecurringRule rule, SpendTransaction tx);
  Future<void> clearAllData();
}

/// Clean local-first repository that starts fresh (no dummy transactions, budgets,
/// or recurring bills) and persists all user entries to device storage across restarts.
class LocalSpendRepository implements SpendRepository {
  static const _storageFile = 'spendwise_data_v1.json';

  List<SpendTransaction> _txList;
  List<SpendCategory> _catList;
  List<SpendAccount> _accList;
  List<CategoryBudget> _budList;
  List<RecurringRule> _recList;

  final _txCtrl = StreamController<List<SpendTransaction>>.broadcast();
  final _catCtrl = StreamController<List<SpendCategory>>.broadcast();
  final _accCtrl = StreamController<List<SpendAccount>>.broadcast();
  final _budCtrl = StreamController<List<CategoryBudget>>.broadcast();
  final _recCtrl = StreamController<List<RecurringRule>>.broadcast();

  LocalSpendRepository({bool seedDemoData = false})
      : _txList = seedDemoData ? SeedData.transactions() : <SpendTransaction>[],
        _catList = SeedData.categories(),
        _accList = seedDemoData ? SeedData.accounts() : SeedData.freshStarterAccounts(),
        _budList = seedDemoData ? SeedData.budgets() : <CategoryBudget>[],
        _recList = seedDemoData ? SeedData.recurringRules() : <RecurringRule>[];

  /// Loads any previously saved data from the device filesystem.
  Future<void> loadFromDisk() async {
    final raw = await readLocalJson(_storageFile);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _txList = (map['transactions'] as List<dynamic>? ?? const [])
          .map((e) => SpendTransaction.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      final cats = (map['categories'] as List<dynamic>? ?? const [])
          .map((e) => SpendCategory.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (cats.isNotEmpty) _catList = cats;
      final accs = (map['accounts'] as List<dynamic>? ?? const [])
          .map((e) => SpendAccount.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (accs.isNotEmpty) _accList = accs;
      _budList = (map['budgets'] as List<dynamic>? ?? const [])
          .map((e) => CategoryBudget.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      _recList = (map['recurring'] as List<dynamic>? ?? const [])
          .map((e) => RecurringRule.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      _emitAll();
    } catch (_) {
      // Ignore corrupt cache and keep clean starter state.
    }
  }

  Future<void> _persist() async {
    final payload = jsonEncode({
      'transactions': _txList.map((e) => e.toMap()).toList(),
      'categories': _catList.map((e) => e.toMap()).toList(),
      'accounts': _accList.map((e) => e.toMap()).toList(),
      'budgets': _budList.map((e) => e.toMap()).toList(),
      'recurring': _recList.map((e) => e.toMap()).toList(),
    });
    await writeLocalJson(_storageFile, payload);
  }

  void _emitTx() => _txCtrl.add(List.unmodifiable(_txList));
  void _emitCat() => _catCtrl.add(List.unmodifiable(_catList));
  void _emitAcc() => _accCtrl.add(List.unmodifiable(_accList));
  void _emitBud() => _budCtrl.add(List.unmodifiable(_budList));
  void _emitRec() => _recCtrl.add(List.unmodifiable(_recList));
  void _emitAll() {
    _emitTx();
    _emitCat();
    _emitAcc();
    _emitBud();
    _emitRec();
  }

  @override
  Stream<List<SpendTransaction>> watchTransactions() async* {
    yield List.unmodifiable(_txList);
    yield* _txCtrl.stream;
  }

  @override
  Stream<List<SpendCategory>> watchCategories() async* {
    yield List.unmodifiable(_catList);
    yield* _catCtrl.stream;
  }

  @override
  Stream<List<SpendAccount>> watchAccounts() async* {
    yield List.unmodifiable(_accList);
    yield* _accCtrl.stream;
  }

  @override
  Stream<List<CategoryBudget>> watchBudgets() async* {
    yield List.unmodifiable(_budList);
    yield* _budCtrl.stream;
  }

  @override
  Stream<List<RecurringRule>> watchRecurringRules() async* {
    yield List.unmodifiable(_recList);
    yield* _recCtrl.stream;
  }

  @override
  Future<void> addTransaction(SpendTransaction tx) async {
    _txList.insert(0, tx);
    _emitTx();
    await _persist();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _txList.removeWhere((e) => e.id == id);
    _emitTx();
    await _persist();
  }

  @override
  Future<void> addCategory(SpendCategory category) async {
    _catList.add(category);
    _emitCat();
    await _persist();
  }

  @override
  Future<void> addAccount(SpendAccount account) async {
    _accList.add(account);
    _emitAcc();
    await _persist();
  }

  @override
  Future<void> upsertBudget(CategoryBudget budget) async {
    final idx = _budList.indexWhere((b) => b.categoryId == budget.categoryId);
    if (idx >= 0) {
      _budList[idx] = budget;
    } else {
      _budList.add(budget);
    }
    _emitBud();
    await _persist();
  }

  @override
  Future<void> addRecurringRule(RecurringRule rule) async {
    _recList.add(rule);
    _emitRec();
    await _persist();
  }

  @override
  Future<void> logRecurringRuleNow(RecurringRule rule, SpendTransaction tx) async {
    _txList.insert(0, tx);
    final idx = _recList.indexWhere((r) => r.id == rule.id);
    if (idx >= 0) {
      _recList[idx] = rule.copyWith(nextDueDate: rule.computeNextDate());
    }
    _emitTx();
    _emitRec();
    await _persist();
  }

  @override
  Future<void> clearAllData() async {
    _txList = <SpendTransaction>[];
    _catList = SeedData.categories();
    _accList = SeedData.freshStarterAccounts();
    _budList = <CategoryBudget>[];
    _recList = <RecurringRule>[];
    _emitAll();
    await _persist();
  }
}
