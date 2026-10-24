import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/vendor/profile/unsaved_stall_changes_guard.dart';

void main() {
  for (final choice in ['Keep editing', 'Discard changes', 'Save changes']) {
    testWidgets('leaving with unsaved changes: $choice', (tester) async {
      final guard = GlobalKey<UnsavedStallChangesGuardState>();
      var saved = 0;
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      child: const Text('Open editor'),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => UnsavedStallChangesGuard(
                                  key: guard,
                                  hasChanges: true,
                                  saving: false,
                                  onSave: () async {
                                    saved++;
                                    guard.currentState!.close();
                                  },
                                  child: Scaffold(
                                      appBar: AppBar(
                                          title: const Text('Edit stall')),
                                      body: TextButton(
                                          onPressed: () => guard.currentState!
                                              .requestLeave(),
                                          child: const Text('Cancel')))))))))));
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      // Exercise system back rather than only the custom Cancel button.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Save your changes?'), findsOneWidget);
      await tester.tap(find.text(choice));
      await tester.pumpAndSettle();
      expect(saved, choice == 'Save changes' ? 1 : 0);
      expect(find.text('Edit stall'),
          choice == 'Keep editing' ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
