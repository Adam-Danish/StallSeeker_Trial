import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/features/shared/profile_page.dart';

ProfilePage page({
  bool guest = false,
  String name = 'Adam Danish',
  String email = 'adam@example.com',
  VoidCallback? onHome,
  VoidCallback? onCustom,
  VoidCallback? onSignIn,
}) {
  void noop() {}
  return ProfilePage(
    name: name,
    email: email,
    isVendor: false,
    isGuest: guest,
    canChangePassword: true,
    location: 'Johor Bahru, Johor',
    isLoadingLocation: false,
    onRefresh: () async {},
    onLocation: noop,
    onEdit: noop,
    onPassword: noop,
    onFaq: noop,
    onAbout: noop,
    onLogout: noop,
    onSignIn: onSignIn ?? noop,
    onNotificationSettings: noop,
    onPrivacyPolicy: noop,
    onTerms: noop,
    onDeleteAccount: noop,
    onHomeLocation: onHome,
    onCustomLocation: onCustom,
  );
}

void main() {
  testWidgets(
      'saved pin rows invoke their actions and remain available to guests',
      (tester) async {
    var homes = 0;
    var customs = 0;
    var signIns = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: page(
          guest: true,
          name: 'Guest',
          email: '',
          onHome: () => homes++,
          onCustom: () => customs++,
          onSignIn: () => signIns++,
        ),
      ),
    ));

    await tester.tap(find.text('Home location'));
    await tester.tap(find.text('Custom pins'));
    await tester.tap(find.text('Sign in'));
    expect(homes, 1);
    expect(customs, 1);
    expect(signIns, 1);
    expect(find.text('Change password'), findsNothing);
    expect(find.text('Delete account'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long account details wrap on small screens with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.5),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: page(
          name: 'Adam Danish bin Muhammad Abdullah',
          email: 'adam.danish.muhammad.abdullah@example.com',
          onHome: () {},
          onCustom: () {},
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Logout'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Logout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
