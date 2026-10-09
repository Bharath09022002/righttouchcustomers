bool isValidIndianMobile(String v) =>
    RegExp(r'^[6-9]\d{9}$').hasMatch(normalizeIndianMobile(v));
bool isValidOtp(String v) => RegExp(r'^\d{4}$').hasMatch(v.trim());

/// Strips spaces/dashes and a leading +91/91/0 so pasted numbers
/// like "98765 43210" or "+91 9876543210" still validate & send.
String normalizeIndianMobile(String v) {
  var d = v.replaceAll(RegExp(r'\D'), '');
  if (d.length == 12 && d.startsWith('91')) d = d.substring(2);
  if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
  return d;
}
bool isValidEmail(String v) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
