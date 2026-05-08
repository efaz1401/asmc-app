import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final _dateOnly = DateFormat.yMMMd();
  static final _dateTime = DateFormat.yMMMd().add_jm();
  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  static String date(DateTime? value) =>
      value == null ? '—' : _dateOnly.format(value.toLocal());
  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dateTime.format(value.toLocal());
  static String money(num? value) =>
      value == null ? '—' : _money.format(value);

  static DateTime? tryParseIso(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
