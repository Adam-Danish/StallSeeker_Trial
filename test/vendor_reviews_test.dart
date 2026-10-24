import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/stall_review.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/shared/stall_review_card.dart';
import 'package:stallseeker/features/vendor/reviews/vendor_reply_editor.dart';
import 'package:stallseeker/features/vendor/reviews/vendor_review_filters.dart';
import 'package:stallseeker/features/vendor/reviews/vendor_reviews_screen.dart';
import 'package:stallseeker/features/vendor/reviews/vendor_reviews_dashboard_card.dart';

final posted = DateTime.utc(2026, 10, 24, 1);
StallReview review(String id, int stars,
        {bool replied = false,
        bool updated = false,
        List<String> photos = const []}) =>
    StallReview(
        customerId: id,
        customerName: id,
        rating: stars,
        text: 'Feedback from $id',
        photoUrls: photos,
        createdAt: posted,
        updatedAt: updated ? posted.add(const Duration(days: 2)) : posted,
        edited: updated,
        vendorReply: replied
            ? VendorReviewReply(
                text: 'Thank you, $id',
                createdAt: posted.add(const Duration(days: 1)),
                updatedAt: posted.add(const Duration(days: 3)),
                reviewUpdatedAt: posted,
                edited: true)
            : null);

void main() {
  test('legacy reviews load without new metadata or private profile reads', () {
    final value = StallReview.fromMap({
      'customerName': 'Aina',
      'rating': 4,
      'text': 'Good',
      'photoUrls': ['https://example.com/photo.jpg'],
      'updatedAt': Timestamp.fromDate(posted)
    }, 'a');
    expect(value.postedAt!.isAtSameMomentAs(posted), true);
    expect(value.hasReply, false);
    expect(value.edited, false);
    expect(value.customerAvatarUrl, '');
    expect(value.updatedAfterReply, false);
  });
  test(
      'replies do not change totals and updated reviews are separate from unanswered',
      () {
    final reviews = [
      review('Aina', 3, replied: true, updated: true),
      review('Daniel', 5)
    ];
    final summary = StallReviewSummary(reviews);
    expect(summary.average, 4);
    expect(summary.total, 2);
    expect(summary.unanswered, 1);
    expect(summary.updated, 1);
    expect(StallReviewSummary([]).average, isNull);
  });
  test(
      'updated flag compares the answered version even if reply was posted later',
      () {
    expect(review('Aina', 3, replied: true, updated: true).updatedAfterReply,
        true);
    expect(review('Aina', 3, replied: true).updatedAfterReply, false);
  });
  test('reply filters, star filters and rating sorts compose', () {
    final reviews = [
      review('A', 3, replied: true, updated: true),
      review('B', 5),
      review('C', 1, replied: true)
    ];
    expect(
        filterVendorReviews(reviews, filter: VendorReviewFilter.unanswered)
            .map((r) => r.customerId),
        ['B']);
    expect(
        filterVendorReviews(reviews, filter: VendorReviewFilter.updated)
            .map((r) => r.customerId),
        ['A']);
    expect(
        filterVendorReviews(reviews,
                filter: VendorReviewFilter.replied, stars: 1)
            .map((r) => r.customerId),
        ['C']);
    expect(
        filterVendorReviews(reviews, sort: VendorReviewSort.lowest)
            .map((r) => r.rating),
        [1, 3, 5]);
    expect(
        filterVendorReviews(reviews, sort: VendorReviewSort.highest)
            .map((r) => r.rating),
        [5, 3, 1]);
  });
  test('newest sorts by review posting date, not owner reply activity', () {
    final older = review('Old', 3, replied: true, updated: true);
    final newer = StallReview(
        customerId: 'New',
        customerName: 'New',
        rating: 5,
        text: '',
        photoUrls: const [],
        createdAt: posted.add(const Duration(days: 1)),
        updatedAt: posted.add(const Duration(days: 1)));
    expect(filterVendorReviews([older, newer]).first.customerId, 'New');
  });
  testWidgets('opening review list does not clear awaiting reply count',
      (tester) async {
    final reviews = [
      review('Aina', 3, replied: true, updated: true),
      review('Daniel', 5)
    ];
    final replies = <String>[];
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
            body: VendorReviewsView(
                reviews: reviews,
                stallName: 'Burger Pak Ali',
                onReply: (r) => replies.add(r.customerId),
                onDeleteReply: (_) {}))));
    expect(find.text('2 reviews · 1 awaiting reply'), findsOneWidget);
    await tester.tap(find.text('Unanswered'));
    await tester.pumpAndSettle();
    expect(find.text('Aina'), findsNothing);
    expect(find.text('Daniel'), findsOneWidget);
    await tester.ensureVisible(find.text('Reply'));
    await tester.tap(find.text('Reply'));
    expect(replies, ['Daniel']);
    expect(find.text('2 reviews · 1 awaiting reply'), findsOneWidget);
    await tester.ensureVisible(find.text('Updated after reply'));
    await tester.tap(find.text('Updated after reply'));
    await tester.pumpAndSettle();
    expect(find.text('Aina'), findsOneWidget);
    expect(find.text('Daniel'), findsNothing);
    expect(find.text('Stall owner'), findsOneWidget);
  });
  for (final width in [320.0, 960.0]) {
    testWidgets('review list fits $width with enlarged text', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!),
          home: Scaffold(
              body: VendorReviewsView(
                  reviews: [
                review('A customer with a long public name', 2,
                    replied: true, updated: true)
              ],
                  stallName: 'Burger Pak Ali',
                  onReply: (_) {},
                  onDeleteReply: (_) {}))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Delete reply'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('summary counts remain unchanged when owner reply is shown',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: VendorReviewSummaryContent(
                reviews: [review('A', 3, replied: true), review('B', 5)]))));
    expect(find.text('4.0 ★'), findsOneWidget);
    expect(find.text('2 reviews'), findsOneWidget);
    expect(find.text('1 awaiting reply'), findsOneWidget);
  });
  testWidgets('reply editor keeps draft on failure and posts it on retry',
      (tester) async {
    var calls = 0;
    String? postedText;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VendorReplyEditor(
                                review: review('Aina', 3),
                                stallName: 'Burger Pak Ali',
                                onSave: (text) async {
                                  calls++;
                                  if (calls == 1) throw Exception('Offline');
                                  postedText = text;
                                }))),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Feedback from Aina'), findsOneWidget);
    await tester.ensureVisible(find.text('Post reply'));
    await tester.tap(find.text('Post reply'));
    await tester.pumpAndSettle();
    expect(find.text('Write a reply before posting.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(
        find.byType(TextFormField), '  Thank you for your feedback.  ');
    await tester.ensureVisible(find.text('Post reply'));
    await tester.tap(find.text('Post reply'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your draft is still here'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '  Thank you for your feedback.  ');
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(postedText, 'Thank you for your feedback.');
    expect(find.text('Open'), findsOneWidget);
  });
  testWidgets(
      'edit reply preloads text and cancel asks before discarding draft',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: VendorReplyEditor(
            review: review('Aina', 3, replied: true),
            stallName: 'Burger Pak Ali',
            onSave: (_) async {})));
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Thank you, Aina');
    await tester.enterText(find.byType(TextFormField), 'A new reply');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this draft?'), findsOneWidget);
    await tester.tap(find.text('Keep writing'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'A new reply');
  });
  testWidgets('photo thumbnail opens the full-screen viewer', (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
            body: StallReviewCard(
                review: review('Aina', 3,
                    photos: ['https://example.com/photo.jpg']),
                stallName: 'Burger Pak Ali'))));
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(find.byType(ReviewPhotoViewer), findsOneWidget);
    expect(find.text('Photo 1 of 1'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewPhotoViewer), findsNothing);
  });
}
