class DebtModel {
  const DebtModel({
    required this.id,
    required this.personName,
    required this.mobileNumber,
    required this.amountGiven,
    required this.amountReturned,
    required this.balanceAmount,
    required this.givenDate,
    required this.expectedReturnDate,
    required this.reminderDate,
    required this.notes,
  });

  final String id;
  final String personName;
  final String mobileNumber;
  final double amountGiven;
  final double amountReturned;
  final double balanceAmount;
  final DateTime? givenDate;
  final DateTime? expectedReturnDate;
  final DateTime? reminderDate;
  final String notes;

  factory DebtModel.fromJson(Map<String, dynamic> json) => DebtModel(
        id: json['_id'] as String? ?? '',
        personName: json['personName'] as String? ?? '',
        mobileNumber: json['mobileNumber'] as String? ?? '',
        amountGiven: (json['amountGiven'] as num?)?.toDouble() ?? 0,
        amountReturned: (json['amountReturned'] as num?)?.toDouble() ?? 0,
        balanceAmount: (json['balanceAmount'] as num?)?.toDouble() ?? 0,
        givenDate: DateTime.tryParse(json['givenDate'] as String? ?? ''),
        expectedReturnDate: DateTime.tryParse(json['expectedReturnDate'] as String? ?? ''),
        reminderDate: DateTime.tryParse(json['reminderDate'] as String? ?? ''),
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJsonWithId() => {
        '_id': id,
        'personName': personName,
        'mobileNumber': mobileNumber,
        'amountGiven': amountGiven,
        'amountReturned': amountReturned,
        'balanceAmount': balanceAmount,
        'givenDate': givenDate?.toIso8601String(),
        'expectedReturnDate': expectedReturnDate?.toIso8601String(),
        'reminderDate': reminderDate?.toIso8601String(),
        'notes': notes,
      };
}
