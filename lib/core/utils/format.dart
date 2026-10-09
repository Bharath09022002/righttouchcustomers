import 'package:intl/intl.dart';
import '../config/env.dart';

String inr(num? v) {
  if (v == null) return '${Env.currencySymbol}--';
  final f = NumberFormat.currency(symbol: '${Env.currencySymbol} ', decimalDigits: 0);
  return f.format(v);
}

String fmtDate(dynamic v) {
  if (v == null) return '--';
  try {
    final d = v is DateTime ? v : DateTime.parse(v.toString());
    return DateFormat('dd MMM yyyy, hh:mm a').format(d.toLocal());
  } catch (_) {
    return v.toString();
  }
}

String titleCase(String s) {
  if (s.isEmpty) return s;
  return s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}
