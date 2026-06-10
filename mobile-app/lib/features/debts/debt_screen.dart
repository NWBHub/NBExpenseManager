import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/debt_model.dart';
import '../../services/api_service.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  List<DebtModel> debts = [];
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
      final res = await ApiService().get('/debts');
      final list = (res['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DebtModel.fromJson)
          .toList();

      if (!mounted) return;
      setState(() => debts = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openEditor({DebtModel? debt}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DebtEditorScreen(initialData: debt?.toJsonWithId()),
      ),
    );

    if (changed == true) {
      await load();
    }
  }

  Future<void> deleteDebt(DebtModel debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete debt record?'),
        content: Text('This will remove "${debt.personName}".'),
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
      await ApiService().delete('/debts/${debt.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debt record deleted')),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> sendDebtReminder(DebtModel debt) async {
    if (debt.mobileNumber.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a mobile number first.')),
      );
      return;
    }

    final cleanedPhone = debt.mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final message = '''
Hello ${debt.personName},

This is a friendly reminder regarding the pending amount.

Amount Given: ${formatInr(debt.amountGiven)}
Amount Returned: ${formatInr(debt.amountReturned)}
Balance Pending: ${formatInr(debt.balanceAmount)}
${debt.expectedReturnDate == null ? '' : 'Expected Return Date: ${DateFormat('dd MMM yyyy').format(debt.expectedReturnDate!)}'}

Please let us know once the payment is completed.
''';

    final uri = Uri.parse('https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debt Tracking')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'debts_add_fab',
        onPressed: () => openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: debts.isEmpty
                      ? const _EmptyState(
                          title: 'No debt entries yet',
                          subtitle: 'Track money you gave, returned amounts, and expected return dates.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: debts.length,
                          itemBuilder: (_, index) {
                            final debt = debts[index];
                            final returnDate = debt.expectedReturnDate == null
                                ? 'No expected date'
                                : DateFormat('dd MMM yyyy').format(debt.expectedReturnDate!);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => openEditor(debt: debt),
                                leading: const Icon(Icons.people_outline),
                                title: Text(debt.personName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      debt.mobileNumber.isEmpty ? 'No mobile number' : debt.mobileNumber,
                                    ),
                                    Text('Expected return $returnDate'),
                                    Text(
                                      'Returned ${formatInr(debt.amountReturned)} - Balance ${formatInr(debt.balanceAmount)}',
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(formatInr(debt.amountGiven)),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'whatsapp') {
                                          sendDebtReminder(debt);
                                        } else if (value == 'delete') {
                                          deleteDebt(debt);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'whatsapp',
                                          child: Text('Send WhatsApp Reminder'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

class DebtEditorScreen extends StatefulWidget {
  const DebtEditorScreen({super.key, this.initialData});

  final Map<String, dynamic>? initialData;

  @override
  State<DebtEditorScreen> createState() => _DebtEditorScreenState();
}

class _DebtEditorScreenState extends State<DebtEditorScreen> {
  final personNameCtrl = TextEditingController();
  final mobileNumberCtrl = TextEditingController();
  final amountGivenCtrl = TextEditingController();
  final amountReturnedCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  DateTime? givenDate;
  DateTime? expectedReturnDate;
  DateTime? reminderDate;
  bool saving = false;

  bool get isEditing => widget.initialData?['_id'] != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      personNameCtrl.text = '${data['personName'] ?? ''}';
      mobileNumberCtrl.text = '${data['mobileNumber'] ?? ''}';
      amountGivenCtrl.text = '${data['amountGiven'] ?? ''}';
      amountReturnedCtrl.text = '${data['amountReturned'] ?? 0}';
      notesCtrl.text = '${data['notes'] ?? ''}';
      givenDate = data['givenDate'] == null ? null : DateTime.tryParse('${data['givenDate']}');
      expectedReturnDate = data['expectedReturnDate'] == null
          ? null
          : DateTime.tryParse('${data['expectedReturnDate']}');
      reminderDate =
          data['reminderDate'] == null ? null : DateTime.tryParse('${data['reminderDate']}');
    }
  }

  @override
  void dispose() {
    personNameCtrl.dispose();
    mobileNumberCtrl.dispose();
    amountGivenCtrl.dispose();
    amountReturnedCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final personName = personNameCtrl.text.trim();
    final amountGiven = double.tryParse(amountGivenCtrl.text.trim()) ?? 0;
    final amountReturned = double.tryParse(amountReturnedCtrl.text.trim()) ?? 0;

    if (personName.isEmpty || amountGiven <= 0) {
      _show('Enter a valid person name and amount given.');
      return;
    }

    if (amountReturned > amountGiven) {
      _show('Returned amount cannot be greater than amount given.');
      return;
    }

    setState(() => saving = true);

    try {
      final body = {
        'personName': personName,
        'mobileNumber': mobileNumberCtrl.text.trim(),
        'amountGiven': amountGiven,
        'amountReturned': amountReturned,
        'notes': notesCtrl.text.trim(),
        if (givenDate != null) 'givenDate': givenDate!.toIso8601String(),
        if (expectedReturnDate != null) 'expectedReturnDate': expectedReturnDate!.toIso8601String(),
        if (reminderDate != null) 'reminderDate': reminderDate!.toIso8601String(),
      };

      if (isEditing) {
        await ApiService().put('/debts/${widget.initialData!['_id']}', body);
      } else {
        await ApiService().post('/debts', body);
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
      appBar: AppBar(title: Text(isEditing ? 'Edit Debt' : 'Add Debt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: personNameCtrl,
            decoration: const InputDecoration(labelText: 'Person Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: mobileNumberCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile Number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountGivenCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount Given'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountReturnedCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount Returned'),
          ),
          const SizedBox(height: 12),
          _DateTile(
            label: 'Given Date',
            value: givenDate == null ? 'Optional' : dateFormat.format(givenDate!),
            onTap: () => pickDate(
              initialDate: givenDate ?? DateTime.now(),
              onPicked: (value) => setState(() => givenDate = value),
            ),
            onClear: givenDate == null ? null : () => setState(() => givenDate = null),
          ),
          _DateTile(
            label: 'Expected Return Date',
            value: expectedReturnDate == null ? 'Optional' : dateFormat.format(expectedReturnDate!),
            onTap: () => pickDate(
              initialDate: expectedReturnDate ?? DateTime.now(),
              onPicked: (value) => setState(() => expectedReturnDate = value),
            ),
            onClear:
                expectedReturnDate == null ? null : () => setState(() => expectedReturnDate = null),
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
          const SizedBox(height: 12),
          TextField(
            controller: notesCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving...' : (isEditing ? 'Update Debt' : 'Save Debt')),
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
        Icon(Icons.group_off_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Center(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
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
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
