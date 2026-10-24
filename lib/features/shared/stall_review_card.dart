import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/stall_review.dart';
import '../../core/widgets/app_page_app_bar.dart';

String reviewDate(DateTime? value) {
  if (value == null) return 'Date unavailable';
  final date = value.toUtc().add(const Duration(hours: 8));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class StallReviewCard extends StatelessWidget {
  const StallReviewCard({
    super.key,
    required this.review,
    required this.stallName,
    this.onReply,
    this.onDeleteReply,
    this.onEditReview,
    this.onDeleteReview,
  });
  final StallReview review;
  final String stallName;
  final VoidCallback? onReply;
  final VoidCallback? onDeleteReply;
  final VoidCallback? onEditReview;
  final VoidCallback? onDeleteReview;

  @override
  Widget build(BuildContext context) {
    final initial = review.customerName.trim().isEmpty
        ? '?'
        : review.customerName.trim().characters.first.toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: Container(
                    width: 44,
                    height: 44,
                    color: AppColors.mint,
                    child: review.customerAvatarUrl.isEmpty
                        ? fallback
                        : Image.network(
                            review.customerAvatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => fallback,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customerName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reviewDate(review.postedAt)}${review.edited ? ' · Edited' : ''}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              label: '${review.rating} out of 5 stars',
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    for (var star = 1; star <= 5; star++)
                      Icon(
                        star <= review.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),
            if (review.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.text, style: const TextStyle(height: 1.5)),
            ],
            if (review.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => Semantics(
                    button: true,
                    label: 'View review photo ${index + 1}',
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewPhotoViewer(
                            urls: review.photoUrls,
                            initialIndex: index,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          review.photoUrls[index],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 90,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (review.updatedAfterReply) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Review updated after the owner’s reply',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
            ],
            if (review.hasReply) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Reply from $stallName',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Stall owner',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${reviewDate(review.vendorReply!.createdAt)}${review.vendorReply!.edited ? ' · Edited' : ''}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      review.vendorReply!.text,
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
            if (onReply != null ||
                onDeleteReply != null ||
                onEditReview != null ||
                onDeleteReview != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (onReply != null)
                    TextButton.icon(
                      onPressed: onReply,
                      icon: const Icon(Icons.reply_rounded, size: 19),
                      label: Text(review.hasReply ? 'Edit reply' : 'Reply'),
                    ),
                  if (review.hasReply && onDeleteReply != null)
                    TextButton(
                      onPressed: onDeleteReply,
                      child: const Text('Delete reply'),
                    ),
                  if (onEditReview != null)
                    TextButton(
                      onPressed: onEditReview,
                      child: const Text('Edit your review'),
                    ),
                  if (onDeleteReview != null)
                    TextButton(
                      onPressed: onDeleteReview,
                      child: const Text('Delete your review'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReviewPhotoViewer extends StatefulWidget {
  const ReviewPhotoViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });
  final List<String> urls;
  final int initialIndex;
  @override
  State<ReviewPhotoViewer> createState() => _ReviewPhotoViewerState();
}

class _ReviewPhotoViewerState extends State<ReviewPhotoViewer> {
  late final PageController _controller;
  late int _index;
  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppPageAppBar(
      showBackButton: true,
      title: Text('Photo ${_index + 1} of ${widget.urls.length}'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    body: PageView.builder(
      controller: _controller,
      itemCount: widget.urls.length,
      onPageChanged: (index) => setState(() => _index = index),
      itemBuilder: (context, index) => InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image.network(
            widget.urls[index],
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : const CircularProgressIndicator(),
            errorBuilder: (_, __, ___) => const Text(
              'Could not load photo.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}
