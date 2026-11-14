import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _preferences;

Future<void> loadLastTabs() async {
  try {
    _preferences = await SharedPreferences.getInstance();
  } catch (_) {
    // Navigation still works when local storage is unavailable.
  }
}

String _key(String accountId, String role) => 'lastTab.$role.$accountId';

int lastTab(String? accountId, String role, int tabCount) {
  if (accountId == null) return 0;
  final index = _preferences?.get(_key(accountId, role));
  return index is int && index >= 0 && index < tabCount ? index : 0;
}

Future<void> saveLastTab(String? accountId, String role, int index) async {
  if (accountId == null) return;
  try {
    await _preferences?.setInt(_key(accountId, role), index);
  } catch (_) {
    // A storage error should never interrupt a tab change.
  }
}

String? lastPage(String accountId, String role) {
  final page = _preferences?.get('lastPage.$role.$accountId');
  return page is String ? page : null;
}

Future<void> saveLastPage(String accountId, String role, String? page) async {
  try {
    final key = 'lastPage.$role.$accountId';
    if (page == null) {
      await _preferences?.remove(key);
    } else {
      await _preferences?.setString(key, page);
    }
  } catch (_) {
    // The current route is still usable without local storage.
  }
}
