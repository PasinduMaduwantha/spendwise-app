import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/unit_normalizer.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_providers.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // Optional Product & Value Comparison fields
  bool _trackProduct = false;
  final _groupCtrl = TextEditingController(text: 'Biscuits');
  final _itemTypeCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _unitSizeCtrl = TextEditingController(text: '250');
  final _packCountCtrl = TextEditingController(text: '1');
  MeasureUnit _unit = MeasureUnit.g;
  double _qualityRating = 4.5;
  double _experienceRating = 4.5;
  bool _shareAnonymously = false;

  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  final DateTime _selectedDate = DateTime.now();
  String? _receiptImagePath;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _shopCtrl.dispose();
    _noteCtrl.dispose();
    _groupCtrl.dispose();
    _itemTypeCtrl.dispose();
    _brandCtrl.dispose();
    _unitSizeCtrl.dispose();
    _packCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCreateCategoryDialog() async {
    final nameCtrl = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g., Personal Care, Pet Food'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (created != null && created.isNotEmpty) {
      final newCat = SpendCategory(
        id: 'cat_${const Uuid().v4().substring(0, 8)}',
        name: created,
        type: _type,
        iconCodePoint: Icons.label_outline.codePoint,
        colorValue: 0xFF0F766E,
      );
      await ref.read(spendRepositoryProvider).addCategory(newCat);
      setState(() => _selectedCategoryId = newCat.id);
    }
  }

  Future<void> _pickReceiptPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() => _receiptImagePath = file.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;

    ProductPurchaseDetails? product;
    if (_type == TransactionType.expense && _trackProduct) {
      product = ProductPurchaseDetails(
        productGroup: _groupCtrl.text.trim(),
        itemType: _itemTypeCtrl.text.trim().isEmpty ? 'Standard' : _itemTypeCtrl.text.trim(),
        brand: _brandCtrl.text.trim().isEmpty ? 'Generic' : _brandCtrl.text.trim(),
        unitSize: double.tryParse(_unitSizeCtrl.text.trim()) ?? 100,
        packCount: int.tryParse(_packCountCtrl.text.trim()) ?? 1,
        unit: _unit,
        qualityRating: _qualityRating,
        experienceRating: _experienceRating,
        isPublicShared: _shareAnonymously,
      );
    }

    final tx = SpendTransaction(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId!,
      date: _selectedDate,
      shopName: _shopCtrl.text.trim().isEmpty ? null : _shopCtrl.text.trim(),
      receiptNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      receiptImagePath: _receiptImagePath,
      product: product,
    );

    await ref.read(spendRepositoryProvider).addTransaction(tx);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final allCategories = ref.watch(categoriesStreamProvider).valueOrNull ?? const [];
    final categories = allCategories.where((c) => c.type == _type).toList();
    final accounts = ref.watch(accountsStreamProvider).valueOrNull ?? const [];

    _selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;
    if (categories.every((c) => c.id != _selectedCategoryId) && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }
    _selectedAccountId ??= accounts.isNotEmpty ? accounts.first.id : null;

    final liveAmount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final liveSize = double.tryParse(_unitSizeCtrl.text.trim()) ?? 0;
    final livePacks = int.tryParse(_packCountCtrl.text.trim()) ?? 1;
    final liveUnitPrice = UnitNormalizer.normalizePrice(
      totalPrice: liveAmount,
      unitSize: liveSize,
      packCount: livePacks,
      unit: _unit,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollCtrl) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Add Transaction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            // Expense / Income Toggle
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                ButtonSegment(value: TransactionType.income, label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title (e.g., SunBake Digestive)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Amount ($currency)'),
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid amount' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _shopCtrl,
                    decoration: const InputDecoration(labelText: 'Shop / Merchant'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Category picker + Inline "+ New Category" button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _showCreateCategoryDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Category'),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                return ChoiceChip(
                  label: Text(cat.name),
                  selected: _selectedCategoryId == cat.id,
                  onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Account Picker
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: const InputDecoration(labelText: 'Account / Payment Method'),
              items: accounts
                  .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.typeLabel})')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
            ),
            const SizedBox(height: 12),

            // Optional Product & Brand Comparison Section
            if (_type == TransactionType.expense) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Track Product for Brand / Shop / Value Comparison',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text('Calculates price per 100g/100ml + Quality Value Score'),
                value: _trackProduct,
                onChanged: (v) => setState(() => _trackProduct = v),
              ),
              if (_trackProduct) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _groupCtrl,
                                decoration:
                                    const InputDecoration(labelText: 'Product Group (e.g. Biscuits)'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _itemTypeCtrl,
                                decoration:
                                    const InputDecoration(labelText: 'Type (e.g. Digestive)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _brandCtrl,
                          decoration: const InputDecoration(labelText: 'Brand (e.g. SunBake)'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _unitSizeCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Pack Size'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<MeasureUnit>(
                                value: _unit,
                                decoration: const InputDecoration(labelText: 'Unit'),
                                items: MeasureUnit.values
                                    .map((u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(UnitNormalizer.shortUnitLabel(u)),
                                        ))
                                    .toList(),
                                onChanged: (u) => setState(() => _unit = u ?? MeasureUnit.g),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _packCountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Packs'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Normalized Unit Price: $currency${liveUnitPrice.toStringAsFixed(2)} / ${UnitNormalizer.normalizedUnitLabel(_unit)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Quality Rating: ${_qualityRating.toStringAsFixed(1)} ★'),
                        Slider(
                          value: _qualityRating,
                          min: 1,
                          max: 5,
                          divisions: 8,
                          onChanged: (v) => setState(() => _qualityRating = v),
                        ),
                        Text('User Experience Rating: ${_experienceRating.toStringAsFixed(1)} ★'),
                        Slider(
                          value: _experienceRating,
                          min: 1,
                          max: 5,
                          divisions: 8,
                          onChanged: (v) => setState(() => _experienceRating = v),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _shareAnonymously,
                          onChanged: (v) => setState(() => _shareAnonymously = v ?? false),
                          title: const Text(
                            'Share anonymized price & rating for community benchmarks',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],

            // Receipt Note & Photo Attachment
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Receipt Note (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickReceiptPhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(
                _receiptImagePath == null ? 'Attach Receipt Photo' : 'Receipt Photo Attached ✓',
              ),
            ),
            const SizedBox(height: 18),

            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save Transaction', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
