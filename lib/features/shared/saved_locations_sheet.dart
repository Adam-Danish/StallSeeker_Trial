import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/saved_location.dart';
import '../../core/services/saved_location_service.dart';
import 'manual_location_dialog.dart';
import 'pin_location_screen.dart';

Future<LocationSelection?> showSavedLocationsSheet(
  BuildContext context, {
  required LatLng initialLocation,
  String? initialType,
}) =>
    showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF3F2F8),
      builder: (_) => _SavedLocationsSheet(
          initialLocation: initialLocation, initialType: initialType),
    );

class _SavedLocationsSheet extends StatefulWidget {
  const _SavedLocationsSheet({required this.initialLocation, this.initialType});
  final LatLng initialLocation;
  final String? initialType;

  @override
  State<_SavedLocationsSheet> createState() => _SavedLocationsSheetState();
}

class _SavedLocationsSheetState extends State<_SavedLocationsSheet> {
  final _service = SavedLocationService();
  List<SavedLocation> _locations = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final locations = await _service.load();
      if (mounted) {
        setState(() {
          _locations = locations;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Could not load saved places. Check your connection and retry.';
        });
      }
    }
  }

  Future<void> _edit({required bool home, SavedLocation? existing}) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search address'),
            onTap: () => Navigator.pop(context, 'search')),
        ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Pin on map'),
            subtitle: const Text('Choose the exact spot'),
            onTap: () => Navigator.pop(context, 'pin')),
        ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Use current search location'),
            onTap: () => Navigator.pop(context, 'current')),
      ])),
    );
    if (!mounted || method == null) return;
    final initial = existing?.coordinates ?? widget.initialLocation;
    LocationSelection? selection;
    if (method == 'search') {
      selection = await showManualLocationDialog(context,
          initialLocation: initial,
          title: home ? 'Set Home location' : 'Set custom location');
    } else if (method == 'pin') {
      selection = await Navigator.push<LocationSelection>(
          context,
          MaterialPageRoute(
              builder: (_) => PinLocationScreen(initialLocation: initial)));
    } else {
      var label = '${widget.initialLocation.latitude.toStringAsFixed(5)}, '
          '${widget.initialLocation.longitude.toStringAsFixed(5)}';
      try {
        label = await describeLocation(widget.initialLocation);
      } catch (_) {
        // Coordinates still identify the exact search location offline.
      }
      selection =
          LocationSelection(coordinates: widget.initialLocation, label: label);
    }
    if (!mounted || selection == null) return;
    final name = home ? 'Home' : await _name(existing?.name ?? '');
    if (!mounted || name == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.save(
          name: name,
          address: selection.label,
          coordinates: selection.coordinates,
          isHome: home,
          id: existing?.id);
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save this place. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _name(String initial) async {
    final controller = TextEditingController(text: initial);
    final key = GlobalKey<FormState>();
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Name this place'),
              content: Form(
                  key: key,
                  child: TextFormField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Work, campus, favourite area'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a name for this place.'
                        : null,
                  )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (key.currentState!.validate()) {
                        Navigator.pop(context, controller.text.trim());
                      }
                    },
                    child: const Text('Save place')),
              ],
            ));
    // Dispose after the closing route has finished using the text field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    return name;
  }

  Future<void> _delete(SavedLocation location) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.delete(location.id);
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not remove this place. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _pin(SavedLocation location) => ListTile(
        leading: Icon(
            location.isHome ? Icons.home_outlined : Icons.location_on_outlined,
            color: const Color(0xFF8E8E93)),
        title: Text(location.name),
        subtitle: Text(location.address,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap:
            _saving ? null : () => Navigator.pop(context, location.selection),
        trailing: PopupMenuButton<String>(
          enabled: !_saving,
          tooltip: 'Manage ${location.name}',
          onSelected: (value) {
            if (value == 'edit') {
              _edit(home: location.isHome, existing: location);
            } else {
              _delete(location);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit place')),
            PopupMenuItem(value: 'delete', child: Text('Remove place')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final homes = _locations.where((location) => location.isHome).toList();
    final custom = _locations.where((location) => !location.isHome).toList();
    return SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text(
                    widget.initialType == 'home'
                        ? 'Home location'
                        : widget.initialType == 'custom'
                            ? 'Custom locations'
                            : 'Saved places',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Choose a place to search for nearby stalls.',
                    style: TextStyle(color: Color(0xFF8E8E93))),
                const SizedBox(height: 24),
                if (_loading || _saving) const LinearProgressIndicator(),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        Expanded(child: Text(_error!)),
                        TextButton(onPressed: _load, child: const Text('Retry'))
                      ])),
                if (!_loading) ...[
                  _group('HOME', [
                    if (homes.isNotEmpty)
                      _pin(homes.first)
                    else
                      ListTile(
                          leading: const Icon(Icons.home_outlined),
                          title: const Text('Save Home location'),
                          subtitle: const Text(
                              'Keep your home pin for quick searches'),
                          onTap: _saving ? null : () => _edit(home: true)),
                  ]),
                  const SizedBox(height: 24),
                  _group('CUSTOM PLACES', [
                    ...custom.map(_pin),
                    ListTile(
                        leading: const Icon(Icons.add_location_alt_outlined),
                        title: const Text('Add custom location'),
                        onTap: _saving ? null : () => _edit(home: false)),
                  ]),
                ],
              ],
            )));
  }

  Widget _group(String label, List<Widget> rows) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        const SizedBox(height: 10),
        Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i != 0) const Divider(height: 1, thickness: .5),
                rows[i],
              ],
            ])),
      ]);
}
