import 'dart:js_interop';

@JS('stallSeekerLoadMaps')
external JSPromise<JSAny?> _loadMaps();

Future<void> loadWebMaps() async {
  await _loadMaps().toDart;
}
