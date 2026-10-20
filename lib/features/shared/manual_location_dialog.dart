import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/place_search_service.dart';

export '../../core/services/place_search_service.dart'
    show LocationSelection, PlaceSuggestion;

Future<LocationSelection?> showManualLocationDialog(
  BuildContext context, {
  LatLng? initialLocation,
  String title = 'Enter Location Manually',
  PlaceSearchService? placeSearch,
}) {
  return showDialog<LocationSelection>(
    context: context,
    builder: (_) => _ManualLocationDialog(
      title: title,
      initialLocation: initialLocation,
      placeSearch: placeSearch,
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

  if (placemarks.isEmpty) return 'Selected location';

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

    if (value.isNotEmpty && seen.add(value.toLowerCase())) {
      parts.add(value);
    }
  }

  return parts.isEmpty ? 'Selected location' : parts.join(', ');
}

class _ManualLocationDialog extends StatefulWidget {
  const _ManualLocationDialog({
    required this.title,
    required this.initialLocation,
    this.placeSearch,
  });

  final String title;
  final LatLng? initialLocation;
  final PlaceSearchService? placeSearch;

  @override
  State<_ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<_ManualLocationDialog> {
  final _placeController = TextEditingController();

  late final _placeSearch = widget.placeSearch ?? PlaceSearchService();

  Timer? _debounce;

  List<PlaceSuggestion> _suggestions = const [];
  LocationSelection? _selection;

  String? _errorText;
  String? _fallbackMessage;

  bool _isSearching = false;
  bool _isFetchingCoords = false;
  bool _usingDeviceFallback = false;

  int _requestId = 0;

  bool _isCurrent(int requestId) => mounted && requestId == _requestId;

  @override
  void dispose() {
    _requestId++;
    _debounce?.cancel();
    _placeController.dispose();

    if (widget.placeSearch == null) {
      _placeSearch.dispose();
    }

    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _requestId++;

    setState(() {
      _selection = null;
      _suggestions = const [];
      _errorText = null;
      _fallbackMessage = null;
      _usingDeviceFallback = false;
      _isSearching = false;
      _isFetchingCoords = false;
    });

    final query = value.trim();
    if (query.length < 2) return;

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _findSuggestions(query),
    );
  }

  Future<void> _findSuggestions(String value) async {
    _debounce?.cancel();

    final query = value.trim();
    if (!mounted || query.length < 2) return;

    final requestId = ++_requestId;

    setState(() {
      _isSearching = true;
      _isFetchingCoords = false;
      _selection = null;
      _suggestions = const [];
      _errorText = null;
      _fallbackMessage = null;
      _usingDeviceFallback = false;
    });

    var googleFailed = false;
    List<PlaceSuggestion> results = const [];

    try {
      results = await _placeSearch.search(query);
    } catch (_) {
      // The service logs the actual Google Places error.
      googleFailed = true;
    }

    if (!_isCurrent(requestId)) return;

    if (results.isNotEmpty) {
      setState(() {
        _suggestions = results.take(5).toList();
        _isSearching = false;
      });
      return;
    }

    final fallbackResults = await _findDeviceSuggestions(query, requestId);

    if (!_isCurrent(requestId)) return;

    setState(() {
      _isSearching = false;
      _usingDeviceFallback = true;
      _suggestions = fallbackResults;

      if (fallbackResults.isNotEmpty) {
        _fallbackMessage = googleFailed
            ? 'Google search is unavailable. These are limited device '
                'results; check the address before selecting.'
            : 'No Google suggestions found. Showing limited device results.';
      } else {
        _errorText = googleFailed
            ? 'Location search is unavailable. Try again or check '
                'your connection.'
            : 'No matching places found. Try a more specific name, '
                'such as Bukit Bintang, Kuala Lumpur.';
      }
    });
  }

  Future<List<PlaceSuggestion>> _findDeviceSuggestions(
    String query,
    int requestId,
  ) async {
    try {
      final searchQuery =
          query.toLowerCase().contains('malaysia') ? query : '$query, Malaysia';

      final locations = await Geocoding()
          .locationFromAddress(searchQuery)
          .timeout(const Duration(seconds: 8));

      if (!_isCurrent(requestId)) return [];

      final ordered = List<Location>.from(locations);
      final origin = widget.initialLocation;

      if (origin != null) {
        ordered.sort(
          (a, b) => _distanceSquared(a, origin)
              .compareTo(_distanceSquared(b, origin)),
        );
      }

      final suggestions = <PlaceSuggestion>[];
      final seen = <String>{};

      for (final location in ordered.take(3)) {
        if (!_isCurrent(requestId)) return [];

        final coordinates = LatLng(
          location.latitude,
          location.longitude,
        );

        String label;

        try {
          label = await describeLocation(coordinates);
        } catch (_) {
          label = '$query '
              '(${coordinates.latitude.toStringAsFixed(5)}, '
              '${coordinates.longitude.toStringAsFixed(5)})';
        }

        if (!_isCurrent(requestId)) return [];

        if (seen.add(label.toLowerCase())) {
          suggestions.add(
            PlaceSuggestion(
              placeId: '',
              primaryText: label,
              secondaryText: 'Device result',
              fullText: label,
              coordinates: coordinates,
            ),
          );
        }
      }

      return suggestions;
    } catch (error) {
      debugPrint('Device location search failed: $error');
      return [];
    }
  }

  double _distanceSquared(Location location, LatLng origin) {
    final latitude = location.latitude - origin.latitude;
    final longitude = location.longitude - origin.longitude;

    return latitude * latitude + longitude * longitude;
  }

  Future<void> _handleSuggestionTap(
    PlaceSuggestion suggestion,
  ) async {
    _debounce?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();

    final requestId = ++_requestId;

    if (suggestion.coordinates != null) {
      _selectSuggestion(
        LocationSelection(
          coordinates: suggestion.coordinates!,
          label: suggestion.fullText,
        ),
      );
      return;
    }

    setState(() {
      _selection = null;
      _isSearching = false;
      _isFetchingCoords = true;
      _errorText = null;
    });

    try {
      final coordinates = await _placeSearch.getCoordinates(suggestion.placeId);

      if (!_isCurrent(requestId)) return;

      if (coordinates == null) {
        setState(() {
          _isFetchingCoords = false;
          _errorText =
              'Could not load this place. Please select another result.';
        });
        return;
      }

      _selectSuggestion(
        LocationSelection(
          coordinates: coordinates,
          label: suggestion.fullText,
        ),
      );
    } catch (_) {
      if (!_isCurrent(requestId)) return;

      setState(() {
        _isFetchingCoords = false;
        _errorText = 'Could not load location details. Please try again.';
      });
    }
  }

  void _selectSuggestion(LocationSelection selection) {
    if (!mounted) return;

    setState(() {
      _selection = selection;
      _isSearching = false;
      _isFetchingCoords = false;
      _errorText = null;
    });
  }

  void _submit() {
    final selection = _selection;
    if (selection == null) return;

    _requestId++;
    _debounce?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.pop(context, selection);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSearching || _isFetchingCoords;

    return AlertDialog(
      backgroundColor: AppColors.cardColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      scrollable: true,
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search for a place in Malaysia, then select its address.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _placeController,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: _findSuggestions,
              decoration: InputDecoration(
                labelText: 'Search location',
                hintText: 'Bukit Bintang, Kuala Lumpur',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: busy
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (var index = 0; index < _suggestions.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                _suggestionTile(_suggestions[index]),
              ],
            ],
            if (_isFetchingCoords)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Getting location details…',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            if (_fallbackMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _fallbackMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.closedRed,
                ),
              ),
            ],
            if (_usingDeviceFallback && !busy)
              TextButton(
                onPressed: () => _findSuggestions(_placeController.text),
                child: const Text('Retry Google search'),
              ),
            if (_selection != null) ...[
              const SizedBox(height: 12),
              Text(
                'Selected: ${_selection!.label}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
            if (!_usingDeviceFallback && _suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Powered by Google Places',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () {
            _requestId++;
            _debounce?.cancel();
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy || _selection == null ? null : _submit,
          child: const Text('Use location'),
        ),
      ],
    );
  }

  Widget _suggestionTile(PlaceSuggestion suggestion) {
    final selected = _selection?.label == suggestion.fullText;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      selected: selected,
      leading: const Icon(Icons.location_on_outlined),
      title: Text(
        suggestion.primaryText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: suggestion.secondaryText.isEmpty
          ? null
          : Text(
              suggestion.secondaryText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: AppColors.openGreen,
            )
          : null,
      onTap: _isSearching || _isFetchingCoords
          ? null
          : () => _handleSuggestionTap(suggestion),
    );
  }
}
