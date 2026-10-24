import '../../../core/models/stall_review.dart';

enum VendorReviewFilter { all, unanswered, replied, updated }

enum VendorReviewSort { newest, lowest, highest }

List<StallReview> filterVendorReviews(
  List<StallReview> reviews, {
  VendorReviewFilter filter = VendorReviewFilter.all,
  VendorReviewSort sort = VendorReviewSort.newest,
  int? stars,
}) {
  final result = reviews
      .where(
        (review) =>
            (stars == null || review.rating == stars) &&
            switch (filter) {
              VendorReviewFilter.all => true,
              VendorReviewFilter.unanswered => !review.hasReply,
              VendorReviewFilter.replied => review.hasReply,
              VendorReviewFilter.updated => review.updatedAfterReply,
            },
      )
      .toList();
  result.sort((a, b) {
    final rating = switch (sort) {
      VendorReviewSort.lowest => a.rating.compareTo(b.rating),
      VendorReviewSort.highest => b.rating.compareTo(a.rating),
      VendorReviewSort.newest => 0,
    };
    if (rating != 0) return rating;
    final date = (b.postedAt ?? DateTime(0)).compareTo(
      a.postedAt ?? DateTime(0),
    );
    return date != 0 ? date : a.customerId.compareTo(b.customerId);
  });
  return result;
}
