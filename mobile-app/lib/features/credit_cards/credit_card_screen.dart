import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/credit_card_model.dart';
import '../../services/api_service.dart';

class CreditCardScreen extends StatefulWidget {
  const CreditCardScreen({
    super.key,
    this.recordType = 'Credit Card',
    this.pageTitle = 'Credit Cards',
  });

  final String recordType;
  final String pageTitle;

  @override
  State<CreditCardScreen> createState() => _CreditCardScreenState();
}

class _CreditCardScreenState extends State<CreditCardScreen> {
  List<CreditCardModel> records = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService().get('/credit-cards');
      final list = (res['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CreditCardModel.fromJson)
          .where((item) => item.recordType == widget.recordType)
          .toList();

      if (!mounted) return;
      setState(() => records = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openEditor({CreditCardModel? record}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreditCardEditorScreen(
          initialData: record?.toJsonWithId(),
          defaultRecordType: widget.recordType,
        ),
      ),
    );

    if (changed == true) {
      await load();
    }
  }

  Future<void> deleteRecord(CreditCardModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${record.recordType.toLowerCase()}?'),
        content: Text('This will remove "${record.cardName}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService().delete('/credit-cards/${record.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${record.recordType} deleted')),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalOutstanding = records.fold<double>(0, (sum, item) => sum + item.balanceAmount);
    final totalLimit = records.fold<double>(0, (sum, item) => sum + item.creditLimit);
    final totalCyclesLeft = records.fold<int>(0, (sum, item) => sum + item.remainingInstallments);

    return Scaffold(
      appBar: AppBar(title: Text(widget.pageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: widget.recordType == 'BC' ? 'bc_add_fab' : 'credit_cards_add_fab',
        onPressed: () => openEditor(),
        icon: const Icon(Icons.add),
        label: Text(widget.recordType == 'BC' ? 'Add BC' : 'Add Card'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      _ModuleHeroCard(
                        recordType: widget.recordType,
                        totalRecords: records.length,
                        totalOutstanding: totalOutstanding,
                        totalLimit: totalLimit,
                        cyclesLeft: totalCyclesLeft,
                        progressCount: widget.recordType == 'BC'
                            ? records.fold<int>(0, (sum, item) => sum + item.paidInstallments)
                            : records.fold<int>(0, (sum, item) => sum + item.totalInstallments),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              label: widget.recordType == 'BC' ? 'Running BCs' : 'Cards',
                              value: '${records.length}',
                              icon: widget.recordType == 'BC'
                                  ? Icons.groups_2_outlined
                                  : Icons.credit_card_outlined,
                              color: widget.recordType == 'BC'
                                  ? const Color(0xFFE35D6A)
                                  : const Color(0xFF5B6EF5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStatCard(
                              label: widget.recordType == 'BC' ? 'Months Left' : 'EMIs Left',
                              value: '$totalCyclesLeft',
                              icon: Icons.timelapse_outlined,
                              color: const Color(0xFF2EB67D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.pageTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (records.isEmpty)
                        _EmptyState(
                          title: widget.recordType == 'BC'
                              ? 'No BC records yet'
                              : 'No credit cards yet',
                          subtitle: widget.recordType == 'BC'
                              ? 'Track each BC amount, paid months, remaining months, and completion dates here.'
                              : 'Track card limits, bill amounts, EMI progress, and remaining balances here.',
                        )
                      else
                        ...records.map(
                          (record) => _CreditRecordCard(
                            record: record,
                            onTap: () => openEditor(record: record),
                            onDelete: () => deleteRecord(record),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class CreditCardEditorScreen extends StatefulWidget {
  const CreditCardEditorScreen({
    super.key,
    this.initialData,
    this.defaultRecordType = 'Credit Card',
  });

  final Map<String, dynamic>? initialData;
  final String defaultRecordType;

  @override
  State<CreditCardEditorScreen> createState() => _CreditCardEditorScreenState();
}

class _CreditCardEditorScreenState extends State<CreditCardEditorScreen> {
  final cardNameCtrl = TextEditingController();
  final bankNameCtrl = TextEditingController();
  final creditLimitCtrl = TextEditingController();
  final billAmountCtrl = TextEditingController();
  final minimumDueCtrl = TextEditingController();
  final paidAmountCtrl = TextEditingController();
  final totalInstallmentsCtrl = TextEditingController();
  final paidInstallmentsCtrl = TextEditingController();
  final installmentAmountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  late String recordType;
  DateTime? startDate;
  DateTime? dueDate;
  DateTime? reminderDate;
  DateTime? completionDate;
  bool saving = false;

  bool get isEditing => widget.initialData?['_id'] != null;
  bool get isBc => recordType == 'BC';

  @override
  void initState() {
    super.initState();
    recordType = widget.defaultRecordType;
    final data = widget.initialData;
    if (data != null) {
      recordType = '${data['recordType'] ?? widget.defaultRecordType}';
      cardNameCtrl.text = '${data['cardName'] ?? ''}';
      bankNameCtrl.text = '${data['bankName'] ?? ''}';
      creditLimitCtrl.text = '${data['creditLimit'] ?? ''}';
      billAmountCtrl.text = '${data['billAmount'] ?? ''}';
      minimumDueCtrl.text = '${data['minimumDue'] ?? 0}';
      paidAmountCtrl.text = '${data['paidAmount'] ?? 0}';
      totalInstallmentsCtrl.text = '${data['totalInstallments'] ?? 0}';
      paidInstallmentsCtrl.text = '${data['paidInstallments'] ?? 0}';
      installmentAmountCtrl.text = '${data['installmentAmount'] ?? 0}';
      notesCtrl.text = '${data['notes'] ?? ''}';
      startDate = data['startDate'] == null ? null : DateTime.tryParse('${data['startDate']}');
      dueDate = data['dueDate'] == null ? null : DateTime.tryParse('${data['dueDate']}');
      reminderDate =
          data['reminderDate'] == null ? null : DateTime.tryParse('${data['reminderDate']}');
      completionDate =
          data['completionDate'] == null ? null : DateTime.tryParse('${data['completionDate']}');
    }
  }

  @override
  void dispose() {
    cardNameCtrl.dispose();
    bankNameCtrl.dispose();
    creditLimitCtrl.dispose();
    billAmountCtrl.dispose();
    minimumDueCtrl.dispose();
    paidAmountCtrl.dispose();
    totalInstallmentsCtrl.dispose();
    paidInstallmentsCtrl.dispose();
    installmentAmountCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  double get totalAmount => double.tryParse(billAmountCtrl.text.trim()) ?? 0;
  double get paidAmount => double.tryParse(paidAmountCtrl.text.trim()) ?? 0;
  double get balanceAmount => (totalAmount - paidAmount).clamp(0, double.infinity).toDouble();

  Future<void> save() async {
    final name = cardNameCtrl.text.trim();
    final creditLimit = double.tryParse(creditLimitCtrl.text.trim()) ?? 0;
    final totalInstallments = int.tryParse(totalInstallmentsCtrl.text.trim()) ?? 0;
    final paidInstallments = int.tryParse(paidInstallmentsCtrl.text.trim()) ?? 0;
    final installmentAmount = double.tryParse(installmentAmountCtrl.text.trim()) ?? 0;

    if (name.isEmpty || totalAmount <= 0) {
      _show('Enter a valid name and total amount.');
      return;
    }

    if (paidAmount > totalAmount) {
      _show('Paid amount cannot be greater than total amount.');
      return;
    }

    if (paidInstallments > totalInstallments) {
      _show('Paid installments cannot be greater than total installments.');
      return;
    }

    setState(() => saving = true);

    try {
      final body = {
        'recordType': recordType,
        'cardName': name,
        'bankName': bankNameCtrl.text.trim(),
        'creditLimit': creditLimit,
        'billAmount': totalAmount,
        'minimumDue': double.tryParse(minimumDueCtrl.text.trim()) ?? 0,
        'paidAmount': paidAmount,
        'totalInstallments': totalInstallments,
        'paidInstallments': paidInstallments,
        'installmentAmount': installmentAmount,
        'notes': notesCtrl.text.trim(),
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (reminderDate != null) 'reminderDate': reminderDate!.toIso8601String(),
        if (completionDate != null) 'completionDate': completionDate!.toIso8601String(),
      };

      if (isEditing) {
        await ApiService().put('/credit-cards/${widget.initialData!['_id']}', body);
      } else {
        await ApiService().post('/credit-cards', body);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onPicked(picked);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit ${isBc ? 'BC' : 'Card'}' : 'Add ${isBc ? 'BC' : 'Card'}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2A78), Color(0xFF5B6EF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x225B6EF5),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBc ? 'BC cycle tracker' : 'Credit card control center',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isBc
                      ? 'Track BC total amount, paid months, remaining months, and expected completion.'
                      : 'Track multiple cards, credit limits, EMI progress, and monthly due amounts.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(label: 'Total', value: formatInr(totalAmount)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroMetric(label: 'Balance', value: formatInr(balanceAmount)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _EditorSection(
            title: isBc ? 'BC Details' : 'Card Details',
            child: Column(
              children: [
                TextField(
                  controller: cardNameCtrl,
                  decoration: InputDecoration(
                    labelText: isBc ? 'BC Name' : 'Card Name',
                    hintText: isBc ? 'Ex: Friends BC June Batch' : 'Ex: HDFC Millennia',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bankNameCtrl,
                  decoration: InputDecoration(
                    labelText: isBc ? 'Organizer / Group Name' : 'Bank Name',
                  ),
                ),
                if (!isBc) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: creditLimitCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Credit Limit'),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: billAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isBc ? 'Total BC Amount' : 'Bill Amount',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paidAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Paid Amount'),
                  onChanged: (_) => setState(() {}),
                ),
                if (!isBc) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: minimumDueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Minimum Due'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _EditorSection(
            title: isBc ? 'Cycle Progress' : 'EMI Progress',
            child: Column(
              children: [
                TextField(
                  controller: installmentAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isBc ? 'Monthly BC Amount' : 'EMI Amount',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalInstallmentsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isBc ? 'Total BC Months' : 'Total EMIs',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paidInstallmentsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isBc ? 'Months Paid' : 'EMIs Paid',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _EditorSection(
            title: 'Dates',
            child: Column(
              children: [
                _DateTile(
                  label: isBc ? 'Start Date' : 'Card Start Date',
                  value: startDate == null ? 'Optional' : dateFormat.format(startDate!),
                  onTap: () => pickDate(
                    initialDate: startDate ?? DateTime.now(),
                    onPicked: (value) => setState(() => startDate = value),
                  ),
                  onClear: startDate == null ? null : () => setState(() => startDate = null),
                ),
                _DateTile(
                  label: isBc ? 'Next Due Date' : 'Bill Due Date',
                  value: dueDate == null ? 'Optional' : dateFormat.format(dueDate!),
                  onTap: () => pickDate(
                    initialDate: dueDate ?? DateTime.now(),
                    onPicked: (value) => setState(() => dueDate = value),
                  ),
                  onClear: dueDate == null ? null : () => setState(() => dueDate = null),
                ),
                _DateTile(
                  label: isBc ? 'Expected Completion Date' : 'EMI Completion Date',
                  value: completionDate == null ? 'Optional' : dateFormat.format(completionDate!),
                  onTap: () => pickDate(
                    initialDate: completionDate ?? DateTime.now(),
                    onPicked: (value) => setState(() => completionDate = value),
                  ),
                  onClear:
                      completionDate == null ? null : () => setState(() => completionDate = null),
                ),
                _DateTile(
                  label: 'Reminder Date',
                  value: reminderDate == null ? 'Optional' : dateFormat.format(reminderDate!),
                  onTap: () => pickDate(
                    initialDate: reminderDate ?? DateTime.now(),
                    onPicked: (value) => setState(() => reminderDate = value),
                  ),
                  onClear:
                      reminderDate == null ? null : () => setState(() => reminderDate = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _EditorSection(
            title: 'Notes',
            child: TextField(
              controller: notesCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add provider details, group members, or payment remarks',
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving...' : (isEditing ? 'Update Record' : 'Save Record')),
          ),
        ],
      ),
    );
  }
}

class _ModuleHeroCard extends StatelessWidget {
  const _ModuleHeroCard({
    required this.recordType,
    required this.totalRecords,
    required this.totalOutstanding,
    required this.totalLimit,
    required this.cyclesLeft,
    required this.progressCount,
  });

  final String recordType;
  final int totalRecords;
  final double totalOutstanding;
  final double totalLimit;
  final int cyclesLeft;
  final int progressCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A78), Color(0xFF5B6EF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x225B6EF5),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recordType == 'BC' ? 'BC cycle overview' : 'Credit card overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            recordType == 'BC'
                ? 'Track running BC amounts, paid months, remaining months, and expected completion.'
                : 'Track multiple cards, limits, current bills, outstanding amounts, and EMI cycles.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(label: 'Outstanding', value: formatInr(totalOutstanding)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: recordType == 'BC' ? 'Cycles Left' : 'Card Limits',
                  value: recordType == 'BC' ? '$cyclesLeft' : formatInr(totalLimit),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: recordType == 'BC' ? 'Running BCs' : 'Cards',
                  value: '$totalRecords',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: recordType == 'BC' ? 'Paid Cycles' : 'Configured EMIs',
                  value: '$progressCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditRecordCard extends StatelessWidget {
  const _CreditRecordCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  final CreditCardModel record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = record.billAmount <= 0
        ? 0.0
        : (record.paidAmount / record.billAmount).clamp(0.0, 1.0).toDouble();
    final accent = record.recordType == 'BC' ? const Color(0xFFE35D6A) : const Color(0xFF5B6EF5);
    final dueText = record.dueDate == null
        ? 'No due date'
        : DateFormat('dd MMM yyyy').format(record.dueDate!);
    final completionText = record.completionDate == null
        ? 'Not set'
        : DateFormat('dd MMM yyyy').format(record.completionDate!);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      record.recordType == 'BC'
                          ? Icons.groups_2_outlined
                          : Icons.credit_card_outlined,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.cardName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.bankName.isEmpty ? 'No provider set' : record.bankName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Due: $dueText • Completion: $completionText',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: progress,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ValueChip(
                      label: record.recordType == 'BC' ? 'BC Amount' : 'Bill Amount',
                      value: formatInr(record.billAmount),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ValueChip(
                      label: 'Balance',
                      value: formatInr(record.balanceAmount),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ValueChip(
                      label: record.recordType == 'BC' ? 'Months Paid' : 'EMIs Paid',
                      value: '${record.paidInstallments}/${record.totalInstallments}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ValueChip(
                      label: record.recordType == 'BC' ? 'Months Left' : 'EMIs Left',
                      value: '${record.remainingInstallments}',
                    ),
                  ),
                ],
              ),
              if (record.recordType == 'Credit Card' && record.creditLimit > 0) ...[
                const SizedBox(height: 10),
                _ValueChip(
                  label: 'Credit Limit',
                  value: formatInr(record.creditLimit),
                ),
              ],
              if (record.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  record.notes.trim(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_month_outlined),
      title: Text(label),
      subtitle: Text(value),
      trailing: onClear == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            ),
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.credit_card_off_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
