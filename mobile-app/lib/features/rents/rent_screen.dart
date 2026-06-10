import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/rent_model.dart';
import '../../services/api_service.dart';

class RentScreen extends StatefulWidget {
  const RentScreen({super.key});

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  List<RentModel> rents = [];
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
      final res = await ApiService().get('/rents');
      final list = (res['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RentModel.fromJson)
          .toList();
      if (!mounted) return;
      setState(() => rents = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openEditor({RentModel? rent}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RentEditorScreen(initialData: rent?.toJsonWithId()),
      ),
    );
    if (changed == true) {
      await load();
    }
  }

  Future<void> deleteRent(RentModel rent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete rent record?'),
        content: Text('This will remove ${rent.propertyName}.'),
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
      await ApiService().delete('/rents/${rent.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rent record deleted')),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> sendWhatsAppReminder(RentModel rent) async {
    final phone = rent.tenantPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add tenant mobile number first.')),
      );
      return;
    }

    final message = '''
Hello ${rent.tenantName},

This is a reminder for the rent of ${rent.propertyName}.

Property Type: ${rent.propertyType}
Rent Amount: ${formatInr(rent.monthlyRent)}
Paid: ${formatInr(rent.paidAmount)}
Balance: ${formatInr(rent.balanceAmount)}
${rent.dueDate == null ? '' : 'Due Date: ${DateFormat('dd MMM yyyy').format(rent.dueDate!)}'}

Please arrange the payment on time.
''';

    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

