import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/utils/stall_share_link.dart';
import 'package:stallseeker/features/customer/vendor_details/share_stall_button.dart';
import 'package:stallseeker/features/customer/vendor_details/shared_stall_page.dart';

void main() {
  test('public stall links round-trip a Firestore document ID', () {
    final link = stallShareLink('stall #42');
    expect(link.toString(), 'https://stallseeker.my/stall/stall%20%2342');
    expect(sharedStallId(Uri.parse(link.toString())), 'stall #42');
    expect(sharedStallId(Uri.parse('/stall-name/demo')), isNull);
    expect(sharedStallId(Uri.parse('/stall/')), isNull);
    expect(sharedStallId(Uri.parse('/stall/vendor%2Fmenu')), isNull);
    expect(sharedStallId(Uri.parse('/stall/demo/menu')), isNull);
  });

  testWidgets('copying a stall link copies the public URL', (tester) async {
    String? copied;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ShareStallButton(stallId: 'demo', stallName: 'Nasi Ayam'),
      ),
    ));
    await tester.tap(find.byTooltip('Share stall'));
    await tester.pumpAndSettle();
    expect(find.text('Nasi Ayam'), findsOneWidget);
    expect(find.text('Share on WhatsApp'), findsOneWidget);
    expect(find.text('More sharing options'), findsOneWidget);
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(copied, stallShareLink('demo').toString());
    expect(find.text('Stall link copied.'), findsOneWidget);
  });

  testWidgets('a malformed shared link reaches the unavailable page',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const Scaffold(body: Text('Explore')),
      routes: {
        '/stall': (_) => const SharedStallPage(stallId: null),
      },
      initialRoute: '/stall',
    ));
    await tester.pumpAndSettle();
    expect(find.text('This stall is no longer available.'), findsOneWidget);
    await tester.tap(find.text('Explore StallSeeker'));
    await tester.pumpAndSettle();
    expect(find.text('Explore'), findsOneWidget);
  });
}
