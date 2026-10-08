import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'manual_location_dialog.dart';

class PinLocationScreen extends StatefulWidget {
  const PinLocationScreen({super.key, required this.initialLocation});
  final LatLng initialLocation;

  @override
  State<PinLocationScreen> createState() => _PinLocationScreenState();
}

class _PinLocationScreenState extends State<PinLocationScreen> {
  GoogleMapController? _controller;
  late LatLng _position = widget.initialLocation;
  String? _address;
  bool _saving = false;
  bool _mapReady = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final location = await showManualLocationDialog(context,
        initialLocation: _position, title: 'Find a place to pin');
    if (!mounted || location == null) return;
    setState(() {
      _position = location.coordinates;
      _address = location.label;
    });
    await _controller
        ?.animateCamera(CameraUpdate.newLatLngZoom(location.coordinates, 17));
  }

  Future<void> _usePin() async {
    setState(() => _saving = true);
    final position = _position;
    var label = _address;
    if (label == null) {
      try {
        label = await describeLocation(position);
      } catch (_) {
        label = '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      }
    }
    if (mounted) {
      Navigator.pop(
          context, LocationSelection(coordinates: position, label: label));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pin a location')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                  onPressed: _saving ? null : _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Search for a place'))),
          Expanded(
              child: Stack(alignment: Alignment.center, children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _position, zoom: 16),
              onMapCreated: (controller) {
                _controller = controller;
                if (mounted) setState(() => _mapReady = true);
              },
              onCameraMove: (camera) {
                if (_saving) return;
                if ((_position.latitude - camera.target.latitude).abs() >
                        .00001 ||
                    (_position.longitude - camera.target.longitude).abs() >
                        .00001) {
                  _address = null;
                }
                _position = camera.target;
              },
              scrollGesturesEnabled: !_saving,
              zoomGesturesEnabled: !_saving,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
            const IgnorePointer(
                child: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.location_pin,
                        size: 48, color: Color(0xFFFF6E41)))),
            const Positioned(
                top: 12,
                left: 20,
                right: 20,
                child: IgnorePointer(
                    child: Card(
                        child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                                'Move the map to place the pin at the exact location.',
                                textAlign: TextAlign.center))))),
          ])),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: _saving || !_mapReady ? null : _usePin,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Use this pin'))))),
        ]),
      );
}
