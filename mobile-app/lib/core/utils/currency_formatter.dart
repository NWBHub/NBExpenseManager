import 'package:intl/intl.dart';

final _inrFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'INR ',
  decimalDigits: 0,
);

String formatInr(num value) => _inrFormatter.format(value);
