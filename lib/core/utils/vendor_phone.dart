/// Normalizes Malaysian vendor contact numbers for display and tap-to-call.
/// This checks format only; it does not verify ownership of the number.
String? normalizeVendorPhone(String input) {
  var value = input.replaceAll(RegExp(r'[\s()\-]'), '');
  if (value.startsWith('+60')) {
    value = value.substring(3);
  } else if (value.startsWith('60')) {
    value = value.substring(2);
  } else if (value.startsWith('0')) {
    value = value.substring(1);
  } else {
    return null;
  }
  final mobile = RegExp(r'^1[0-9]{8,9}$');
  final landline = RegExp(r'^[2-9][0-9]{7,8}$');
  return mobile.hasMatch(value) || landline.hasMatch(value)
      ? '+60$value'
      : null;
}
