import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'web_page_navigation.dart';
import 'web_tab_back_gesture_stub.dart'
    if (dart.library.js_interop) 'web_tab_back_gesture_web.dart';

/// Adds tab changes to the enclosing route's back history.
mixin TabNavigationHistory<T extends StatefulWidget> on State<T> {
  final _tabHistory = <LocalHistoryEntry>[];
  double _backDragDistance = 0;
  VoidCallback? _unregisterWebBackGesture;

  void showTabPath(String path) {
    if (!kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        webPageNavigation.showShellPath(ModalRoute.of(context), path);
    });
  }

  void rememberTabChange(VoidCallback restoreTab) {
    final route = ModalRoute.of(context);
    if (route == null) return;

    late final LocalHistoryEntry entry;
    entry = LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: () {
        if (_tabHistory.remove(entry) && mounted) restoreTab();
      },
    );
    _tabHistory.add(entry);
    route.addLocalHistoryEntry(entry);
    if (kIsWeb && Theme.of(context).platform == TargetPlatform.iOS) {
      _unregisterWebBackGesture ??= registerWebTabBackGesture(
        (fromLeft) =>
            mounted &&
            _tabHistory.isNotEmpty &&
            route.isCurrent &&
            fromLeft == (Directionality.of(context) == TextDirection.ltr),
        () {
          if (mounted && _tabHistory.isNotEmpty && route.isCurrent) {
            Navigator.maybePop(context);
          }
        },
      );
    }
  }

  Widget withTabBackGesture(BuildContext context, Widget child) {
    final direction = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        // Flutter's iOS route gesture does not pop local history entries.
        if (_unregisterWebBackGesture == null &&
            _tabHistory.isNotEmpty &&
            Theme.of(context).platform == TargetPlatform.iOS)
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: 20,
            child: PointerInterceptor(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onHorizontalDragStart: (_) => _backDragDistance = 0,
                onHorizontalDragUpdate: (details) {
                  _backDragDistance += details.delta.dx * direction;
                },
                onHorizontalDragEnd: (details) {
                  final velocity = details.velocity.pixelsPerSecond.dx;
                  if ((_backDragDistance >= 64 ||
                          (_backDragDistance > 0 &&
                              velocity * direction > 500)) &&
                      ModalRoute.isCurrentOf(context) == true) {
                    Navigator.maybePop(context);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _unregisterWebBackGesture?.call();
    while (_tabHistory.isNotEmpty) {
      _tabHistory.removeLast().remove();
    }
    super.dispose();
  }
}
