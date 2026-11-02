import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stall_categories.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/stall_schedule.dart';
import 'discovery_options.dart';

/// One menu style, inherited by category, filters, more options and submenus.
const discoveryMenuStyle = MenuStyle(
  backgroundColor: WidgetStatePropertyAll(Colors.white),
  surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
  shadowColor: WidgetStatePropertyAll(Color(0x26000000)),
  elevation: WidgetStatePropertyAll(8),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)))),
);

class DiscoveryMenuChoice extends StatelessWidget {
  const DiscoveryMenuChoice(
      {super.key,
      required this.label,
      required this.selected,
      required this.onPressed,
      this.keepOpen = false});
  final String label;
  final bool selected, keepOpen;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
        checked: selected,
        child: MenuItemButton(
          leadingIcon: SizedBox(
              width: 20,
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 20, color: AppColors.primary)
                  : null),
          closeOnActivate: !keepOpen,
          onPressed: onPressed,
          child: Text(label),
        ),
      );
}

class DiscoveryMapFilters extends StatelessWidget {
  const DiscoveryMapFilters(
      {super.key,
      required this.category,
      required this.openNow,
      required this.sort,
      required this.availableOnly,
      required this.selfCollectOnly,
      required this.recentOnly,
      required this.onCategory,
      required this.onOpenNow,
      required this.onSort,
      required this.onAvailable,
      required this.onSelfCollect,
      required this.onRecent,
      required this.onReset,
      required this.moreItems,
      this.hasExtraFilters = false});
  final String? category;
  final bool openNow,
      availableOnly,
      selfCollectOnly,
      recentOnly,
      hasExtraFilters;
  final DiscoverySort sort;
  final ValueChanged<String?> onCategory;
  final ValueChanged<bool> onOpenNow, onAvailable, onSelfCollect, onRecent;
  final ValueChanged<DiscoverySort> onSort;
  final VoidCallback onReset;
  final List<Widget> moreItems;

