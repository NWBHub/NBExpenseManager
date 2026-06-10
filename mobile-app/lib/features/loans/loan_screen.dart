import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/loan_model.dart';
import '../../services/api_service.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  List<LoanModel> loans = [];
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
      final res = await ApiService().get('/loans');
      final list = (res['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LoanModel.fromJson)
          .toList();

      if (!mounted) return;
      setState(() => loans = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openEditor({LoanModel? loan}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LoanEditorScreen(initialData: loan?.toJsonWithId()),
      ),
    );

    if (changed == true) {
      await load();
    }
  }

  Future<void> deleteLoan(LoanModel loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete loan?'),
        content: Text('This will remove "${loan.loanName}".'),
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
      await ApiService().delete('/loans/${loan.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan deleted')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Loan EMI Management')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'loans_add_fab',
        onPressed: () => openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add Loan'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: loans.isEmpty
                      ? const _EmptyState(
                          title: 'No loans added yet',
                          subtitle: 'Add your first loan EMI to track balance and due dates.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: loans.length,
                          itemBuilder: (_, index) {
                            final loan = loans[index];
                            final dueDate = loan.dueDate == null
                                ? 'No due date'
                                : DateFormat('dd MMM yyyy').format(loan.dueDate!);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => openEditor(loan: loan),
                                leading: const Icon(Icons.account_balance),
                                title: Text(loan.loanName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(loan.bankName.isEmpty ? 'Loan account' : loan.bankName),
                                    Text('EMI ${formatInr(loan.emiAmount)} - Due $dueDate'),
                                    Text(
                                      'Paid ${formatInr(loan.paidAmount)} - Balance ${formatInr(loan.remainingAmount)}',
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  onPressed: () => deleteLoan(loan),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

class LoanEditorScreen extends StatefulWidget {
  const LoanEditorScreen({super.key, this.initialData});

  final Map<String, dynamic>? initialData;

  @override
  State<LoanEditorScreen> createState() => _LoanEditorScreenState();
}

class _LoanEditorScreenState extends State<LoanEditorScreen> {
  final loanNameCtrl = TextEditingController();
  final bankNameCtrl = TextEditingController();
  final totalAmountCtrl = TextEditingController();
  final emiAmountCtrl = TextEditingController();
  final paidAmountCtrl = TextEditingController();
  final interestRateCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? dueDate;
  DateTime? reminderDate;
  bool saving = false;

  bool get isEditing => widget.initialData?['_id'] != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      loanNameCtrl.text = '${data['loanName'] ?? ''}';
      bankNameCtrl.text = '${data['bankName'] ?? ''}';
      totalAmountCtrl.text = '${data['totalLoanAmount'] ?? ''}';
      emiAmountCtrl.text = '${data['emiAmount'] ?? ''}';
      paidAmountCtrl.text = '${data['paidAmount'] ?? 0}';
      interestRateCtrl.text = '${data['interestRate'] ?? 0}';
      startDate = data['startDate'] == null ? null : DateTime.tryParse('${data['startDate']}');
      dueDate = data['dueDate'] == null ? null : DateTime.tryParse('${data['dueDate']}');
      reminderDate =
          data['reminderDate'] == null ? null : DateTime.tryParse('${data['reminderDate']}');
    }
  }

  @override
  void dispose() {
    loanNameCtrl.dispose();
    bankNameCtrl.dispose();
    totalAmountCtrl.dispose();
    emiAmountCtrl.dispose();
    paidAmountCtrl.dispose();
    interestRateCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final loanName = loanNameCtrl.text.trim();
    final totalAmount = double.tryParse(totalAmountCtrl.text.trim()) ?? 0;
    final emiAmount = double.tryParse(emiAmountCtrl.text.trim()) ?? 0;
    final paidAmount = double.tryParse(paidAmountCtrl.text.trim()) ?? 0;
    final interestRate = double.tryParse(interestRateCtrl.text.trim()) ?? 0;

    if (loanName.isEmpty || totalAmount <= 0 || emiAmount <= 0) {
      _show('Enter a valid loan name, total amount, and EMI amount.');
      return;
    }

    if (paidAmount > totalAmount) {
      _show('Paid amount cannot be greater than total loan amount.');
      return;
    }

    setState(() => saving = true);

    try {
      final body = {
        'loanName': loanName,
        'bankName': bankNameCtrl.text.trim(),
        'totalLoanAmount': totalAmount,
        'emiAmount': emiAmount,
        'paidAmount': paidAmount,
        'interestRate': interestRate,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (reminderDate != null) 'reminderDate': reminderDate!.toIso8601String(),
      };

      if (isEditing) {
        await ApiService().put('/loans/${widget.initialData!['_id']}', body);
      } else {
        await ApiService().post('/loans', body);
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
      appBar: AppBar(title: Text(isEditing ? 'Edit Loan' : 'Add Loan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: loanNameCtrl,
            decoration: const InputDecoration(labelText: 'Loan Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bankNameCtrl,
            decoration: const InputDecoration(labelText: 'Bank Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: totalAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Total Loan Amount'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emiAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'EMI Amount'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: paidAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Paid Amount'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: interestRateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Interest Rate (%)'),
          ),
          const SizedBox(height: 12),
          _DateTile(
            label: 'Start Date',
            value: startDate == null ? 'Optional' : dateFormat.format(startDate!),
            onTap: () => pickDate(
              initialDate: startDate ?? DateTime.now(),
              onPicked: (value) => setState(() => startDate = value),
            ),
            onClear: startDate == null ? null : () => setState(() => startDate = null),
          ),
          _DateTile(
            label: 'Due Date',
            value: dueDate == null ? 'Optional' : dateFormat.format(dueDate!),
            onTap: () => pickDate(
              initialDate: dueDate ?? DateTime.now(),
              onPicked: (value) => setState(() => dueDate = value),
            ),
            onClear: dueDate == null ? null : () => setState(() => dueDate = null),
          ),
          _DateTile(
            label: 'Reminder Date',
            value: reminderDate == null ? 'Optional' : dateFormat.format(reminderDate!),
            onTap: () => pickDate(
              initialDate: reminderDate ?? DateTime.now(),
              onPicked: (value) => setState(() => reminderDate = value),
            ),
            onClear: reminderDate == null ? null : () => setState(() => reminderDate = null),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving...' : (isEditing ? 'Update Loan' : 'Save Loan')),
          ),
        ],
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
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.inbox_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Center(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(subtitle, textAlign: TextAlign.center),
        ),
      ],
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
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
