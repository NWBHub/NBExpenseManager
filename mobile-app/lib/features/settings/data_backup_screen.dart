import 'package:flutter/material.dart';

import '../../services/data_backup_service.dart';

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  final service = DataBackupService();
  bool exporting = false;
  bool importing = false;
  String? lastExportPath;
  List<String> exportedFiles = const [];
  String? lastImportMessage;

  Future<void> exportAll() async {
    setState(() => exporting = true);
    try {
      final result = await service.exportAllCsv();
      if (!mounted) return;
      setState(() {
        lastExportPath = result.directoryPath;
        exportedFiles = result.files;
      });
      _show('Backup exported successfully.');
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> importCsv() async {
    setState(() => importing = true);
    try {
      final result = await service.pickAndImportCsv();
      if (result == null || !mounted) return;
      setState(() {
        lastImportMessage =
            'Imported ${result.importedCount} ${result.module} record(s) from ${result.filePath}';
      });
      _show('CSV imported successfully.');
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
                  'Local CSV backup',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Export your expenses, loans, cards, BC records, debts, and reminders into CSV files stored on the device. You can later import any CSV file back into the app.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Export All creates separate CSV files for each module in one backup folder.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: exporting ? null : exportAll,
                      icon: const Icon(Icons.file_download_outlined),
                      label: Text(exporting ? 'Exporting...' : 'Export All CSV'),
                    ),
                  ),
                  if (lastExportPath != null) ...[
                    const SizedBox(height: 16),
                    SelectableText(
                      'Backup folder:\n$lastExportPath',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    ...exportedFiles.map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(file, style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick a CSV from internal storage and import it into the matching module. Imported records are added to your existing data.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: importing ? null : importCsv,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: Text(importing ? 'Importing...' : 'Import CSV'),
                    ),
                  ),
                  if (lastImportMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      lastImportMessage!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supported files',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('expenses.csv'),
                  Text('loans.csv'),
                  Text('credit_cards.csv'),
                  Text('debts.csv'),
                  Text('rents.csv'),
                  Text('reminders.csv'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
