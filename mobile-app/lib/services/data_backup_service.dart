import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';

class BackupExportResult {
  const BackupExportResult({
    required this.directoryPath,
    required this.files,
  });

  final String directoryPath;
  final List<String> files;
}

class BackupImportResult {
  const BackupImportResult({
    required this.module,
    required this.importedCount,
    required this.filePath,
  });

  final String module;
  final int importedCount;
  final String filePath;
}

class DataBackupService {
  final ApiService _api = ApiService();

  static const _modules = <_BackupModule>[
    _BackupModule(
      key: 'expenses',
      path: '/expenses',
      fileName: 'expenses.csv',
      columns: [
        'title',
        'shopkeeperName',
        'shopkeeperPhone',
        'category',
        'amount',
        'paidAmount',
        'balanceAmount',
        'paymentStatus',
        'paymentMode',
        'expenseDate',
        'dueDate',
        'reminderDate',
        'notes',
      ],
    ),
    _BackupModule(
      key: 'loans',
      path: '/loans',
      fileName: 'loans.csv',
      columns: [
        'loanName',
        'bankName',
        'totalLoanAmount',
        'emiAmount',
        'paidAmount',
        'remainingAmount',
        'interestRate',
        'startDate',
        'dueDate',
        'paymentStatus',
        'reminderDate',
      ],
    ),
    _BackupModule(
      key: 'credit-cards',
      path: '/credit-cards',
      fileName: 'credit_cards.csv',
      columns: [
        'recordType',
        'cardName',
        'bankName',
        'creditLimit',
        'billAmount',
        'minimumDue',
        'paidAmount',
        'balanceAmount',
        'paymentStatus',
        'totalInstallments',
        'paidInstallments',
        'installmentAmount',
        'startDate',
        'dueDate',
        'reminderDate',
        'completionDate',
        'notes',
      ],
    ),
    _BackupModule(
      key: 'debts',
      path: '/debts',
      fileName: 'debts.csv',
      columns: [
        'personName',
        'mobileNumber',
        'amountGiven',
        'amountReturned',
        'balanceAmount',
        'givenDate',
        'expectedReturnDate',
        'reminderDate',
        'notes',
      ],
    ),
    _BackupModule(
      key: 'rents',
      path: '/rents',
      fileName: 'rents.csv',
      columns: [
        'propertyName',
        'propertyType',
        'tenantName',
        'tenantPhone',
        'monthlyRent',
        'paidAmount',
        'balanceAmount',
        'paymentStatus',
        'rentMonth',
        'dueDate',
        'reminderDate',
        'notes',
      ],
    ),
    _BackupModule(
      key: 'reminders',
      path: '/reminders',
      fileName: 'reminders.csv',
      columns: [
        'title',
        'type',
        'amount',
        'dueDate',
        'reminderDate',
        'isCompleted',
        'notes',
      ],
    ),
  ];

