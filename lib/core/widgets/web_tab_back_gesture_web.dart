import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('stallSeekerRegisterTabBackGesture')
external JSFunction? get _register;

VoidCallback? registerWebTabBackGesture(
  bool Function(bool fromLeft) canGoBack,
  VoidCallback goBack,
) {
  final unregister = _register?.callAsFunction(
    null,
    ((JSBoolean fromLeft) => canGoBack(fromLeft.toDart).toJS).toJS,
    goBack.toJS,
  ) as JSFunction?;
  if (unregister == null) return null;
  return () => unregister.callAsFunction();
}
