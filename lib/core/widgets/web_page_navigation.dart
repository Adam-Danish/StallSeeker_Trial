import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const customerTabPaths = ['/home', '/following', '/notifications', '/settings'];
const vendorTabPaths = ['/vendor/dashboard', '/vendor/settings'];

int? tabIndexForPath(String? path, List<String> tabs) {
  final index = tabs.indexOf(path ?? '');
  return index < 0 ? null : index;
}

final webPageNavigation = WebPageNavigation();

/// Keep an IndexedStack tab's address in sync with Navigator's page history.
class WebPageNavigation extends NavigatorObserver {
  Route<dynamic>? _shell;
  String? _tabPath;

  void showShellPath(Route<dynamic>? shell, String path) {
    if (!kIsWeb || shell == null) return;
    _shell = shell;
    _tabPath = path;
    _publishTab(shell);
  }

  void _publishTab(Route<dynamic> shell, {bool force = false}) {
    final path = _tabPath;
    if (!shell.isCurrent || path == null || (!force && Uri.base.path == path)) {
      return;
    }
    unawaited(SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(path),
      replace: true,
    ));
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    if (kIsWeb && identical(topRoute, _shell)) {
      // Navigator reports the shell route name after notifying observers.
      scheduleMicrotask(() {
        if (identical(topRoute, _shell)) _publishTab(topRoute, force: true);
      });
    }
  }
}
