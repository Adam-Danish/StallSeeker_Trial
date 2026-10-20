import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/services/place_search_service.dart';
import 'package:stallseeker/features/shared/manual_location_dialog.dart';

class FakePlacesSdk extends places.FlutterGooglePlacesSdk {
  FakePlacesSdk({this.failure}) : super('test-key');

  final Object? failure;

  String? lastQuery;
  List<String>? requestedCountries;

  @override
  Future<places.FindAutocompletePredictionsResponse>
      findAutocompletePredictions(
    String query, {
    List<String>? countries,
    List<places.PlaceTypeFilter> placeTypesFilter = const [],
    bool? newSessionToken,
    places.LatLng? origin,
    places.LatLngBounds? locationBias,
    places.LatLngBounds? locationRestriction,
  }) async {
    lastQuery = query;
    requestedCountries = countries;

    final error = failure;
    if (error != null) throw error;

    return const places.FindAutocompletePredictionsResponse([
      places.AutocompletePrediction(
        distanceMeters: null,
        placeId: 'bangi',
        primaryText: 'Bangi',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi, Selangor, Malaysia',
      ),
      places.AutocompletePrediction(
        distanceMeters: null,
        placeId: 'bangi-square',
        primaryText: 'Bangi Square',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi Square, Selangor, Malaysia',
      ),
    ]);
  }
}

class FakePlaceSearchService extends PlaceSearchService {
  FakePlaceSearchService() : super(places: FakePlacesSdk());

  @override
  Future<List<PlaceSuggestion>> search(String query) async {
    return const [
      PlaceSuggestion(
        placeId: 'bangi',
        primaryText: 'Bangi',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi, Selangor, Malaysia',
        coordinates: LatLng(2.9, 101.7),
      ),
      PlaceSuggestion(
        placeId: 'bangi-square',
        primaryText: 'Bangi Square',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi Square, Selangor, Malaysia',
        coordinates: LatLng(2.91, 101.8),
      ),
    ];
  }
}

void main() {
  group('scheduled opening in Malaysia time', () {
    final hours = <int, List<StallHoursInterval>>{
      1: [const StallHoursInterval(20 * 60, 2 * 60)],
      2: [
        const StallHoursInterval(8 * 60, 12 * 60),
        const StallHoursInterval(14 * 60, 17 * 60),
      ],
      7: [const StallHoursInterval(23 * 60, 60)],
    };

    DateTime at(int day, int hour, [int minute = 0]) =>
        malaysiaInstant(2026, 9, day, hour, minute);

    test(
      'overnight hours include next day and Sunday to Monday rollover',
      () {
        expect(isWithinStallSchedule(at(21, 0, 30), hours, []), isTrue);
        expect(isWithinStallSchedule(at(21, 20), hours, []), isTrue);
        expect(isWithinStallSchedule(at(22, 1, 59), hours, []), isTrue);
        expect(isWithinStallSchedule(at(22, 2), hours, []), isFalse);
        expect(isWithinStallSchedule(at(22, 13), hours, []), isFalse);
      },
    );

    test(
      'no saved schedule is not assumed open at a future time',
      () {
        expect(isWithinStallSchedule(at(22, 10), {}, []), isFalse);
      },
    );

    test(
      'closures override an exact time at inclusive start and exclusive end',
      () {
        final closures = [
          TemporaryClosure(at(22, 9), at(22, 10)),
        ];

        expect(
          isWithinStallSchedule(at(22, 9), hours, closures),
          isFalse,
        );
        expect(
          isWithinStallSchedule(at(22, 10), hours, closures),
          isTrue,
        );
      },
    );

    test(
      'time windows match partial openings but exclude fully closed windows',
      () {
        expect(
          hasScheduledOpening(at(21, 22), at(22, 6), hours, []),
          isTrue,
        );

        expect(
          hasScheduledOpening(
            at(22, 6),
            at(22, 12),
            hours,
            [TemporaryClosure(at(22, 8), at(22, 12))],
          ),
          isFalse,
        );

        expect(
          hasScheduledOpening(
            at(22, 6),
            at(22, 12),
            hours,
            [TemporaryClosure(at(22, 8), at(22, 10))],
          ),
          isTrue,
        );

        expect(
          hasScheduledOpening(
            at(22, 6),
            at(22, 12),
            hours,
            [
              TemporaryClosure(at(22, 8), at(22, 10)),
              TemporaryClosure(at(22, 10), at(22, 12)),
            ],
          ),
          isFalse,
        );
      },
    );
  });

  test('Google Places search requests Malaysian suggestions', () async {
    final sdk = FakePlacesSdk();
    final service = PlaceSearchService(places: sdk);

    final results = await service.search(' bangi ');

    expect(sdk.lastQuery, 'bangi');
    expect(sdk.requestedCountries, ['my']);
    expect(results.length, 2);
    expect(results.last.placeId, 'bangi-square');
    expect(
      results.last.fullText,
      'Bangi Square, Selangor, Malaysia',
    );

    service.dispose();
  });

  test('Google Places errors propagate for fallback handling', () async {
    final service = PlaceSearchService(
      places: FakePlacesSdk(
        failure: StateError('Places API unavailable'),
      ),
    );

    await expectLater(
      service.search('ipoh'),
      throwsA(isA<StateError>()),
    );

    service.dispose();
  });

  testWidgets(
    'customer can change the selected location suggestion',
    (tester) async {
      final service = FakePlaceSearchService();
      LocationSelection? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showManualLocationDialog(
                    context,
                    placeSearch: service,
                  );
                },
                child: const Text('Pick location'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick location'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'bangi');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use location'));
      await tester.pumpAndSettle();

      expect(
        selected?.label,
        'Bangi Square, Selangor, Malaysia',
      );
      expect(selected?.coordinates, const LatLng(2.91, 101.8));
      expect(tester.takeException(), isNull);

      service.dispose();
    },
  );
}
