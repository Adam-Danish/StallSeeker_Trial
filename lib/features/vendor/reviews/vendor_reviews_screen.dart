import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/stall_review.dart';
import '../../../core/services/stall_review_service.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../../shared/stall_review_card.dart';
import 'vendor_reply_editor.dart';
import 'vendor_review_filters.dart';

class VendorReviewsScreen extends StatefulWidget {
  const VendorReviewsScreen({
    super.key,
    required this.vendorId,
    required this.stallName,
  });
  final String vendorId;
  final String stallName;
  @override
  State<VendorReviewsScreen> createState() => _VendorReviewsScreenState();
}

class _VendorReviewsScreenState extends State<VendorReviewsScreen> {
  final _service = StallReviewService();
  late Stream<List<StallReview>> _reviews;
  final _deleting = <String>{};
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _reviews = _service.watchReviews(widget.vendorId);
  }

  void _reply(StallReview review) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VendorReplyEditor(
            review: review,
            stallName: widget.stallName,
            onSave: (text) =>
                _service.saveVendorReply(widget.vendorId, review, text),
          ),
        ),
      );
  Future<void> _deleteReply(StallReview review) async {
    if (_deleting.contains(review.customerId)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your reply?'),
        content: const Text('The customer’s review will remain visible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete reply'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting.add(review.customerId));
    try {
      await _service.deleteVendorReply(widget.vendorId, review.customerId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reply deleted.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete your reply. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(review.customerId));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppPageAppBar(
          title: Text('Customer reviews'),
          showBackButton: true,
        ),
        body: SafeArea(
          child: StreamBuilder<List<StallReview>>(
            stream: _reviews,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load reviews.'),
                      TextButton(
                        onPressed: () => setState(_listen),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return VendorReviewsView(
                reviews: snapshot.data!,
                stallName: widget.stallName,
                deleting: _deleting,
                onReply: _reply,
                onDeleteReply: _deleteReply,
              );
            },
          ),
        ),
      );
}

class VendorReviewsView extends StatefulWidget {
  const VendorReviewsView({
    super.key,
    required this.reviews,
    required this.stallName,
    required this.onReply,
    required this.onDeleteReply,
    this.deleting = const {},
  });
  final List<StallReview> reviews;
  final String stallName;
  final ValueChanged<StallReview> onReply;
  final ValueChanged<StallReview> onDeleteReply;
  final Set<String> deleting;
  @override
  State<VendorReviewsView> createState() => _VendorReviewsViewState();
}

class _VendorReviewsViewState extends State<VendorReviewsView> {
  VendorReviewFilter _filter = VendorReviewFilter.all;
  VendorReviewSort _sort = VendorReviewSort.newest;
  int? _stars;
  @override
  Widget build(BuildContext context) {
    final summary = StallReviewSummary(widget.reviews);
    final reviews = filterVendorReviews(
      widget.reviews,
      filter: _filter,
      sort: _sort,
      stars: _stars,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.stallName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  summary.average == null
                      ? 'No ratings yet'
                      : '${summary.average!.toStringAsFixed(1)} ★',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.total} ${summary.total == 1 ? 'review' : 'reviews'} · ${summary.unanswered} awaiting reply',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final entry in {
                      VendorReviewFilter.all: 'All',
                      VendorReviewFilter.unanswered: 'Unanswered',
                      VendorReviewFilter.replied: 'Replied',
                      VendorReviewFilter.updated: 'Updated after reply',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _filter == entry.key,
                        onSelected: (_) => setState(() => _filter = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth < 640
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: width,
                          child: DropdownButtonFormField<int>(
                            initialValue: _stars ?? 0,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Star rating',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 0,
                                child: Text('All ratings'),
                              ),
                              for (var star = 5; star >= 1; star--)
                                DropdownMenuItem(
                                  value: star,
                                  child: Text(
                                    '$star ${star == 1 ? 'star' : 'stars'}',
                                  ),
                                ),
                            ],
                            onChanged: (value) => setState(
                              () => _stars = value == 0 ? null : value,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: DropdownButtonFormField<VendorReviewSort>(
                            initialValue: _sort,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Sort reviews',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: VendorReviewSort.newest,
                                child: Text('Newest'),
                              ),
                              DropdownMenuItem(
                                value: VendorReviewSort.lowest,
                                child: Text('Lowest rating'),
                              ),
                              DropdownMenuItem(
                                value: VendorReviewSort.highest,
                                child: Text('Highest rating'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _sort = value);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Text(
                      widget.reviews.isEmpty
                          ? 'No reviews yet. Customer feedback will appear here.'
                          : 'No reviews match these filters.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                for (final review in reviews)
                  StallReviewCard(
                    key: ValueKey(review.customerId),
                    review: review,
                    stallName: widget.stallName,
                    onReply: widget.deleting.contains(review.customerId)
                        ? null
                        : () => widget.onReply(review),
                    onDeleteReply: widget.deleting.contains(review.customerId)
                        ? null
                        : () => widget.onDeleteReply(review),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
