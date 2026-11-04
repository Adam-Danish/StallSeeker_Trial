import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

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
    this.onReport,
    required this.onClose,
    required this.onExtentChanged,
    this.horizontalInset = 0,
    this.bottomInset = 0,
  });

  final VendorModel vendor;
  final Widget rating;
  final String? distance;
  final List<String> photos;
  final bool following;
  final VoidCallback? onFollow, onSelfCollect;
  final VoidCallback onDirections, onViewMenu, onDetails, onClose;
  final VoidCallback? onReport;
  final ValueChanged<double> onExtentChanged;
  final double horizontalInset, bottomInset;

  static const initialExtent = .55;
  static const fullExtent = 1.0;

  static double expansionProgress(double extent) {
    // Extent notifications can finish a fraction of a pixel from the snap
    // point. Normalize the endpoints so navigation becomes interactive again.
    if (extent <= initialExtent + .001) return 0;
    if (extent >= fullExtent - .001) return 1;
    return ((extent - initialExtent) / (fullExtent - initialExtent))
        .clamp(0.0, 1.0);
  }

  @override
  State<StallPreviewSheet> createState() => _StallPreviewSheetState();
}

class _StallPreviewSheetState extends State<StallPreviewSheet> {
  final _controller = DraggableScrollableController();
  int _photo = 0;
  bool _closing = false;
  bool _hasOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resize(StallPreviewSheet.initialExtent);
    });
  }

  Future<void> _resize(double size) async {
    if (!_controller.isAttached) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(size);
      return;
    }
    await _controller.animateTo(size,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic);
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    setState(() => _closing = true);
    await _resize(0);
    if (mounted) widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_controller.isAttached && _controller.size >= .999) {
            _resize(StallPreviewSheet.initialExtent);
          } else {
            _dismiss();
          }
        },
        child: NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            widget.onExtentChanged(notification.extent);
            if (notification.extent > .0001) _hasOpened = true;
            if (notification.extent <= .0001 && _hasOpened && !_closing) {
              _closing = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onClose();
              });
            }
            return false;
          },
          child: DraggableScrollableSheet(
            controller: _controller,
            initialChildSize: 0,
            minChildSize: 0,
            maxChildSize: StallPreviewSheet.fullExtent,
            snap: true,
            snapSizes: const [
              0,
              .28,
              StallPreviewSheet.initialExtent,
              StallPreviewSheet.fullExtent
            ],
            snapAnimationDuration: Duration(
                milliseconds:
                    MediaQuery.disableAnimationsOf(context) ? 1 : 320),
            shouldCloseOnMinExtent: false,
            builder: (context, scrollController) => AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final extent = _controller.isAttached
                    ? _controller.size
                    : StallPreviewSheet.initialExtent;
                final progress = StallPreviewSheet.expansionProgress(extent);
                final fullScreen = extent >= .999;
                final bottomPadding = widget.bottomInset * (1 - progress) +
                    MediaQuery.viewPaddingOf(context).bottom * progress;
                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: widget.horizontalInset * (1 - progress)),
                  child: AbsorbPointer(
                    absorbing: _closing,
                    child: Material(
                      key: const Key('stall-preview-surface'),
                      color: AppColors.cardColor,
                      elevation: 12,
                      shadowColor: const Color(0x33000000),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28 * (1 - progress))),
                      clipBehavior: Clip.antiAlias,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            ...ScrollConfiguration.of(context).dragDevices,
                            PointerDeviceKind.mouse,
                          },
                        ),
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(
                              20, 8, 20, 24 + bottomPadding),
                          children: [
                            Center(
                                child: Container(
                                    width: 38,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: AppColors.border,
                                        borderRadius:
                                            BorderRadius.circular(4)))),
                            Row(children: [
                              Expanded(
                                  child: Text(
                                      fullScreen
                                          ? 'Stall details'
                                          : 'Stall preview',
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12))),
                              IconButton(
                                  tooltip: 'Collapse preview',
                                  onPressed: () => _resize(fullScreen
                                      ? StallPreviewSheet.initialExtent
                                      : .28),
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded)),
                              IconButton(
                                  tooltip: fullScreen
                                      ? 'Exit full screen'
                                      : 'Full screen',
                                  onPressed: () => _resize(fullScreen
                                      ? StallPreviewSheet.initialExtent
                                      : StallPreviewSheet.fullExtent),
                                  icon: Icon(
                                      fullScreen
                                          ? Icons.close_fullscreen_rounded
                                          : Icons.open_in_full_rounded,
                                      size: 19)),
                              IconButton(
                                  tooltip: 'Close preview',
                                  onPressed: _dismiss,
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
                                  text: widget.vendor.isOpenNow
                                      ? 'Open now'
                                      : 'Closed',
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
                                  icon: const Icon(Icons.directions_outlined,
                                      size: 18),
                                  label: const Text('Directions')),
                              OutlinedButton.icon(
                                  onPressed: widget.onFollow,
                                  icon: Icon(
                                      widget.following
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 18),
                                  label: Text(widget.following
                                      ? 'Following'
                                      : 'Follow')),
                              OutlinedButton.icon(
                                  onPressed: widget.onViewMenu,
                                  icon: const Icon(Icons.restaurant_menu,
                                      size: 18),
                                  label: const Text('View menu')),
                              if (widget.onReport != null)
                                OutlinedButton.icon(
                                    onPressed: widget.onReport,
                                    icon: const Icon(Icons.flag_outlined,
                                        size: 18),
                                    label: const Text('Report this stall')),
                              if (widget.vendor.selfCollectEnabled)
                                OutlinedButton.icon(
                                    onPressed: widget.onSelfCollect,
                                    icon: const Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 18),
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
                                            errorBuilder: (_, __, ___) =>
                                                const ColoredBox(
                                                    color: AppColors.mint,
                                                    child: Center(
                                                        child: Icon(
                                                            Icons
                                                                .storefront_rounded,
                                                            color: AppColors
                                                                .primary,
                                                            size: 48)))),
                                      ),
                                      if (widget.photos.length > 1)
                                        Positioned(
                                            right: 12,
                                            bottom: 12,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                  color: AppColors.cardColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20)),
                                              child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
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
                                            fontSize: 11,
                                            color: AppColors.textMuted))),
                              const SizedBox(height: 16),
                            ],
                            if (widget.vendor.description
                                .trim()
                                .isNotEmpty) ...[
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
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            const SizedBox(height: 12),
                            TextButton(
                                onPressed: widget.onDetails,
                                child:
                                    const Text('Full stall details & reviews')),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
}
