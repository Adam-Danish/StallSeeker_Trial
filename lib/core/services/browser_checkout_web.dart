import 'dart:js_interop';

@JS('window.open')
external _BrowserWindow? _openWindow(String url, String target);

extension type _BrowserWindow._(JSObject _) implements JSObject {
  external bool get closed;
  external set location(String url);
  external set opener(JSAny? value);
  external void close();
}

/// Reserve a tab during the click gesture, before checkout's network request.
class BrowserCheckoutWindow {
  BrowserCheckoutWindow._(this._window);
  final _BrowserWindow _window;

  static BrowserCheckoutWindow? open() {
    final window = _openWindow('about:blank', '_blank');
    if (window == null) return null;
    window.opener = null;
    return BrowserCheckoutWindow._(window);
  }

  bool navigate(Uri uri) {
    if (_window.closed) return false;
    _window.location = uri.toString();
    return true;
  }

  void close() => _window.close();
}
