import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/web_maps_loader.dart';

class WebMapLoader extends StatefulWidget {
  const WebMapLoader({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<WebMapLoader> createState() => _WebMapLoaderState();
}

class _WebMapLoaderState extends State<WebMapLoader> {
  static bool _mapsReady = false;
  late Future<void> _maps = _loadMaps();

  Future<void> _loadMaps() async {
    await loadWebMaps();
    _mapsReady = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _mapsReady) return widget.builder(context);
    return FutureBuilder<void>(
      future: _maps,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load the map.'),
                TextButton(
                  onPressed: () => setState(() => _maps = _loadMaps()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return widget.builder(context);
      },
    );
  }
}
