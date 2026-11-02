import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/vendor_model.dart';

class StallPreviewSheet extends StatefulWidget {
  const StallPreviewSheet({
    super.key,
    required this.vendor,
    required this.rating,
    required this.distance,
    required this.photos,
    required this.following,
    required this.onFollow,
    required this.onDirections,
    required this.onViewMenu,
    required this.onSelfCollect,
    required this.onDetails,
    required this.onClose,
    required this.onExtentChanged,
  });

  final VendorModel vendor;
  final Widget rating;
  final String? distance;
  final List<String> photos;
  final bool following;
  final VoidCallback? onFollow, onSelfCollect;
  final VoidCallback onDirections, onViewMenu, onDetails, onClose;
  final ValueChanged<double> onExtentChanged;

  @override
  State<StallPreviewSheet> createState() => _StallPreviewSheetState();
}

class _StallPreviewSheetState extends State<StallPreviewSheet> {
  final _controller = DraggableScrollableController();
  int _photo = 0;

  void _resize(double size) {
    if (!_controller.isAttached) return;
    _controller.animateTo(size,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          widget.onExtentChanged(notification.extent);
          return false;
        },
        child: DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: .55,
          minChildSize: .28,
          maxChildSize: .94,
          snap: true,
          snapSizes: const [.28, .55, .94],
          shouldCloseOnMinExtent: false,
          builder: (context, scrollController) => Material(
            color: AppColors.cardColor,
            elevation: 12,
            shadowColor: const Color(0x33000000),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Center(
                    child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4)))),
                Row(children: [
                  Expanded(
                      child: Text('Stall preview',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12))),
                  IconButton(
                      tooltip: 'Collapse preview',
                      onPressed: () => _resize(.28),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded)),
                  IconButton(
                      tooltip: 'Expand preview',
                      onPressed: () => _resize(.94),
                      icon: const Icon(Icons.open_in_full_rounded, size: 19)),
                  IconButton(
                      tooltip: 'Close preview',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded)),
                ]),
                Text(widget.vendor.stallName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(children: [
                  Flexible(child: widget.rating),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(widget.vendor.categoryLabel,
                          style: const TextStyle(fontSize: 12)))
                ]),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: widget.vendor.isOpenNow ? 'Open now' : 'Closed',
                      style: TextStyle(
                          color: widget.vendor.isOpenNow
                              ? AppColors.openGreen
                              : AppColors.closedRed)),
                  if (widget.distance != null)
                    TextSpan(text: ' · ${widget.distance}'),
                ])),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.icon(
                      onPressed: widget.onDirections,
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      label: const Text('Directions')),
                  OutlinedButton.icon(
                      onPressed: widget.onFollow,
                      icon: Icon(
                          widget.following
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18),
                      label: Text(widget.following ? 'Following' : 'Follow')),
                  OutlinedButton.icon(
                      onPressed: widget.onViewMenu,
                      icon: const Icon(Icons.restaurant_menu, size: 18),
                      label: const Text('View menu')),
                  if (widget.vendor.selfCollectEnabled)
                    OutlinedButton.icon(
                        onPressed: widget.onSelfCollect,
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('Self-collect')),
                ]),
                const SizedBox(height: 18),
                if (widget.photos.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                        height: 190,
                        child: Stack(children: [
                          PageView.builder(
                            key: ValueKey(widget.vendor.vendorId),
                            itemCount: widget.photos.length,
                            onPageChanged: (value) =>
                                setState(() => _photo = value),
                            itemBuilder: (_, index) => Image.network(
                                widget.photos[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                    color: AppColors.mint,
                                    child: Center(
                                        child: Icon(Icons.storefront_rounded,
                                            color: AppColors.primary,
                                            size: 48)))),
                          ),
                          if (widget.photos.length > 1)
                            Positioned(
                                right: 12,
                                bottom: 12,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      color: AppColors.cardColor,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      child: Text(
                                          '${_photo + 1} / ${widget.photos.length}')),
                                )),
                        ])),
                  ),
                  if (widget.photos.length > 1)
                    const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text('Stall & menu photos',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted))),
                  const SizedBox(height: 16),
                ],
                if (widget.vendor.description.trim().isNotEmpty) ...[
                  Text(widget.vendor.description,
                      style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 16),
                ],
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Opening hours today'),
                    subtitle: Text(widget.vendor.hoursToday.isEmpty
                        ? 'Hours not provided'
                        : widget.vendor.hoursToday)),
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(widget.vendor.hasFreshLocation
                        ? 'Location updated recently'
                        : 'Last known location'),
                    subtitle: Text(widget.vendor.hasFreshLocation
                        ? 'The vendor is sharing their location.'
                        : 'This location may be outdated. Check before travelling.')),
                if (widget.vendor.selfCollectEnabled &&
                    !widget.vendor.isOpenNow)
                  const Text(
                      'Self-collect is available when this stall is open.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: widget.onDetails,
                    child: const Text('Full stall details & reviews')),
              ],
            ),
          ),
        ),
      );
}