  @override
  Widget build(BuildContext context) {
    final active = hasExtraFilters ||
        openNow ||
        sort != DiscoverySort.distance ||
        availableOnly ||
        selfCollectOnly ||
        recentOnly;
    final rowStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(220, 48)),
      padding:
          const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
      textStyle: WidgetStatePropertyAll(Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(fontSize: 14, height: 1.3)),
      foregroundColor: const WidgetStatePropertyAll(AppColors.textDark),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)
              ? AppColors.mint
              : Colors.white),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
    );
    return MenuTheme(
      data: const MenuThemeData(style: discoveryMenuStyle),
      child: MenuButtonTheme(
        data: MenuButtonThemeData(style: rowStyle),
        child: Row(children: [
          Flexible(
            fit: FlexFit.loose,
            child: Material(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(28),
              elevation: 2,
              child: MenuAnchor(
                style: discoveryMenuStyle,
                menuChildren: [
                  for (final value in ['All stalls', ...stallCategories])
                    DiscoveryMenuChoice(
                        label: value,
                        selected: value == (category ?? 'All stalls'),
                        onPressed: () =>
                            onCategory(value == 'All stalls' ? null : value)),
                ],
                builder: (_, controller, __) => Tooltip(
                  message: 'Choose stall category',
                  child: TextButton(
                    style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: AppColors.textDark,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 18)),
                    onPressed: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                          child: Text(category ?? 'All stalls',
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      const Icon(Icons.expand_more_rounded, size: 20),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(28),
            elevation: 2,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              MenuAnchor(
                  style: discoveryMenuStyle,
                  menuChildren: moreItems,
                  builder: (_, controller, __) => IconButton(
                      tooltip: 'More map options',
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open())),
              MenuAnchor(
                  style: discoveryMenuStyle,
                  menuChildren: [
                    DiscoveryMenuChoice(
                        label: 'Open now',
                        selected: openNow,
                        keepOpen: true,
                        onPressed: () => onOpenNow(!openNow)),
                    const Divider(height: 1),
                    DiscoveryMenuChoice(
                        label: 'Top rated',
                        selected: sort == DiscoverySort.rating,
                        keepOpen: true,
                        onPressed: () => onSort(sort == DiscoverySort.rating
                            ? DiscoverySort.distance
                            : DiscoverySort.rating)),
                    const Divider(height: 1),
                    DiscoveryMenuChoice(
                        label: 'Available dishes',
                        selected: availableOnly,
                        keepOpen: true,
                        onPressed: () => onAvailable(!availableOnly)),
                    DiscoveryMenuChoice(
                        label: 'Self-collect',
                        selected: selfCollectOnly,
                        keepOpen: true,
                        onPressed: () => onSelfCollect(!selfCollectOnly)),
                    DiscoveryMenuChoice(
                        label: 'Updated in 24h',
                        selected: recentOnly,
                        keepOpen: true,
                        onPressed: () => onRecent(!recentOnly)),
                    SubmenuButton(
                        menuStyle: discoveryMenuStyle,
                        menuChildren: [
                          for (final value in DiscoverySort.values)
                            DiscoveryMenuChoice(
                                label: value.label,
                                selected: sort == value,
                                onPressed: () => onSort(value)),
                        ],
                        child: const Text('Sort results')),
                    MenuItemButton(
                        onPressed: onReset, child: const Text('Reset filters')),
                  ],
                  builder: (_, controller, __) => IconButton.filledTonal(
                      tooltip: 'Filter stalls',
                      icon: const Icon(Icons.filter_list_rounded),
                      style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor:
                              active ? AppColors.primary : AppColors.mint,
                          foregroundColor:
                              active ? Colors.white : AppColors.primary),
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open())),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Shared geometry: tablets keep the same full-width header and centered cards.
class DiscoveryMapGeometry {
  DiscoveryMapGeometry(Size size)
      : overlayWidth = math.max(0.0, size.width - 24),
        panelWidth = size.width,
        panelLeft = 0;
  final double overlayWidth, panelWidth, panelLeft;
  bool get multipleCards => panelWidth >= 600;
  int get cardsPerPage =>
      multipleCards ? (panelWidth / 360).floor().clamp(2, 4) : 1;
  double get viewportFraction => .94;
  double get cardWidth => cardsPerPage == 1
      ? panelWidth * viewportFraction - 10
      : (panelWidth * viewportFraction - 10) / cardsPerPage - 10;
  double get previewInset => math.max(0.0, (panelWidth - 520) / 2);
}

/// Use actual hours when available; never invent an opening time.
String stallCardOpeningText(VendorModel vendor, {DateTime? now}) {
  final instant = (now ?? DateTime.now()).toUtc();
  final local = malaysiaTime(instant);
  final today = DateTime.utc(local.year, local.month, local.day);
  final closedBySchedule =
      vendor.temporaryClosures.any((c) => c.contains(instant));
  final open = vendor.isOpen && !closedBySchedule;
  DateTime? next;
  for (var offset = -1; offset <= 7; offset++) {
    final day = today.add(Duration(days: offset));
    for (final interval
        in vendor.weeklyHours[day.weekday] ?? <StallHoursInterval>[]) {
      final midnight = malaysiaInstant(day.year, day.month, day.day, 0, 0);
      var start = midnight.add(Duration(minutes: interval.openMinute));
      var end = midnight.add(Duration(
          minutes: interval.closeMinute +
              (interval.closeMinute < interval.openMinute ? 1440 : 0)));
      if (open && !instant.isBefore(start) && instant.isBefore(end)) {
        for (final closure in vendor.temporaryClosures) {
          if (closure.start.isAfter(instant) && closure.start.isBefore(end)) {
            end = closure.start;
          }
        }
        final close = malaysiaTime(end);
        return 'Closes ${formatStallTime(close.hour * 60 + close.minute).replaceFirst(':00', '')}';
      }
      if (!open) {
        if (closedBySchedule &&
            start.isBefore(instant) &&
            end.isAfter(instant)) {
          start = instant;
        }
        final closures = [...vendor.temporaryClosures]
          ..sort((a, b) => a.start.compareTo(b.start));
        for (final closure in closures) {
          if (closure.contains(start)) start = closure.end;
        }
        if (start.isAfter(instant) &&
            start.isBefore(end) &&
            (next == null || start.isBefore(next))) {
          next = start;
        }
      }
    }
  }
  if (!open && next != null) {
    final opening = malaysiaTime(next);
    final days = DateTime.utc(opening.year, opening.month, opening.day)
        .difference(today)
        .inDays;
    if (days == 0) {
      return 'Opens ${formatStallTime(opening.hour * 60 + opening.minute).replaceFirst(':00', '')}';
    }
    if (days == 1) return 'Opens tomorrow';
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return 'Opens ${weekdays[opening.weekday - 1]}';
  }
  return vendor.weeklyHours.isEmpty ? vendor.openingHours.trim() : '';
}

/// Retain fractional scroll positions when map selection rebuilds the cards.
class StallCardCarousel extends StatefulWidget {
  const StallCardCarousel({
    super.key,
    required this.ids,
    required this.selectedId,
    required this.onSelected,
    required this.itemBuilder,
    this.viewportFraction = .94,
    this.cardsPerPage = 1,
  });

  final List<String> ids;
  final String? selectedId;
  final ValueChanged<int> onSelected;
  final IndexedWidgetBuilder itemBuilder;
  final double viewportFraction;
  final int cardsPerPage;

  @override
  State<StallCardCarousel> createState() => _StallCardCarouselState();
}

class _StallCardCarouselState extends State<StallCardCarousel> {
  final _controller = ScrollController();
  static const _edgePadding = 12.0;
  static const _cardGap = 10.0;
  double _viewportWidth = 0;
  double _cardWidth = 0;
  bool _programmatic = false;
  bool _revealScheduled = false;
  String? _scrollSelectedId;

  @override
  void didUpdateWidget(covariant StallCardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reordered = oldWidget.ids.join('\u0000') != widget.ids.join('\u0000');
    if (!reordered && widget.selectedId == _scrollSelectedId) {
      _scrollSelectedId = null;
      return;
    }
    if (oldWidget.selectedId != widget.selectedId || reordered) {
      _scheduleReveal();
    }
  }

  void _scheduleReveal() {
    if (_revealScheduled) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (!mounted || !_controller.hasClients) return;
      final index = widget.ids.indexOf(widget.selectedId ?? '');
      final offset = index < 0
          ? 0.0
          : _edgePadding +
              index * (_cardWidth + _cardGap) +
              _cardWidth / 2 -
              _viewportWidth / 2;
      _programmatic = true;
      _controller
          .jumpTo(offset.clamp(0.0, _controller.position.maxScrollExtent));
      _programmatic = false;
    });
  }

  bool _onScrollEnd(ScrollEndNotification notification) {
    if (notification.depth != 0 ||
        _programmatic ||
        _revealScheduled ||
        widget.ids.isEmpty ||
        !_controller.hasClients) {
      return false;
    }
    final offset = _controller.offset;
    final maximum = _controller.position.maxScrollExtent;
    final index = offset <= .5
        ? 0
        : maximum > 0 && offset >= maximum - .5
            ? widget.ids.length - 1
            : ((offset + _viewportWidth / 2 - _edgePadding - _cardWidth / 2) /
                    (_cardWidth + _cardGap))
                .round()
                .clamp(0, widget.ids.length - 1);
    if (widget.ids[index] != widget.selectedId) {
      _scrollSelectedId = widget.ids[index];
      widget.onSelected(index);
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final pageWidth = constraints.maxWidth * widget.viewportFraction;
        final cardWidth = math.max(
            1.0,
            widget.cardsPerPage == 1
                ? pageWidth - 10
                : (pageWidth - 10) / widget.cardsPerPage - 10);
        if (_viewportWidth != constraints.maxWidth || _cardWidth != cardWidth) {
          _viewportWidth = constraints.maxWidth;
          _cardWidth = cardWidth;
          _scheduleReveal();
        }
        return NotificationListener<ScrollEndNotification>(
          onNotification: _onScrollEnd,
          child: ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
                scrollbars: false,
                dragDevices: PointerDeviceKind.values.toSet()),
            child: ListView.separated(
              key: const ValueKey('stall-card-carousel'),
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: _edgePadding, vertical: 5),
              itemCount: widget.ids.length,
              separatorBuilder: (_, __) => const SizedBox(width: _cardGap),
              itemBuilder: (context, index) =>
                  SizedBox(width: cardWidth, child: _card(context, index)),
            ),
          ),
        );
      });

  Widget _card(BuildContext context, int index) => KeyedSubtree(
      key: ValueKey(widget.ids[index]),
      child: Semantics(
          selected: widget.ids[index] == widget.selectedId,
          child: Align(
              alignment: Alignment.bottomCenter,
              child: widget.itemBuilder(context, index))));
}

class StallMapCard extends StatelessWidget {
  const StallMapCard({super.key, required this.vendor, required this.onTap});
  final VendorModel vendor;
  final VoidCallback onTap;

  // Flutter uses logical pixels. Keep the reference layout compact instead of
  // enlarging screenshot pixels again on a tablet's wider viewport.
  static const _photoSize = 64.0;
  static const _titleStyle = TextStyle(
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w600,
      color: Color(0xFF222222));
  static const _metaStyle =
      TextStyle(fontSize: 14, height: 1.3, color: Color(0xFF222222));
  static const _bodyStyle =
      TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF696969));

  static double preferredHeight(
      BuildContext context, double carouselWidth, Iterable<VendorModel> vendors,
      {double viewportFraction = .94, int cardsPerPage = 1}) {
    final width = cardsPerPage == 1
        ? carouselWidth * viewportFraction - 10
        : (carouselWidth * viewportFraction - 10) / cardsPerPage - 10;
    const padding = 14.0;
    final inherited = DefaultTextStyle.of(context).style;
    final painter = TextPainter(
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 3,
        ellipsis: '…');
    double measure(String text, TextStyle style) {
      painter.text = TextSpan(text: text, style: inherited.merge(style));
      painter.layout(maxWidth: math.max(1, width - 2 * padding));
      return painter.height;
    }

    final header = math.max(_photoSize,
        measure('Ag', _titleStyle) + measure('Ag', _metaStyle) * 2 + 4);
    var body = 0.0;
    for (final vendor in vendors) {
      if (vendor.description.trim().isEmpty) continue;
      body = math.max(body, measure(vendor.description.trim(), _bodyStyle));
    }
    painter.dispose();
    return (padding * 2 + 2 + header + (body > 0 ? 12 + body : 0) + 10)
        .ceilToDouble();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final hours = stallCardOpeningText(vendor);
        Widget placeholder() => const ColoredBox(
            color: AppColors.mint,
            child: Center(
                child:
                    Icon(Icons.storefront_rounded, color: AppColors.primary)));
        return Material(
          key: const ValueKey('stall-map-card-surface'),
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          elevation: 2,
          shadowColor: const Color(0x14000000),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                key: const ValueKey('stall-card-thumbnail'),
                                width: _photoSize,
                                height: _photoSize,
                                child: vendor.imageUrl.isEmpty
                                    ? placeholder()
                                    : Image.network(vendor.imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (_, child, progress) =>
                                            progress == null
                                                ? child
                                                : placeholder(),
                                        errorBuilder: (_, __, ___) =>
                                            placeholder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(vendor.stallName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _titleStyle),
                                  const SizedBox(height: 2),
                                  Text(vendor.categoryLabel,
                                      key:
                                          const ValueKey('stall-card-category'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _metaStyle),
                                  const SizedBox(height: 2),
                                  Text.rich(
                                      TextSpan(children: [
                                        TextSpan(
                                            text: vendor.isOpenNow
                                                ? 'Open'
                                                : 'Closed',
                                            style: TextStyle(
                                                color: vendor.isOpenNow
                                                    ? const Color(0xFF4A984D)
                                                    : const Color(0xFFD56C66))),
                                        if (hours.isNotEmpty)
                                          TextSpan(text: ' · $hours'),
                                      ]),
                                      key: const ValueKey('stall-card-status'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _metaStyle),
                                ])),
                          ]),
                      if (vendor.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(vendor.description.trim(),
                            key: const ValueKey('stall-card-description'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: _bodyStyle),
                      ],
                    ]),
              ),
            ),
          ),
        );
      });
}
