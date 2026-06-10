class ReportModel {
  const ReportModel({
    required this.year,
    required this.month,
    required this.totalExpense,
    required this.totalPaid,
    required this.totalPending,
    required this.loanBalance,
    required this.creditCardBalance,
    required this.debtBalance,
    required this.savingSuggestion,
    required this.byCategory,
  });

  final int year;
  final int month;
  final double totalExpense;
  final double totalPaid;
  final double totalPending;
  final double loanBalance;
  final double creditCardBalance;
  final double debtBalance;
  final String savingSuggestion;
  final Map<String, double> byCategory;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final byCategoryRaw = json['byCategory'] as Map<String, dynamic>? ?? {};

    return ReportModel(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      totalPending: (json['totalPending'] as num?)?.toDouble() ?? 0,
      loanBalance: (json['loanBalance'] as num?)?.toDouble() ?? 0,
      creditCardBalance: (json['creditCardBalance'] as num?)?.toDouble() ?? 0,
      debtBalance: (json['debtBalance'] as num?)?.toDouble() ?? 0,
      savingSuggestion: json['savingSuggestion'] as String? ?? '',
      byCategory: byCategoryRaw.map(
        (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
      ),
    );
  }
}