  Future<void> sendSmsReminder(RentModel rent) async {
    final phone = rent.tenantPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add tenant mobile number first.')),
      );
      return;
    }

    final body = Uri.encodeComponent(
      'Rent reminder for ${rent.propertyName}: pending ${formatInr(rent.balanceAmount)}.'
      '${rent.dueDate == null ? '' : ' Due ${DateFormat('dd MMM yyyy').format(rent.dueDate!)}.'}',
    );
    final uri = Uri.parse('sms:$phone?body=$body');
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open messaging app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRent = rents.fold<double>(0, (sum, item) => sum + item.monthlyRent);
    final totalCollected = rents.fold<double>(0, (sum, item) => sum + item.paidAmount);
    final totalPending = rents.fold<double>(0, (sum, item) => sum + item.balanceAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('Rent Collection')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'rents_add_fab',
        onPressed: () => openEditor(),
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Add Rent'),
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
                      _RentHeroCard(
                        totalRent: totalRent,
                        totalCollected: totalCollected,
                        totalPending: totalPending,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Properties & Tenants',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (rents.isEmpty)
                        const _EmptyState(
                          title: 'No rent records yet',
                          subtitle:
                              'Track shop or apartment rent, due dates, tenant contact details, and send reminders.',
                        )
                      else
                        ...rents.map(
                          (rent) => _RentCard(
                            rent: rent,
                            onTap: () => openEditor(rent: rent),
                            onDelete: () => deleteRent(rent),
                            onWhatsApp: () => sendWhatsAppReminder(rent),
                            onSms: () => sendSmsReminder(rent),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class RentEditorScreen extends StatefulWidget {
  const RentEditorScreen({super.key, this.initialData});

  final Map<String, dynamic>? initialData;

  @override
  State<RentEditorScreen> createState() => _RentEditorScreenState();
}

class _RentEditorScreenState extends State<RentEditorScreen> {
  final propertyNameCtrl = TextEditingController();
  final tenantNameCtrl = TextEditingController();
  final tenantPhoneCtrl = TextEditingController();
  final monthlyRentCtrl = TextEditingController();
  final paidAmountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  String propertyType = 'Shop';
  DateTime? rentMonth;
  DateTime? dueDate;
  DateTime? reminderDate;
  bool saving = false;

  bool get isEditing => widget.initialData?['_id'] != null;
  double get monthlyRent => double.tryParse(monthlyRentCtrl.text.trim()) ?? 0;
  double get paidAmount => double.tryParse(paidAmountCtrl.text.trim()) ?? 0;
  double get balanceAmount => (monthlyRent - paidAmount).clamp(0, double.infinity).toDouble();

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      propertyNameCtrl.text = '${data['propertyName'] ?? ''}';
      tenantNameCtrl.text = '${data['tenantName'] ?? ''}';
      tenantPhoneCtrl.text = '${data['tenantPhone'] ?? ''}';
      monthlyRentCtrl.text = '${data['monthlyRent'] ?? ''}';
      paidAmountCtrl.text = '${data['paidAmount'] ?? 0}';
      notesCtrl.text = '${data['notes'] ?? ''}';
      propertyType = '${data['propertyType'] ?? propertyType}';
      rentMonth = data['rentMonth'] == null ? null : DateTime.tryParse('${data['rentMonth']}');
      dueDate = data['dueDate'] == null ? null : DateTime.tryParse('${data['dueDate']}');
      reminderDate =
          data['reminderDate'] == null ? null : DateTime.tryParse('${data['reminderDate']}');
    } else {
      rentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    }
  }

  @override
  void dispose() {
    propertyNameCtrl.dispose();
    tenantNameCtrl.dispose();
    tenantPhoneCtrl.dispose();
    monthlyRentCtrl.dispose();
    paidAmountCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (propertyNameCtrl.text.trim().isEmpty || tenantNameCtrl.text.trim().isEmpty || monthlyRent <= 0) {
      _show('Enter property, tenant name, and valid monthly rent.');
      return;
    }
    if (paidAmount > monthlyRent) {
      _show('Paid amount cannot be greater than monthly rent.');
      return;
    }

    setState(() => saving = true);
    try {
      final body = {
        'propertyName': propertyNameCtrl.text.trim(),
        'propertyType': propertyType,
        'tenantName': tenantNameCtrl.text.trim(),
        'tenantPhone': tenantPhoneCtrl.text.trim(),
        'monthlyRent': monthlyRent,
        'paidAmount': paidAmount,
        'balanceAmount': balanceAmount,
        if (rentMonth != null) 'rentMonth': rentMonth!.toIso8601String(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (reminderDate != null) 'reminderDate': reminderDate!.toIso8601String(),
        'notes': notesCtrl.text.trim(),
      };

      if (isEditing) {
        await ApiService().put('/rents/${widget.initialData!['_id']}', body);
      } else {
        await ApiService().post('/rents', body);
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
      appBar: AppBar(title: Text(isEditing ? 'Edit Rent' : 'Add Rent')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          TextField(
            controller: propertyNameCtrl,
            decoration: const InputDecoration(labelText: 'Property Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: propertyType,
            items: const ['Shop', 'Apartment', 'Office', 'House', 'Other']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => propertyType = value!),
            decoration: const InputDecoration(labelText: 'Property Type'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tenantNameCtrl,
            decoration: const InputDecoration(labelText: 'Tenant Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tenantPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Tenant Mobile Number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: monthlyRentCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monthly Rent'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: paidAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Paid Amount'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _DateTile(
            label: 'Rent Month',
            value: rentMonth == null ? 'Optional' : DateFormat('MMMM yyyy').format(rentMonth!),
            onTap: () => pickDate(
              initialDate: rentMonth ?? DateTime.now(),
              onPicked: (value) => setState(() => rentMonth = DateTime(value.year, value.month)),
            ),
            onClear: rentMonth == null ? null : () => setState(() => rentMonth = null),
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
            child: Text(saving ? 'Saving...' : (isEditing ? 'Update Rent' : 'Save Rent')),
          ),
        ],
      ),
    );
  }
}

class _RentHeroCard extends StatelessWidget {
  const _RentHeroCard({
    required this.totalRent,
    required this.totalCollected,
    required this.totalPending,
  });

  final double totalRent;
  final double totalCollected;
  final double totalPending;

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rent collection overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track shop and apartment rents, pending balances, and due reminders in one place.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _HeroMetric(label: 'Total Rent', value: formatInr(totalRent))),
              const SizedBox(width: 12),
              Expanded(child: _HeroMetric(label: 'Collected', value: formatInr(totalCollected))),
              const SizedBox(width: 12),
              Expanded(child: _HeroMetric(label: 'Pending', value: formatInr(totalPending))),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

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
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RentCard extends StatelessWidget {
  const _RentCard({
    required this.rent,
    required this.onTap,
    required this.onDelete,
    required this.onWhatsApp,
    required this.onSms,
  });

  final RentModel rent;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onWhatsApp;
  final VoidCallback onSms;

  @override
  Widget build(BuildContext context) {
    final dueText =
        rent.dueDate == null ? 'No due date' : DateFormat('dd MMM yyyy').format(rent.dueDate!);
    final progress = rent.monthlyRent <= 0
        ? 0.0
        : (rent.paidAmount / rent.monthlyRent).clamp(0.0, 1.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rent.propertyName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text('${rent.propertyType} • Tenant: ${rent.tenantName}'),
                        const SizedBox(height: 4),
                        Text('Due: $dueText'),
                      ],
                    ),
                  ),
                  IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: progress,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _ValueChip(label: 'Rent', value: formatInr(rent.monthlyRent))),
                  const SizedBox(width: 10),
                  Expanded(child: _ValueChip(label: 'Pending', value: formatInr(rent.balanceAmount))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSms,
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('SMS'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onWhatsApp,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label, required this.value});

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
          : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
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
      ),
      child: Column(
        children: [
          Icon(Icons.home_work_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
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