  Future<BackupExportResult> exportAllCsv() async {
    final root = await _backupRootDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final backupDir = Directory('${root.path}${Platform.pathSeparator}nbexpense_backup_$stamp');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final writtenFiles = <String>[];

    for (final module in _modules) {
      final response = await _api.get(module.path);
      final rows = (response['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

      final buffer = StringBuffer()
        ..writeln(_csvLine(module.columns));

      for (final row in rows) {
        final values = module.columns.map((column) => _stringValue(row[column])).toList();
        buffer.writeln(_csvLine(values));
      }

      final file = File('${backupDir.path}${Platform.pathSeparator}${module.fileName}');
      await file.writeAsString(buffer.toString());
      writtenFiles.add(file.path);
    }

    return BackupExportResult(
      directoryPath: backupDir.path,
      files: writtenFiles,
    );
  }

  Future<BackupImportResult?> pickAndImportCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    final path = result?.files.single.path;
    if (path == null || path.isEmpty) {
      return null;
    }

    return importCsv(path);
  }

  Future<BackupImportResult> importCsv(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final rows = _parseCsv(content);
    if (rows.isEmpty) {
      throw Exception('Selected CSV file is empty.');
    }

    final header = rows.first;
    final module = _detectModule(filePath, header);
    if (module == null) {
      throw Exception('Could not detect which module this CSV belongs to.');
    }

    int importedCount = 0;

    for (final row in rows.skip(1)) {
      if (row.every((value) => value.trim().isEmpty)) {
        continue;
      }

      final data = <String, dynamic>{};
      for (var i = 0; i < module.columns.length && i < row.length; i++) {
        final key = module.columns[i];
        final value = row[i].trim();
        data[key] = _typedValue(key, value);
      }

      data.removeWhere((key, value) => value == null);
      if (data.isEmpty) {
        continue;
      }

      await _api.post(module.path, data);
      importedCount++;
    }

    return BackupImportResult(
      module: module.key,
      importedCount: importedCount,
      filePath: filePath,
    );
  }

  Future<Directory> _backupRootDirectory() async {
    final external = await getExternalStorageDirectory();
    if (external != null) {
      return external;
    }
    return getApplicationDocumentsDirectory();
  }

  _BackupModule? _detectModule(String filePath, List<String> header) {
    final normalizedHeader = header.map((item) => item.trim()).toSet();
    final lowerPath = filePath.toLowerCase();

    for (final module in _modules) {
      final columns = module.columns.toSet();
      final headerMatches = columns.every(normalizedHeader.contains);
      final fileMatches = lowerPath.endsWith(module.fileName.toLowerCase());
      if (headerMatches || fileMatches) {
        return module;
      }
    }
    return null;
  }

  dynamic _typedValue(String key, String value) {
    if (value.isEmpty) {
      return null;
    }

    const doubleKeys = {
      'amount',
      'paidAmount',
      'balanceAmount',
      'totalLoanAmount',
      'emiAmount',
      'remainingAmount',
      'interestRate',
      'creditLimit',
      'billAmount',
      'minimumDue',
      'amountGiven',
      'amountReturned',
      'installmentAmount',
    };

    const intKeys = {
      'totalInstallments',
      'paidInstallments',
    };

    const boolKeys = {
      'isCompleted',
    };

    const dateKeys = {
      'expenseDate',
      'dueDate',
      'reminderDate',
      'startDate',
      'completionDate',
      'givenDate',
      'expectedReturnDate',
    };

    if (doubleKeys.contains(key)) {
      return double.tryParse(value) ?? 0;
    }

    if (intKeys.contains(key)) {
      return int.tryParse(value) ?? 0;
    }

    if (boolKeys.contains(key)) {
      return value.toLowerCase() == 'true';
    }

    if (dateKeys.contains(key)) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toIso8601String();
    }

    return value;
  }

  String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }
    return '$value';
  }

  String _csvLine(List<String> values) {
    return values.map(_escapeCsv).join(',');
  }

  String _escapeCsv(String input) {
    final escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    var currentCell = StringBuffer();
    var insideQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '"') {
        if (insideQuotes && i + 1 < input.length && input[i + 1] == '"') {
          currentCell.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
        continue;
      }

      if (char == ',' && !insideQuotes) {
        currentRow.add(currentCell.toString());
        currentCell = StringBuffer();
        continue;
      }

      if ((char == '\n' || char == '\r') && !insideQuotes) {
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        currentRow.add(currentCell.toString());
        currentCell = StringBuffer();
        if (currentRow.isNotEmpty) {
          rows.add(List<String>.from(currentRow));
          currentRow.clear();
        }
        continue;
      }

      currentCell.write(char);
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      rows.add(List<String>.from(currentRow));
    }

    return rows.where((row) => row.isNotEmpty).toList();
  }
}

class _BackupModule {
  const _BackupModule({
    required this.key,
    required this.path,
    required this.fileName,
    required this.columns,
  });

  final String key;
  final String path;
  final String fileName;
  final List<String> columns;
}
