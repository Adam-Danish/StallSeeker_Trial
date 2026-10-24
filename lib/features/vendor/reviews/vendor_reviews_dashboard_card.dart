import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/stall_review.dart';
import '../../../core/services/stall_review_service.dart';
import 'vendor_reviews_screen.dart';

class VendorReviewsDashboardCard extends StatefulWidget {
  const VendorReviewsDashboardCard({
    super.key,
    required this.vendorId,
    required this.stallName,
  });
  final String vendorId;
  final String stallName;
  @override
  State<VendorReviewsDashboardCard> createState() =>
      _VendorReviewsDashboardCardState();
}

class _VendorReviewsDashboardCardState
    extends State<VendorReviewsDashboardCard> {
  final _service = StallReviewService();
  late Stream<List<StallReview>> _reviews;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _reviews = _service.watchReviews(widget.vendorId);
  }

  @override
  void didUpdateWidget(covariant VendorReviewsDashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendorId != widget.vendorId) _listen();
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reviews',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              StreamBuilder<List<StallReview>>(
                stream: _reviews,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Could not load review summary.'),
                        TextButton(
                          onPressed: () => setState(_listen),
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return VendorReviewSummaryContent(reviews: snapshot.data!);
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorReviewsScreen(
                      vendorId: widget.vendorId,
                      stallName: widget.stallName,
                    ),
                  ),
                ),
                icon: const Icon(Icons.rate_review_outlined, size: 19),
                label: const Text('View reviews'),
              ),
            ],
          ),
        ),
      );
}

class VendorReviewSummaryContent extends StatelessWidget {
  const VendorReviewSummaryContent({super.key, required this.reviews});
  final List<StallReview> reviews;
  @override
  Widget build(BuildContext context) {
    final summary = StallReviewSummary(reviews);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary.average == null
              ? 'No ratings yet'
              : '${summary.average!.toStringAsFixed(1)} ★',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '${summary.total} ${summary.total == 1 ? 'review' : 'reviews'}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        Text(
          '${summary.unanswered} awaiting reply',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (summary.updated > 0) ...[
          const SizedBox(height: 6),
          Text(
            '${summary.updated} updated after your reply',
            style: const TextStyle(color: AppColors.primary),
          ),
        ],
      ],
    );
  }
}
