import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSelection {
  const LocationSelection({required this.coordinates, required this.label});

  final LatLng coordinates;
  final String label;
}

Future<LocationSelection?> showManualLocationDialog(
  BuildContext context, {
  LatLng? initialLocation,
  String title = 'Enter Location Manually',
}) {
  return showDialog<LocationSelection>(
    context: context,
    builder: (_) => _ManualLocationDialog(
      title: title,
      initialLocation: initialLocation,
    ),
  );
}

Future<String> describeLocation(LatLng coordinates) async {
  final placemarks = await Geocoding()
      .placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      )
      .timeout(const Duration(seconds: 8));
  if (placemarks.isEmpty) {
    return 'Selected location';
  }
  return _formatPlacemark(placemarks.first);
}

String _formatPlacemark(Placemark placemark) {
  final candidates = <String?>[
    placemark.name,
    placemark.subLocality,
    placemark.locality,
    placemark.subAdministrativeArea,
    placemark.administrativeArea,
    placemark.postalCode,
    placemark.country,
  ];
  final parts = <String>[];
  final seen = <String>{};
  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';
    if (value.isEmpty || !seen.add(value.toLowerCase())) {
      continue;
    }
    parts.add(value);
  }
  return parts.isEmpty ? 'Selected location' : parts.join(', ');
}

class _ManualLocationDialog extends StatefulWidget {
  const _ManualLocationDialog({
    required this.title,
    required this.initialLocation,
  });

  final String title;
  final LatLng? initialLocation;

  @override
  State<_ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<_ManualLocationDialog> {
  final _placeController = TextEditingController();
  Timer? _debounce;
  List<LocationSelection> _suggestions = const [];
  LocationSelection? _selection;
  String? _errorText;
  bool _isSearching = false;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _placeController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _requestId++;
    final query = value.trim();
    setState(() {
      _selection = null;
      _suggestions = const [];
      _errorText = null;
      _isSearching = false;
    });
    if (query.length < 3) {
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _findSuggestions(query),
    );
  }

  Future<void> _findSuggestions(String query) async {
    final requestId = ++_requestId;
    if (mounted) {
      setState(() {
        _isSearching = true;
        _errorText = null;
      });
    }
    try {
      final searchQuery =
          query.toLowerCase().contains('malaysia') ? query : '$query, Malaysia';
      final locations = await Geocoding()
          .locationFromAddress(searchQuery)
          .timeout(const Duration(seconds: 10));
      if (!mounted || requestId != _requestId) {
        return;
      }

      final ordered = List<Location>.from(locations);
      final origin = widget.initialLocation;
      if (origin != null) {
        ordered.sort((a, b) {
          final aDistance = _distanceSquared(a, origin);
          final bDistance = _distanceSquared(b, origin);
          return aDistance.compareTo(bDistance);
        });
      }

      final suggestions = <LocationSelection>[];
      final labels = <String>{};
      for (final location in ordered.take(6)) {
        if (!mounted || requestId != _requestId) {
          return;
        }
        final coordinates = LatLng(location.latitude, location.longitude);
        String label;
        try {
          label = await describeLocation(coordinates);
        } catch (_) {
          label = query;
        }
        if (labels.add(label.toLowerCase())) {
          suggestions.add(
            LocationSelection(coordinates: coordinates, label: label),
          );
        }
      }

      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _isSearching = false;
        _suggestions = suggestions;
        if (suggestions.isEmpty) {
          _errorText =
              'No matching locations were found. Please refine your search.';
        }
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _isSearching = false;
        _suggestions = const [];
        _errorText =
            'Unable to search for locations. Please check your connection and try again.';
      });
    }
  }

  double _distanceSquared(Location location, LatLng origin) {
    final latitude = location.latitude - origin.latitude;
    final longitude = location.longitude - origin.longitude;
    return latitude * latitude + longitude * longitude;
  }

  void _selectSuggestion(LocationSelection suggestion) {
    setState(() {
      _selection = suggestion;
      _suggestions = const [];
      _errorText = null;
      _placeController.text = suggestion.label;
      _placeController.selection = TextSelection.collapsed(
        offset: _placeController.text.length,
      );
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _submit() {
    final selection = _selection;
    if (selection == null) {
      setState(() {
        _errorText = 'Please select a location from the suggestions.';
      });
      return;
    }
    // Avoid registering a new inherited focus dependency while this route is
    // being removed; doing so can trigger `_dependents.isEmpty` in debug mode.
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, selection);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Search for an area, city, state, or postcode in Malaysia, then select the correct result.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _placeController,
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            onSubmitted: (value) {
              _debounce?.cancel();
              final query = value.trim();
              if (query.length >= 3) {
                _findSuggestions(query);
              }
            },
            decoration: InputDecoration(
              labelText: 'Search location',
              hintText: 'For example, Bukit Bintang',
              border: const OutlineInputBorder(),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
            ),
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(suggestion.label),
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _requestId++;
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSearching ? null : _submit,
          child: const Text('Use Location'),
        ),
      ],
    );
  }
}
