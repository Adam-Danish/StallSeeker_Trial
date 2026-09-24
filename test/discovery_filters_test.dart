import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/services/place_search_service.dart';
import 'package:stallseeker/features/shared/manual_location_dialog.dart';

Map<String, Object> feature(String name, double lon, {String country = 'MY'}) =>
    {
      'properties': {'name': name, 'countrycode': country, 'state': 'Selangor'},
      'geometry': {
        'coordinates': [lon, 2.9]
      },
    };

void main() {
  group('scheduled opening in Malaysia time', () {
    final hours = <int, List<StallHoursInterval>>{
      1: [const StallHoursInterval(20 * 60, 2 * 60)],
      2: [
        const StallHoursInterval(8 * 60, 12 * 60),
        const StallHoursInterval(14 * 60, 17 * 60)
      ],
      7: [const StallHoursInterval(23 * 60, 60)],
    };
    DateTime at(int day, int hour, [int minute = 0]) =>
        malaysiaInstant(2026, 9, day, hour, minute);
    test('overnight hours include next day and Sunday to Monday rollover', () {
      expect(isWithinStallSchedule(at(21, 0, 30), hours, []), isTrue);
      expect(isWithinStallSchedule(at(21, 20), hours, []), isTrue);
      expect(isWithinStallSchedule(at(22, 1, 59), hours, []), isTrue);
      expect(isWithinStallSchedule(at(22, 2), hours, []), isFalse);
      expect(isWithinStallSchedule(at(22, 13), hours, []), isFalse);
    });
    test('no saved schedule is not assumed open at a future time', () {
      expect(isWithinStallSchedule(at(22, 10), {}, []), isFalse);
    });
    test('closures override an exact time at inclusive start and exclusive end',
        () {
      final closures = [TemporaryClosure(at(22, 9), at(22, 10))];
      expect(isWithinStallSchedule(at(22, 9), hours, closures), isFalse);
      expect(isWithinStallSchedule(at(22, 10), hours, closures), isTrue);
    });
    test('time windows match partial openings but exclude fully closed windows',
        () {
      expect(hasScheduledOpening(at(21, 22), at(22, 6), hours, []), isTrue);
      expect(
          hasScheduledOpening(at(22, 6), at(22, 12), hours,
              [TemporaryClosure(at(22, 8), at(22, 12))]),
          isFalse);
      expect(
          hasScheduledOpening(at(22, 6), at(22, 12), hours,
              [TemporaryClosure(at(22, 8), at(22, 10))]),
          isTrue);
      expect(
          hasScheduledOpening(at(22, 6), at(22, 12), hours, [
            TemporaryClosure(at(22, 8), at(22, 10)),
            TemporaryClosure(at(22, 10), at(22, 12))
          ]),
          isFalse);
    });
  });

  test(
      'autocomplete returns distinct Malaysian suggestions and retries one-result searches',
      () async {
    final requests = <Uri>[];
    final service = PlaceSearchService(client: MockClient((request) async {
      requests.add(request.url);
      return http.Response(
          jsonEncode({
            'features': requests.length == 1
                ? [feature('Bangi', 101.7)]
                : [
                    feature('Bangi', 101.7),
                    feature('Bangi Square', 101.8),
                    feature('Outside Malaysia', 100, country: 'TH')
                  ]
          }),
          200);
    }));
    final results =
        await service.search('bangi', origin: const LatLng(2.9, 101.7));
    expect(results.length, 2);
    expect(results.last.label, contains('Bangi Square'));
    expect(requests.first.queryParameters['countrycode'], 'MY');
    expect(requests.last.queryParameters.containsKey('lat'), isFalse);
    service.dispose();
  });

  test('temporary HTTP failure retries and returns multiple options', () async {
    var count = 0;
    final service = PlaceSearchService(client: MockClient((_) async {
      if (++count == 1) return http.Response('unavailable', 503);
      return http.Response(
          jsonEncode({
            'features': [feature('Ipoh', 101), feature('Ipoh Garden', 101.1)]
          }),
          200);
    }));
    expect((await service.search('ipoh')).length, 2);
    service.dispose();
  });

  testWidgets(
      'typing shows a dropdown and customer can change the selected suggestion',
      (tester) async {
    final service = PlaceSearchService(
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'features': [
                feature('Bangi', 101.7),
                feature('Bangi Square', 101.8)
              ],
            }),
            200)));
    LocationSelection? selected;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      selected = await showManualLocationDialog(context,
                          placeSearch: service);
                    },
                    child: const Text('Pick location'))))));
    await tester.tap(find.text('Pick location'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bangi');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    await tester.tap(find.byType(ListTile).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Location'));
    await tester.pumpAndSettle();
    expect(selected?.label, contains('Bangi Square'));
    service.dispose();
  });
}
