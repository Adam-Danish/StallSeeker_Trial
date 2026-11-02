This file is a merged representation of a subset of the codebase, containing specifically included files, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of a subset of the repository's contents that is considered the most important context.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: **/*.dart
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
````
lib/
  core/
    constants/
      app_colors.dart
      firestore_collections.dart
      stall_categories.dart
    models/
      demo_order.dart
      dish_follow_model.dart
      dish_search_entry.dart
      menu_item_model.dart
      notification_model.dart
      saved_location.dart
      stall_review.dart
      stall_schedule.dart
      user_model.dart
      vendor_model.dart
    services/
      auth_service.dart
      demo_order_service.dart
      dish_follow_service.dart
      dish_search_service.dart
      follow_service.dart
      local_demo_booking_service.dart
      menu_service.dart
      notification_history_service.dart
      notification_service.dart
      place_search_service.dart
      saved_location_service.dart
      saved_search_service.dart
      search_history_service.dart
      stall_review_service.dart
      storage_service.dart
      vendor_location_service.dart
      vendor_service.dart
    theme/
      app_theme.dart
    utils/
      vendor_phone.dart
    widgets/
      app_back_button.dart
      app_dropdown.dart
      app_page_app_bar.dart
      app_pill_navigation.dart
      app_sheet_header.dart
      app_top_action.dart
      ios_grouped.dart
  features/
    auth/
      screens/
        change_email_screen.dart
        email_verification_screen.dart
        forgot_password_screen.dart
        login_screen.dart
        register_screen.dart
        welcome_screen.dart
      auth_wrapper.dart
    customer/
      following/
        customer_following_screen.dart
        followed_dishes_list.dart
      home/
        customer_home_screen.dart
        discovery_map_widgets.dart
        discovery_options.dart
        discovery_search_filters.dart
        map_marker_focus.dart
        map_marker_guide.dart
        open_at_picker.dart
        price_range_picker.dart
        stall_map_marker.dart
        stall_preview_sheet.dart
      notifications/
        customer_notifications_screen.dart
      orders/
        demo_order_cart_screen.dart
      profile/
        customer_profile_screen.dart
      vendor_details/
        vendor_details_screen.dart
    shared/
      about_screen.dart
      account_ui.dart
      booking_detail_screen.dart
      booking_payment_card.dart
      change_password_screen.dart
      delete_account_screen.dart
      demo_orders_screen.dart
      edit_profile_screen.dart
      faq_screen.dart
      info_page.dart
      legal_screen.dart
      live_booking_section.dart
      logout_helper.dart
      manual_location_dialog.dart
      notification_settings_screen.dart
      personal_information_screen.dart
      pin_location_screen.dart
      profile_header.dart
      profile_page.dart
      saved_locations_sheet.dart
      stall_review_card.dart
    splash/
      splash_screen.dart
    vendor/
      dashboard/
        vendor_dashboard_screen.dart
        vendor_dashboard_view.dart
        vendor_demo_sales.dart
      menu/
        vendor_menu_screen.dart
      profile/
        edit_stall_screen.dart
        edit_stall_view.dart
        stall_profile_draft.dart
        stall_schedule_editor.dart
        unsaved_stall_changes_guard.dart
        vendor_profile_screen.dart
      reviews/
        vendor_reply_editor.dart
        vendor_review_filters.dart
        vendor_reviews_dashboard_card.dart
        vendor_reviews_screen.dart
      vendor_main_screen.dart
  firebase_options.dart
  main.dart
test/
  app_back_button_test.dart
  app_pill_navigation_test.dart
  booking_card_test.dart
  booking_cart_view_test.dart
  clear_discovery_filters_test.dart
  customer_discovery_search_test.dart
  demo_booking_service_test.dart
  demo_orders_screen_test.dart
  discovery_filters_test.dart
  discovery_map_widgets_test.dart
  discovery_options_test.dart
  edit_stall_view_test.dart
  map_marker_focus_test.dart
  map_marker_guide_test.dart
  payment_ui_test.dart
  profile_page_test.dart
  recent_changes_test.dart
  saved_location_test.dart
  saved_search_access_test.dart
  show_all_dishes_regression_test.dart
  unsaved_stall_changes_guard_test.dart
  vendor_dashboard_view_test.dart
  vendor_reviews_test.dart
````

# Files

## File: lib/features/customer/home/discovery_map_widgets.dart
````dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
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

/// The controller lives with the carousel so sheet/map rebuilds retain its page.
class StallCardCarousel extends StatefulWidget {
  const StallCardCarousel({
    super.key,
    required this.ids,
    required this.selectedId,
    required this.onSelected,
    required this.itemBuilder,
    this.viewportFraction = .94,
    this.padEnds = true,
    this.cardsPerPage = 1,
  });

  final List<String> ids;
  final String? selectedId;
  final ValueChanged<int> onSelected;
  final IndexedWidgetBuilder itemBuilder;
  final double viewportFraction;
  final bool padEnds;
  final int cardsPerPage;

  @override
  State<StallCardCarousel> createState() => _StallCardCarouselState();
}

class _StallCardCarouselState extends State<StallCardCarousel> {
  late PageController _controller;
  String? _programmaticId;

  @override
  void initState() {
    super.initState();
    final index = widget.ids.indexOf(widget.selectedId ?? '');
    _controller = PageController(
        viewportFraction: widget.viewportFraction,
        initialPage: index < 0 ? 0 : index ~/ widget.cardsPerPage);
  }

  @override
  void didUpdateWidget(covariant StallCardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedIndex = widget.ids.indexOf(widget.selectedId ?? '');
    final target =
        selectedIndex < 0 ? -1 : selectedIndex ~/ widget.cardsPerPage;
    if (oldWidget.viewportFraction != widget.viewportFraction ||
        oldWidget.cardsPerPage != widget.cardsPerPage) {
      final previous = _controller;
      _programmaticId = widget.selectedId;
      _controller = PageController(
          viewportFraction: widget.viewportFraction,
          initialPage: target < 0 ? 0 : target);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previous.dispose();
        if (!mounted) return;
        if (_controller.hasClients && widget.ids.isNotEmpty) {
          final currentIndex = widget.ids.indexOf(widget.selectedId ?? '');
          _controller.jumpToPage(
              currentIndex < 0 ? 0 : currentIndex ~/ widget.cardsPerPage);
        }
        _programmaticId = null;
      });
      return;
    }
    final reordered = oldWidget.ids.join('\u0000') != widget.ids.join('\u0000');
    if (target >= 0 &&
        (oldWidget.selectedId != widget.selectedId || reordered)) {
      _programmaticId = widget.selectedId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        final currentIndex = widget.ids.indexOf(widget.selectedId ?? '');
        if (currentIndex < 0) return;
        final currentTarget = currentIndex ~/ widget.cardsPerPage;
        // Jump on external selection: intermediate pages must not move the map.
        _controller.jumpToPage(currentTarget);
        _programmaticId = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
        key: const ValueKey('stall-card-carousel'),
        controller: _controller,
        padEnds: widget.padEnds,
        itemCount: (widget.ids.length / widget.cardsPerPage).ceil(),
        onPageChanged: (page) {
          final index = page * widget.cardsPerPage;
          final selectedIndex = widget.ids.indexOf(widget.selectedId ?? '');
          if (index < widget.ids.length &&
              _programmaticId == null &&
              (selectedIndex < 0 ||
                  selectedIndex ~/ widget.cardsPerPage != page)) {
            widget.onSelected(index);
          }
        },
        itemBuilder: (context, page) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: widget.cardsPerPage == 1
              ? _card(context, page)
              : Row(children: [
                  for (var column = 0; column < widget.cardsPerPage; column++)
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: page * widget.cardsPerPage + column <
                                    widget.ids.length
                                ? _card(context,
                                    page * widget.cardsPerPage + column)
                                : const SizedBox.shrink()))
                ]),
        ),
      );

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
````

## File: lib/features/customer/home/stall_map_marker.dart
````dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';

IconData stallCategoryIcon(String category) => switch (category) {
      'Beverages' => Icons.local_drink_rounded,
      'Burger' => Icons.lunch_dining_rounded,
      'Snacks & Desserts' => Icons.icecream_rounded,
      'Noodles' => Icons.ramen_dining_rounded,
      'Goreng Pisang' => Icons.bakery_dining_rounded,
      _ => Icons.restaurant_rounded,
    };

/// Bounded cache: two marker states per category, rather than one per stall.
class StallMapMarkerCache {
  final _icons = <(String, bool), Future<BitmapDescriptor>>{};

  Future<BitmapDescriptor> icon(String category, {required bool selected}) =>
      _icons.putIfAbsent((category, selected), () => _draw(category, selected));

  Future<BitmapDescriptor> _draw(String category, bool selected) async {
    const scale = 3.0;
    const size = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, 26, Paint()..color = const Color(0x22000000));
    canvas.drawCircle(center, 24, Paint()..color = AppColors.cardColor);
    if (selected) {
      canvas.drawCircle(
          center,
          24,
          Paint()
            ..color = AppColors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    canvas.drawCircle(center, 20,
        Paint()..color = selected ? AppColors.primary : AppColors.cardColor);
    final glyph = stallCategoryIcon(category);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: glyph.fontFamily,
          package: glyph.fontPackage,
          color: selected ? AppColors.cardColor : AppColors.primary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, center - Offset(painter.width / 2, painter.height / 2));
    painter.dispose();
    final picture = recorder.endRecording();
    final image =
        await picture.toImage((size * scale).round(), (size * scale).round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
        imagePixelRatio: scale);
  }
}
````

## File: lib/features/customer/home/stall_preview_sheet.dart
````dart
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
````

## File: test/discovery_map_widgets_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/discovery_map_widgets.dart';
import 'package:stallseeker/features/customer/home/discovery_options.dart';
import 'package:stallseeker/features/customer/home/stall_preview_sheet.dart';
import 'package:stallseeker/features/customer/home/stall_map_marker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';

void main() {
  testWidgets(
      'tablet shows multiple compact cards and retains selection on rotation',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ids = ['a', 'b', 'c', 'd', 'e', 'f'];
    final moves = <int>[];
    var selected = 'a';
    var columns = 3;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (_, setState) {
        update = setState;
        return SizedBox(
            height: 200,
            child: StallCardCarousel(
              ids: ids,
              selectedId: selected,
              cardsPerPage: columns,
              onSelected: (index) {
                moves.add(index);
                setState(() => selected = ids[index]);
              },
              itemBuilder: (_, index) =>
                  Center(child: Text('Card ${ids[index]}')),
            ));
      },
    ))));
    for (final id in ['a', 'b', 'c']) {
      final center = tester.getCenter(find.text('Card $id'));
      expect(center.dx, inInclusiveRange(0, 1280));
    }
    await tester.drag(find.byType(PageView), const Offset(-1100, 0));
    await tester.pumpAndSettle();
    expect(moves, [3]);
    expect(selected, 'd');
    update(() => selected = 'c');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(834, 1194);
    update(() => columns = 2);
    await tester.pumpAndSettle();
    expect(moves, [3]);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 1);
    expect(tester.takeException(), isNull);
  });

  test('landscape tablets retain a full header and centered carousel', () {
    for (final size in [
      const Size(1194, 834),
      const Size(1280, 600),
      const Size(834, 1194)
    ]) {
      final geometry = DiscoveryMapGeometry(size);
      expect(geometry.overlayWidth, size.width - 24);
      expect(geometry.cardWidth, lessThanOrEqualTo(420));
      expect(geometry.multipleCards, isTrue);
      expect(geometry.panelLeft + geometry.panelWidth / 2,
          closeTo(size.width / 2, .01));
    }
  });

  test('card closing time supports an overnight schedule', () {
    final vendor = _vendor().copyWith(weeklyHours: {
      1: [const StallHoursInterval(22 * 60, 2 * 60)]
    });
    expect(
        stallCardOpeningText(vendor, now: malaysiaInstant(2026, 11, 3, 1, 0)),
        'Closes 2 AM');
  });

  test('closed card shows the next scheduled opening day', () {
    final vendor = _vendor().copyWith(isOpen: false, weeklyHours: {
      6: [const StallHoursInterval(10 * 60, 18 * 60)]
    });
    expect(
        stallCardOpeningText(vendor, now: malaysiaInstant(2026, 11, 2, 11, 0)),
        'Opens Saturday');
  });

  test('temporary closure is included when finding the next opening', () {
    final vendor = _vendor().copyWith(
      weeklyHours: {
        1: [const StallHoursInterval(10 * 60, 18 * 60)]
      },
      temporaryClosures: [
        TemporaryClosure(malaysiaInstant(2026, 11, 2, 11, 0),
            malaysiaInstant(2026, 11, 2, 12, 0))
      ],
    );
    expect(
        stallCardOpeningText(vendor, now: malaysiaInstant(2026, 11, 2, 11, 30)),
        'Opens 12 PM');
  });

  testWidgets(
      'category, filter and nested sort use identical dropdown surfaces',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DiscoveryMapFilters(
      category: null,
      openNow: true,
      sort: DiscoverySort.distance,
      availableOnly: false,
      selfCollectOnly: false,
      recentOnly: false,
      onCategory: (_) {},
      onOpenNow: (_) {},
      onSort: (_) {},
      onAvailable: (_) {},
      onSelfCollect: (_) {},
      onRecent: (_) {},
      onReset: () {},
      moreItems: const [],
    ))));
    Material surfaceFor(String text) => tester.widget<Material>(find
        .ancestor(
            of: find.text(text),
            matching: find
                .byWidgetPredicate((w) => w is Material && w.elevation == 8))
        .first);
    void checkSurface(Material surface) {
      expect(surface.color, Colors.white);
      expect(surface.surfaceTintColor, Colors.transparent);
      expect((surface.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(20));
    }

    await tester.tap(find.byTooltip('Filter stalls'));
    await tester.pumpAndSettle();
    checkSurface(surfaceFor('Open now'));
    await tester.tap(find.text('Sort results'));
    await tester.pumpAndSettle();
    checkSurface(surfaceFor(DiscoverySort.distance.label));
    expect(find.byType(Checkbox), findsNothing);
    await tester.tapAt(const Offset(700, 550));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose stall category'));
    await tester.pumpAndSettle();
    checkSurface(surfaceFor('Beverages'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet card matches the reference hierarchy and content height',
      (tester) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final geometry = DiscoveryMapGeometry(const Size(834, 1194));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => SizedBox(
        width: geometry.cardWidth,
        height: StallMapCard.preferredHeight(
                context, geometry.panelWidth, [_vendor()],
                viewportFraction: geometry.viewportFraction,
                cardsPerPage: geometry.cardsPerPage) -
            10,
        child: StallMapCard(vendor: _vendor(), onTap: () {}),
      ),
    ))));
    await tester.pumpAndSettle();
    final surface =
        tester.getRect(find.byKey(const ValueKey('stall-map-card-surface')));
    final description =
        tester.getRect(find.byKey(const ValueKey('stall-card-description')));
    final photo =
        tester.getRect(find.byKey(const ValueKey('stall-card-thumbnail')));
    final title = tester.getRect(find.text('Adam stalls'));
    final category =
        tester.getRect(find.byKey(const ValueKey('stall-card-category')));
    final status =
        tester.getRect(find.byKey(const ValueKey('stall-card-status')));
    expect(surface.width, lessThan(500));
    expect(photo.size, const Size(64, 64));
    expect(tester.widget<Text>(find.text('Adam stalls')).style!.fontSize, 16);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('stall-card-description')))
            .style!
            .fontSize,
        14);
    expect(surface.bottom - description.bottom, inInclusiveRange(13, 15));
    expect(title.top, closeTo(photo.top, 1));
    expect(category.top, greaterThan(title.bottom));
    expect(status.top, greaterThan(category.bottom));
    expect(description.left, closeTo(photo.left, 1));
    expect(description.top, greaterThan(photo.bottom));
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('stall-card-description')))
            .maxLines,
        3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category remains a compact pill on a tablet', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DiscoveryMapFilters(
      category: null,
      openNow: false,
      sort: DiscoverySort.distance,
      availableOnly: false,
      selfCollectOnly: false,
      recentOnly: false,
      onCategory: (_) {},
      onOpenNow: (_) {},
      onSort: (_) {},
      onAvailable: (_) {},
      onSelfCollect: (_) {},
      onRecent: (_) {},
      onReset: () {},
      moreItems: const [],
    ))));
    expect(tester.getSize(find.byTooltip('Choose stall category')).width,
        lessThan(250));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'circular markers render distinct selected and normal PNGs and reuse the cache',
      (tester) async {
    final cache = StallMapMarkerCache();
    final normal = cache.icon('Beverages', selected: false);
    expect(identical(normal, cache.icon('Beverages', selected: false)), isTrue);
    final icons = await tester.runAsync(() => Future.wait([
          normal,
          cache.icon('Beverages', selected: true),
        ]));
    final light = icons![0] as BytesMapBitmap;
    final selected = icons[1] as BytesMapBitmap;
    expect(light.byteData.take(4), [137, 80, 78, 71]);
    expect(light.byteData, isNot(equals(selected.byteData)));
    expect(light.imagePixelRatio, 3);
  });
  testWidgets(
      'swipe selects the next card; marker selection does not emit intermediate pages',
      (tester) async {
    final moves = <int>[];
    var selected = 'a';
    var ids = ['a', 'b', 'c'];
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, setState) {
        update = setState;
        return SizedBox(
            height: 200,
            child: StallCardCarousel(
              ids: ids,
              selectedId: selected,
              onSelected: (index) {
                moves.add(index);
                setState(() => selected = ids[index]);
              },
              itemBuilder: (_, index) => Center(child: Text(ids[index])),
            ));
      },
    ))));
    await tester.drag(find.byType(PageView), const Offset(-750, 0));
    await tester.pumpAndSettle();
    expect(moves, [1]);
    expect(selected, 'b');
    update(() => selected = 'c');
    await tester.pumpAndSettle();
    expect(moves, [1]);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 2);
    update(() {
      ids = ['c'];
    });
    await tester.pumpAndSettle();
    expect(moves, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter menu keeps multiple checked options active',
      (tester) async {
    var open = false;
    var sort = DiscoverySort.distance;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (_, setState) => DiscoveryMapFilters(
        category: null,
        openNow: open,
        sort: sort,
        availableOnly: false,
        selfCollectOnly: false,
        recentOnly: false,
        onCategory: (_) {},
        onOpenNow: (value) => setState(() => open = value),
        onSort: (value) => setState(() => sort = value),
        onAvailable: (_) {},
        onSelfCollect: (_) {},
        onRecent: (_) {},
        onReset: () {},
        moreItems: const [],
      ),
    ))));
    await tester.tap(find.byTooltip('Filter stalls'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open now'));
    await tester.pumpAndSettle();
    expect(open, isTrue);
    await tester.tap(find.text('Top rated'));
    await tester.pumpAndSettle();
    expect(sort, DiscoverySort.rating);
    expect(find.text('Open now'), findsOneWidget);
    expect(find.text('Top rated'), findsOneWidget);
  });

  testWidgets('reference card fits a small phone with enlarged text',
      (tester) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(
          body: SizedBox(
              height: 220,
              child: StallMapCard(
                vendor: _vendor(),
                onTap: () {},
              ))),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Adam stalls'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview collapses, expands and closes above navigation',
      (tester) async {
    final extents = <double>[];
    var closed = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
      height: 700,
      child: StallPreviewSheet(
        vendor: _vendor(),
        rating: const Text('★ 4.8'),
        distance: '229 m away',
        photos: const [],
        following: false,
        onFollow: () {},
        onDirections: () {},
        onViewMenu: () {},
        onSelfCollect: () {},
        onDetails: () {},
        onClose: () => closed = true,
        onExtentChanged: extents.add,
      ),
    ))));
    await tester.tap(find.byTooltip('Collapse preview'));
    await tester.pumpAndSettle();
    expect(extents.last, closeTo(.28, .005));
    await tester.tap(find.byTooltip('Expand preview'));
    await tester.pumpAndSettle();
    expect(extents.last, closeTo(.94, .005));
    await tester.tap(find.byTooltip('Close preview'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}

VendorModel _vendor() => VendorModel(
      vendorId: 'adam',
      stallName: 'Adam stalls',
      category: 'Beverages',
      description:
          'Fresh drinks and refreshments near German-Malaysian Institute.',
      openingHours: '10 AM – 8 PM',
      isOpen: true,
      selfCollectEnabled: true,
    );
````

## File: lib/core/constants/stall_categories.dart
````dart
const stallCategories = <String>[
  'Goreng Pisang',
  'Burger',
  'Beverages',
  'Snacks & Desserts',
  'Malay Food',
  'Chinese Food',
  'Indian Food',
  'Western',
  'Noodles',
];
````

## File: lib/core/models/dish_follow_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DishFollowModel {
  const DishFollowModel(
      {required this.id,
      required this.vendorId,
      required this.itemId,
      this.followedAt});

  final String id;
  final String vendorId;
  final String itemId;
  final DateTime? followedAt;

  factory DishFollowModel.fromMap(Map<String, dynamic> data, String id) {
    final time = data['followedAt'];
    return DishFollowModel(
      id: id,
      vendorId: data['vendorId'] is String ? data['vendorId'] as String : '',
      itemId: data['itemId'] is String ? data['itemId'] as String : '',
      followedAt: time is Timestamp ? time.toDate() : null,
    );
  }
}
````

## File: lib/core/models/saved_location.dart
````dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/place_search_service.dart';

class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.isHome,
  });

  final String id;
  final String name;
  final String address;
  final LatLng coordinates;
  final bool isHome;

  LocationSelection get selection =>
      LocationSelection(coordinates: coordinates, label: '$name · $address');

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'isHome': isHome,
      };

  static SavedLocation? fromMap(String id, Map<String, dynamic> map) {
    final latitude = map['latitude'];
    final longitude = map['longitude'];
    final name = map['name'];
    final address = map['address'];
    if (id.isEmpty ||
        id == '.' ||
        id == '..' ||
        id.contains('/') ||
        id.length > 128 ||
        latitude is! num ||
        longitude is! num ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        name is! String ||
        name.trim().isEmpty ||
        name.length > 60 ||
        address is! String ||
        address.trim().isEmpty ||
        address.length > 500 ||
        map['isHome'] is! bool ||
        (id == 'home') != map['isHome'] ||
        (map['isHome'] == true && name != 'Home')) {
      return null;
    }
    return SavedLocation(
        id: id,
        name: name,
        address: address,
        coordinates: LatLng(latitude.toDouble(), longitude.toDouble()),
        isHome: map['isHome'] as bool);
  }
}
````

## File: lib/core/services/dish_follow_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dish_follow_model.dart';
import '../models/menu_item_model.dart';

/// Each customer's subscriptions live beneath their own user document.
/// The same stall/dish pair always uses the same ID, so following it twice
/// cannot create duplicate alerts.
class DishFollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _subscriptions(String uid) =>
      _db.collection('users').doc(uid).collection('dishFollows');

  String _id(String vendorId, String itemId) {
    for (final value in [vendorId, itemId]) {
      if (value.isEmpty ||
          value.length > 128 ||
          value.contains('/') ||
          value.contains(':')) {
        throw ArgumentError('Invalid stall or dish.');
      }
    }
    return '$vendorId:$itemId';
  }

  void _requireOwner(String uid) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError('Sign in to follow dishes.');
    }
    if (!user.emailVerified) {
      throw StateError('Verify your email before following dishes.');
    }
  }

  Future<void> _requireCustomer(String uid) async {
    _requireOwner(uid);
    final profile = await _db
        .collection('users')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 10));
    _requireOwner(uid);
    if (profile.data()?['role'] != 'customer') {
      throw StateError('Only customers can follow dishes.');
    }
  }

  Future<void> follow(String uid, String vendorId, String itemId) async {
    final id = _id(vendorId, itemId);
    await _requireCustomer(uid);
    final ref = _subscriptions(uid).doc(id);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      // Preserve the original follow time when a tap is repeated or a second
      // device follows the same dish while this device has stale state.
      if (!existing.exists) {
        transaction.set(ref, {
          'customerId': uid,
          'vendorId': vendorId,
          'itemId': itemId,
          'followedAt': FieldValue.serverTimestamp()
        });
      }
    }).timeout(const Duration(seconds: 10));
  }

  Future<void> unfollow(String uid, String vendorId, String itemId) async {
    await _requireCustomer(uid);
    await _subscriptions(uid)
        .doc(_id(vendorId, itemId))
        .delete()
        .timeout(const Duration(seconds: 10));
  }

  Stream<List<DishFollowModel>> watch(String uid, {String? vendorId}) {
    _requireOwner(uid);
    Query<Map<String, dynamic>> query = _subscriptions(uid);
    if (vendorId != null) query = query.where('vendorId', isEqualTo: vendorId);
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => DishFollowModel.fromMap(doc.data(), doc.id))
        .where((item) => item.vendorId.isNotEmpty && item.itemId.isNotEmpty)
        .toList());
  }

  Stream<MenuItemModel?> watchDish(String vendorId, String itemId) => _db
      .collection('vendors')
      .doc(vendorId)
      .collection('menu')
      .doc(itemId)
      .snapshots()
      .map((doc) =>
          doc.exists ? MenuItemModel.fromMap(doc.data()!, doc.id) : null);
}
````

## File: lib/core/services/follow_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _followsRef => _firestore.collection('follows');

  // Combining customerId + vendorId into one predictable document ID
  // means a customer can never accidentally follow the same vendor
  // twice -- the second "follow" would just overwrite the same document.
  String _followId(String customerId, String vendorId) =>
      '${customerId}_$vendorId';

  Future<void> followVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).set({
      'customerId': customerId,
      'vendorId': vendorId,
      'followedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).delete();
  }

  // Live stream of whether this customer currently follows this vendor.
  // Used to show the correct Follow/Unfollow button state, and keeps it
  // in sync automatically if changed from another device.
  Stream<bool> isFollowing(String customerId, String vendorId) {
    return _followsRef
        .doc(_followId(customerId, vendorId))
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Live stream of vendor IDs this customer follows -- used by the
  // Following tab to build its list.
  Stream<List<String>> getFollowedVendorIds(String customerId) {
    return _followsRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['vendorId'] as String).toList());
  }
}
````

## File: lib/core/services/saved_location_service.dart
````dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_location.dart';

class SavedLocationService {
  SavedLocationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  static const _guestKey = 'guest_saved_locations_v1';
  bool get _isGuest =>
      _auth.currentUser == null || _auth.currentUser!.isAnonymous;

  CollectionReference<Map<String, dynamic>> get _locations => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('savedLocations');

  Future<List<SavedLocation>> load() async {
    final List<SavedLocation> locations;
    if (_isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final byId = <String, SavedLocation>{};
      for (final value in prefs.getStringList(_guestKey) ?? <String>[]) {
        try {
          final map = jsonDecode(value) as Map<String, dynamic>;
          final location = SavedLocation.fromMap(map['id'] as String, map);
          if (location != null) byId[location.id] = location;
        } catch (_) {
          // Ignore an invalid legacy pin without hiding other saved places.
        }
      }
      locations = byId.values.toList();
    } else {
      final snapshot =
          await _locations.get().timeout(const Duration(seconds: 12));
      locations = snapshot.docs
          .map((doc) => SavedLocation.fromMap(doc.id, doc.data()))
          .whereType<SavedLocation>()
          .toList();
    }
    locations.sort((a, b) => a.isHome != b.isHome
        ? (a.isHome ? -1 : 1)
        : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return locations;
  }

  Future<void> save(
      {required String name,
      required String address,
      required LatLng coordinates,
      required bool isHome,
      String? id}) async {
    final locationId = isHome ? 'home' : id ?? _db.collection('_ids').doc().id;
    final location = SavedLocation.fromMap(locationId, {
      'name': isHome ? 'Home' : name.trim(),
      'address': address.trim(),
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'isHome': isHome,
    });
    if (location == null) {
      throw ArgumentError('Enter a valid name and map pin.');
    }
    if (_isGuest) {
      final saved = await load();
      saved.removeWhere((pin) => pin.id == location.id);
      saved.add(location);
      await _writeGuest(saved);
    } else {
      await _locations.doc(location.id).set({
        ...location.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 12));
    }
  }

  Future<void> delete(String id) async {
    if (_isGuest) {
      final saved = await load();
      saved.removeWhere((pin) => pin.id == id);
      await _writeGuest(saved);
    } else {
      await _locations.doc(id).delete().timeout(const Duration(seconds: 12));
    }
  }

  Future<void> _writeGuest(List<SavedLocation> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
        _guestKey,
        locations
            .map((location) =>
                jsonEncode({'id': location.id, ...location.toMap()}))
            .toList());
    if (!saved) throw StateError('Could not save the pin on this device.');
  }
}
````

## File: lib/core/services/saved_search_service.dart
````dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedDiscoverySearch {
  const SavedDiscoverySearch(
      {required this.id, required this.name, required this.filters});
  final String id;
  final String name;
  final Map<String, dynamic> filters;
}

/// Saved combinations belong to a signed-in customer; guests have no local fallback.
class SavedSearchService {
  SavedSearchService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String _customerId() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) {
      throw StateError(
          'Sign in with a verified customer account to save searches.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('savedSearches');

  Future<List<SavedDiscoverySearch>> load() async {
    final uid = _customerId();
    final snapshot =
        await _collection(uid).orderBy('savedAt', descending: true).get();
    if (_auth.currentUser?.uid != uid) throw StateError('Account changed.');
    return snapshot.docs
        .map((doc) => SavedDiscoverySearch(
            id: doc.id,
            name: doc.data()['name'] as String,
            filters: Map<String, dynamic>.from(doc.data()['filters'] as Map)))
        .toList();
  }

  Future<void> save(String name, Map<String, dynamic> filters) async {
    final uid = _customerId();
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 80) {
      throw ArgumentError('Invalid search name.');
    }
    // Same combination updates its existing record rather than creating duplicates.
    final encoded =
        base64Url.encode(utf8.encode(jsonEncode(filters))).replaceAll('=', '');
    if (encoded.length > 1400) throw ArgumentError('Saved search is too long.');
    await _collection(uid).doc(encoded).set({
      'name': cleaned,
      'filters': filters,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String id) => _collection(_customerId()).doc(id).delete();
}
````

## File: lib/core/utils/vendor_phone.dart
````dart
/// Normalizes Malaysian vendor contact numbers for display and tap-to-call.
/// This checks format only; it does not verify ownership of the number.
String? normalizeVendorPhone(String input) {
  var value = input.replaceAll(RegExp(r'[\s()\-]'), '');
  if (value.startsWith('+60')) {
    value = value.substring(3);
  } else if (value.startsWith('60')) {
    value = value.substring(2);
  } else if (value.startsWith('0')) {
    value = value.substring(1);
  } else {
    return null;
  }
  final mobile = RegExp(r'^1[0-9]{8,9}$');
  final landline = RegExp(r'^[2-9][0-9]{7,8}$');
  return mobile.hasMatch(value) || landline.hasMatch(value)
      ? '+60$value'
      : null;
}
````

## File: lib/core/widgets/app_back_button.dart
````dart
import 'package:flutter/material.dart';

import 'app_top_action.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton(
      {super.key, this.label = 'Back', this.onPressed, this.enabled = true});

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  static double leadingWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(
          text: label,
          style:
              DefaultTextStyle.of(context).style.merge(AppTopAction.textStyle)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width + 56; // Pill padding and toolbar insets.
    painter.dispose();
    return width < 96 ? 96 : width;
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: AppTopAction(
          label: label,
          onTap:
              !enabled ? null : onPressed ?? () => Navigator.maybePop(context),
        ),
      );
}
````

## File: lib/core/widgets/app_page_app_bar.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_back_button.dart';

/// Route-aware page headers consistently use the Edit Profile pill style.
class AppPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageAppBar(
      {super.key,
      this.title,
      this.actions,
      this.bottom,
      this.centerTitle,
      this.backgroundColor,
      this.foregroundColor,
      this.surfaceTintColor,
      this.elevation,
      this.scrolledUnderElevation,
      this.systemOverlayStyle,
      this.titleTextStyle,
      this.onBack,
      this.backEnabled = true,
      this.backLabel = 'Back',
      this.showBackButton,
      this.toolbarHeight = 64});

  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final TextStyle? titleTextStyle;
  final VoidCallback? onBack;
  final bool backEnabled;
  final String backLabel;
  final bool? showBackButton;
  final double toolbarHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final showBack = showBackButton ??
        (onBack != null ||
            (ModalRoute.of(context)?.impliesAppBarDismissal ?? false));
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth:
          showBack ? AppBackButton.leadingWidth(context, backLabel) : null,
      leading: showBack
          ? Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
              child: AppBackButton(
                  label: backLabel, onPressed: onBack, enabled: backEnabled),
            )
          : null,
      title: title,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      surfaceTintColor: surfaceTintColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      systemOverlayStyle: systemOverlayStyle,
      titleTextStyle: titleTextStyle,
      toolbarHeight: toolbarHeight,
    );
  }
}
````

## File: lib/core/widgets/app_sheet_header.dart
````dart
import 'package:flutter/material.dart';

import 'app_back_button.dart';

/// Sheet dismissal stays at the top left, above the sheet's content.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.onBack,
      this.backLabel = 'Close',
      this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12)});

  final Widget title;
  final Widget? subtitle;
  final VoidCallback? onBack;
  final String backLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppBackButton(label: backLabel, onPressed: onBack),
          const SizedBox(height: 12),
          DefaultTextStyle.merge(
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            child: title,
          ),
          if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
        ]),
      );
}
````

## File: lib/core/widgets/app_top_action.dart
````dart
import 'package:flutter/material.dart';

/// The white pill action used by Edit Profile and page navigation.
class AppTopAction extends StatelessWidget {
  const AppTopAction(
      {super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  static const textStyle = TextStyle(fontSize: 17, color: Colors.black);

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        label: icon == null ? null : label,
        child: Material(
          color: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x14000000),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: icon == null
                    ? Text(label,
                        textAlign: TextAlign.center,
                        style: textStyle.copyWith(
                            color:
                                onTap == null ? Colors.black38 : Colors.black))
                    : Icon(icon,
                        size: 22,
                        color: onTap == null ? Colors.black38 : Colors.black),
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/core/widgets/ios_grouped.dart
````dart
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 32,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .26),
          gradient: color == AppColors.primary
              ? AppColors.logoGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(Colors.white, color, .78)!,
                    color,
                  ],
                ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * .65,
        ),
      );
}

class AppGroupedCard extends StatelessWidget {
  const AppGroupedCard({
    super.key,
    required this.children,
    this.dividerIndent = 60,
  });

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: .5,
                  thickness: .5,
                  indent: dividerIndent,
                  endIndent: 16,
                  color: AppColors.border,
                ),
              children[i],
            ],
          ],
        ),
      );
}
````

## File: lib/features/customer/home/discovery_options.dart
````dart
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/dish_search_entry.dart';
import '../../../core/models/vendor_model.dart';

enum DiscoverySort {
  distance('Distance: nearest first'),
  price('Price: low to high'),
  rating('Rating: highest first'),
  newest('Newest first'),
  updated('Recently updated');

  const DiscoverySort(this.label);
  final String label;
}

class StallRatingSummary {
  const StallRatingSummary(this.average, this.count);
  final double average;
  final int count;
}

/// Canonical phrases cover common Malaysian names and abbreviations.
String normalizeDishSearch(String value) {
  var text = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  text = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  const phrases = {
    'banana fritters': 'pisang goreng',
    'goreng pisang': 'pisang goreng',
    'coconut rice': 'nasi lemak',
    'nasi lmk': 'nasi lemak',
    'pulled tea': 'teh tarik',
    'roti prata': 'roti canai',
    'char kway teow': 'char kuey teow',
    'char koay teow': 'char kuey teow',
    'kueh teow': 'kuey teow',
  };
  for (final entry in phrases.entries) {
    text = text.replaceAll(RegExp('\\b${entry.key}\\b'), entry.value);
  }
  const words = {
    'mi': 'mee',
    'noodle': 'mee',
    'noodles': 'mee',
    'grg': 'goreng',
    'burgers': 'burger',
    'hamburger': 'burger',
    'chkn': 'ayam',
    'chicken': 'ayam',
  };
  return text.split(' ').map((word) => words[word] ?? word).join(' ');
}

int _editDistance(String a, String b) {
  if (a.length == b.length) {
    final differences = <int>[];
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) differences.add(index);
    }
    if (differences.length == 2 &&
        differences.last == differences.first + 1 &&
        a[differences.first] == b[differences.last] &&
        a[differences.last] == b[differences.first]) {
      return 1;
    }
  }
  var previous = List.generate(b.length + 1, (index) => index);
  for (var row = 1; row <= a.length; row++) {
    final current = <int>[row];
    for (var column = 1; column <= b.length; column++) {
      current.add(math.min(math.min(current.last + 1, previous[column] + 1),
          previous[column - 1] + (a[row - 1] == b[column - 1] ? 0 : 1)));
    }
    previous = current;
  }
  return previous.last;
}

/// Null means no match. Smaller scores represent closer matches.
int? discoverySearchScore(String query, String value) {
  final needle = normalizeDishSearch(query);
  final text = normalizeDishSearch(value);
  if (needle.isEmpty || text.contains(needle)) return 0;
  final words = text.split(' ');
  var score = 0;
  for (final token in needle.split(' ')) {
    if (words.any((word) => word.startsWith(token))) continue;
    final tolerance = token.length >= 7
        ? 2
        : token.length >= 4
            ? 1
            : 0;
    if (tolerance == 0) return null;
    final matches = words.where((word) =>
        (word.length - token.length).abs() <= tolerance &&
        _editDistance(token, word) <= tolerance);
    if (matches.isEmpty) return null;
    score++;
  }
  return score;
}

bool discoveryMatches(String query, String value) =>
    discoverySearchScore(query, value) != null;

bool dishIsAvailable(DishSearchEntry dish) =>
    {'available', 'low_stock'}.contains(dish.item.status);

DateTime? latestStallUpdate(
    VendorModel vendor, Iterable<DishSearchEntry> dishes) {
  DateTime? latest = vendor.updatedAt;
  for (final dish in dishes) {
    for (final date in [dish.item.updatedAt, dish.item.statusUpdatedAt]) {
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
  }
  // GPS refreshes do not count as menu/profile updates.
  return latest;
}

bool stallUpdatedRecently(VendorModel vendor, Iterable<DishSearchEntry> dishes,
    {DateTime? now}) {
  final updated = latestStallUpdate(vendor, dishes);
  if (updated == null) return false;
  final age = (now ?? DateTime.now()).difference(updated);
  return !age.isNegative && age <= const Duration(hours: 24);
}

int _ascending(num? a, num? b) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int _newest(DateTime? a, DateTime? b) => _ascending(
    a == null ? null : -a.millisecondsSinceEpoch,
    b == null ? null : -b.millisecondsSinceEpoch);

double? lowestDishPrice(Iterable<DishSearchEntry> dishes, String query) {
  final all = dishes.toList();
  final matches = query.trim().isEmpty
      ? all
      : all.where((dish) => discoveryMatches(query, dish.item.name)).toList();
  final priced = (matches.isEmpty ? all : matches).where((dish) =>
      dish.priceIsKnown && dish.item.price.isFinite && dish.item.price >= 0);
  if (priced.isEmpty) return null;
  return priced.map((dish) => dish.item.price).reduce(math.min);
}

int compareDiscoveryVendors(
  VendorModel a,
  VendorModel b, {
  required DiscoverySort sort,
  required LatLng? center,
  required Map<String, StallRatingSummary> ratings,
  required Map<String, List<DishSearchEntry>> dishes,
  String query = '',
}) {
  double? distance(VendorModel vendor) => center == null
      ? null
      : Geolocator.distanceBetween(
          center.latitude, center.longitude, vendor.latitude, vendor.longitude);
  double? rating(VendorModel vendor) {
    final summary = ratings[vendor.vendorId];
    return summary == null || summary.count == 0 ? null : -summary.average;
  }

  final left = dishes[a.vendorId] ?? const <DishSearchEntry>[];
  final right = dishes[b.vendorId] ?? const <DishSearchEntry>[];
  final order = switch (sort) {
    DiscoverySort.distance => _ascending(distance(a), distance(b)),
    DiscoverySort.price =>
      _ascending(lowestDishPrice(left, query), lowestDishPrice(right, query)),
    DiscoverySort.rating => _ascending(rating(a), rating(b)),
    DiscoverySort.newest => _newest(a.createdAt, b.createdAt),
    DiscoverySort.updated =>
      _newest(latestStallUpdate(a, left), latestStallUpdate(b, right)),
  };
  if (order != 0) return order;
  final name = a.stallName.toLowerCase().compareTo(b.stallName.toLowerCase());
  return name != 0 ? name : a.vendorId.compareTo(b.vendorId);
}

int compareDiscoveryDishes(
  DishSearchEntry a,
  DishSearchEntry b, {
  required DiscoverySort sort,
  required Map<String, VendorModel> vendors,
  required LatLng? center,
  required Map<String, StallRatingSummary> ratings,
  required Map<String, List<DishSearchEntry>> dishes,
  String query = '',
}) {
  final order = switch (sort) {
    DiscoverySort.price => _ascending(a.priceIsKnown ? a.item.price : null,
        b.priceIsKnown ? b.item.price : null),
    DiscoverySort.newest => _newest(a.item.createdAt, b.item.createdAt),
    DiscoverySort.updated => _newest(a.item.updatedAt ?? a.item.statusUpdatedAt,
        b.item.updatedAt ?? b.item.statusUpdatedAt),
    _ => compareDiscoveryVendors(vendors[a.vendorId]!, vendors[b.vendorId]!,
        sort: sort,
        center: center,
        ratings: ratings,
        dishes: dishes,
        query: query),
  };
  if (order != 0) return order;
  final relevance = (discoverySearchScore(query, a.item.name) ?? 999)
      .compareTo(discoverySearchScore(query, b.item.name) ?? 999);
  if (relevance != 0) return relevance;
  final name = a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
  return name != 0
      ? name
      : '${a.vendorId}/${a.item.itemId}'
          .compareTo('${b.vendorId}/${b.item.itemId}');
}
````

## File: lib/features/customer/home/map_marker_focus.dart
````dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/vendor_model.dart';

/// Finds a visible stall close to the center of the map after a user pan.
/// The threshold scales with zoom because it is a fraction of the viewport.
VendorModel? stallNearMapCenter({
  required LatLng center,
  required LatLngBounds bounds,
  required Iterable<VendorModel> vendors,
  double focusFraction = .15,
}) {
  final latitudeSpan = bounds.northeast.latitude - bounds.southwest.latitude;
  final longitudeSpan = bounds.northeast.longitude - bounds.southwest.longitude;
  if (latitudeSpan <= 0 || longitudeSpan <= 0 || focusFraction <= 0) {
    return null;
  }

  VendorModel? nearest;
  var nearestScore = 1.0;
  for (final vendor in vendors) {
    if (!vendor.hasValidLocation) continue;
    final latitudeOffset =
        (vendor.latitude - center.latitude) / (latitudeSpan * focusFraction);
    final longitudeOffset =
        (vendor.longitude - center.longitude) / (longitudeSpan * focusFraction);
    final score =
        latitudeOffset * latitudeOffset + longitudeOffset * longitudeOffset;
    if (score <= nearestScore) {
      nearest = vendor;
      nearestScore = score;
    }
  }
  return nearest;
}
````

## File: lib/features/customer/home/map_marker_guide.dart
````dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Matches the search pin and selected/unselected stall pins on the home map.
class MapMarkerGuide extends StatelessWidget {
  const MapMarkerGuide({super.key});

  static const _entries = [
    ('Search location', Color(0xFF0080FF)),
    ('Other stalls', Color(0xFFFF0000)),
    ('Selected stall', Color(0xFFFF8000)),
  ];
  static const _style = TextStyle(fontSize: 11, color: AppColors.textMuted);

  // The map results panel reserves its own height. Measure the same labels so
  // the guide can wrap without taking space away from the stall cards.
  static double heightFor(BuildContext context, double panelWidth) {
    final available = math.max(1.0, panelWidth - 32);
    var runWidth = 0.0;
    var runs = 1;
    var lineHeight = 18.0;
    for (final entry in _entries) {
      final painter = TextPainter(
          text: TextSpan(
              text: entry.$1,
              style: DefaultTextStyle.of(context).style.merge(_style)),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context))
        ..layout(maxWidth: math.max(1.0, available - 24));
      final itemWidth = painter.width + 22;
      lineHeight = math.max(lineHeight, painter.height);
      if (runWidth > 0 && runWidth + 12 + itemWidth > available) {
        runs++;
        runWidth = itemWidth;
      } else {
        runWidth += (runWidth == 0 ? 0 : 12) + itemWidth;
      }
      painter.dispose();
    }
    return (lineHeight * runs + (runs - 1) * 6 + 16).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final entry in _entries)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on, size: 18, color: entry.$2),
                      const SizedBox(width: 4),
                      Flexible(child: Text(entry.$1, style: _style)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      );
}
````

## File: lib/features/shared/stall_review_card.dart
````dart
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
````

## File: lib/features/vendor/profile/edit_stall_view.dart
````dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/utils/vendor_phone.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../../../core/widgets/app_sheet_header.dart';
import 'stall_schedule_editor.dart';

class EditStallView extends StatefulWidget {
  const EditStallView(
      {super.key,
      required this.formKey,
      required this.nameController,
      required this.descriptionController,
      required this.phoneController,
      required this.image,
      required this.categoryOptions,
      required this.selectedCategories,
      required this.hours,
      required this.closures,
      required this.onCategoryChanged,
      required this.onScheduleChanged,
      required this.onFormChanged,
      required this.onCancel,
      required this.onSave,
      required this.onPreview,
      this.legacyHours = '',
      this.loading = false,
      this.saving = false,
      this.pickingImage = false,
      this.newPhoto = false,
      this.error,
      this.onRetry});
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController phoneController;
  final Widget image;
  final List<String> categoryOptions;
  final Set<String> selectedCategories;
  final Map<int, List<StallHoursInterval>> hours;
  final List<TemporaryClosure> closures;
  final void Function(String, bool) onCategoryChanged;
  final void Function(
          Map<int, List<StallHoursInterval>>, List<TemporaryClosure>)
      onScheduleChanged;
  final VoidCallback onFormChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onPreview;
  final String legacyHours;
  final bool loading;
  final bool saving;
  final bool pickingImage;
  final bool newPhoto;
  final String? error;
  final VoidCallback? onRetry;
  @override
  State<EditStallView> createState() => _EditStallViewState();
}

class _EditStallViewState extends State<EditStallView> {
  bool _hoursExpanded = false;
  bool _closuresExpanded = false;
  bool get _busy =>
      widget.loading ||
      widget.saving ||
      widget.pickingImage ||
      widget.error != null;
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  String _hoursForDay(int day) {
    final intervals = widget.hours[day] ?? [];
    return intervals.isEmpty
        ? 'Closed'
        : intervals
            .map((interval) =>
                '${formatStallTime(interval.openMinute)} – ${formatStallTime(interval.closeMinute)}${interval.closeMinute < interval.openMinute ? ' (next day)' : ''}')
            .join('\n');
  }

  String get _hoursSummary => widget.hours.isEmpty
      ? 'Set your weekly schedule'
      : 'Today: ${_hoursForDay(malaysiaTime(DateTime.now()).weekday)}';
  String get _closureSummary {
    final active = widget.closures
        .where((closure) => closure.end.isAfter(DateTime.now()))
        .length;
    if (active == 0) return 'No upcoming closures';
    return '$active ${active == 1 ? 'closure' : 'closures'} scheduled';
  }

  TextStyle? _heading(BuildContext context) => Theme.of(context)
      .textTheme
      .titleLarge
      ?.copyWith(fontWeight: FontWeight.w700);
  Widget _card(Widget child, {Key? key}) => Container(
      key: key,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border.withValues(alpha: .65))),
      child: child);
  InputDecoration _field(String label, String hint) => InputDecoration(
      labelText: label,
      hintText: hint,
      fillColor: AppColors.background.withValues(alpha: .65),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.border)));

  void _chooseCategories() {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 680),
        builder: (sheet) => StatefulBuilder(
            builder: (context, refresh) => SizedBox(
                height: MediaQuery.sizeOf(context).height * .65,
                child: Column(children: [
                  const AppSheetHeader(
                      title: Text('Food categories'),
                      subtitle: Text(
                          'Choose one or more categories for your stall.')),
                  Expanded(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                          child: Align(
                              alignment: Alignment.topLeft,
                              child: Wrap(spacing: 8, runSpacing: 8, children: [
                                for (final category in {
                                  ...widget.categoryOptions,
                                  ...widget.selectedCategories
                                })
                                  FilterChip(
                                      label: Text(category),
                                      selected: widget.selectedCategories
                                          .contains(category),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.padded,
                                      onSelected: (selected) {
                                        widget.onCategoryChanged(
                                            category, selected);
                                        refresh(() {});
                                      }),
                              ])))),
                ]))));
  }

  Widget _details(BuildContext context) => _card(
      key: const Key('edit-stall-details'),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Stall details', style: _heading(context)),
        const SizedBox(height: 16),
        widget.image,
        const SizedBox(height: 10),
        Text(
            widget.newPhoto
                ? 'New photo selected. Save changes to publish it.'
                : 'This photo appears on your public stall profile.',
            style: TextStyle(
                color:
                    widget.newPhoto ? AppColors.primary : AppColors.textMuted,
                fontSize: 13)),
        const SizedBox(height: 20),
        TextFormField(
            controller: widget.nameController,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _field('Stall name', 'e.g. Uncle John Drink Stall'),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter your stall name.' : null),
        const SizedBox(height: 20),
        Text('Food categories', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (widget.selectedCategories.isNotEmpty)
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final category in widget.selectedCategories)
              Chip(label: Text(category), backgroundColor: AppColors.mint)
          ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: _busy ? null : _chooseCategories,
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.category_outlined, size: 20),
            label: const Text('Choose categories')),
        const SizedBox(height: 20),
        TextFormField(
            controller: widget.descriptionController,
            enabled: !_busy,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: _field(
                'Description', 'Tell customers about your food and drinks.'),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter a description.' : null),
        const SizedBox(height: 20),
        TextFormField(
            controller: widget.phoneController,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: _field('Business phone number', 'e.g. 012-345 6789'),
            validator: (value) => normalizeVendorPhone(value ?? '') == null
                ? 'Enter a valid Malaysian phone number.'
                : null),
      ]));

  Widget _hoursEditor() => StallScheduleEditor(
      hours: widget.hours,
      closures: widget.closures,
      onChanged: widget.onScheduleChanged,
      showClosures: false,
      showSectionTitles: false);
  Widget _closuresEditor() => StallScheduleEditor(
      hours: widget.hours,
      closures: widget.closures,
      onChanged: widget.onScheduleChanged,
      showHours: false,
      showSectionTitles: false);

  void _editHours() {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 680),
        builder: (sheet) => StatefulBuilder(
            builder: (context, refresh) => SizedBox(
                height: MediaQuery.sizeOf(context).height * .88,
                child: Column(children: [
                  const AppSheetHeader(
                      title: Text('Weekly opening hours'),
                      backLabel: 'Back',
                      subtitle: Text(
                          'Your hours are published when you save your stall.')),
                  Expanded(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                          child: StallScheduleEditor(
                              hours: widget.hours,
                              closures: widget.closures,
                              showClosures: false,
                              showSectionTitles: false,
                              onChanged: (hours, closures) {
                                widget.onScheduleChanged(hours, closures);
                                refresh(() {});
                              }))),
                ]))));
  }

  Widget _hours(BuildContext context, bool wide) {
    final legacy = widget.hours.isEmpty && widget.legacyHours.trim().isNotEmpty;
    if (!wide) {
      return _card(
          key: const Key('edit-stall-hours'),
          Padding(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                  key: const PageStorageKey('edit-stall-hours-expansion'),
                  initiallyExpanded: _hoursExpanded,
                  maintainState: true,
                  onExpansionChanged: (expanded) =>
                      setState(() => _hoursExpanded = expanded),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 12),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: const Icon(Icons.schedule_outlined,
                      color: AppColors.primary),
                  title: const Text('Opening hours',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(_hoursSummary),
                  children: [
                    if (legacy)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('Previous hours: ${widget.legacyHours}')),
                    _hoursEditor(),
                  ])));
    }
    return _card(
        key: const Key('edit-stall-hours'),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Opening hours', style: _heading(context)),
          const SizedBox(height: 6),
          const Text('Planned hours · Malaysia time',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          if (legacy) ...[
            Text('Previous hours: ${widget.legacyHours}'),
            const SizedBox(height: 8)
          ],
          if (widget.hours.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Set your weekly schedule.'))
          else
            for (var day = 1; day <= 7; day++)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 94, child: Text(_days[day - 1])),
                        Expanded(
                            child: Text(_hoursForDay(day),
                                style: const TextStyle(
                                    color: AppColors.textMuted)))
                      ])),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: _busy ? null : _editHours,
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.edit_calendar_outlined, size: 20),
              label: const Text('Edit weekly hours')),
          const SizedBox(height: 14),
          const Text(
              'Manage your live Open / Closed status from the dashboard.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]));
  }

  Widget _closures(BuildContext context, bool wide) {
    if (!wide) {
      return _card(
          key: const Key('edit-stall-closures'),
          ExpansionTile(
              key: const PageStorageKey('edit-stall-closures-expansion'),
              initiallyExpanded: _closuresExpanded,
              maintainState: true,
              onExpansionChanged: (expanded) =>
                  setState(() => _closuresExpanded = expanded),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 12),
              shape: const Border(),
              collapsedShape: const Border(),
              leading: const Icon(Icons.event_busy_outlined,
                  color: AppColors.primary),
              title: const Text('Temporary closures',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_closureSummary),
              children: [_closuresEditor()]));
    }
    return _card(
        key: const Key('edit-stall-closures'),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Temporary closures', style: _heading(context)),
          const SizedBox(height: 16),
          _closuresEditor(),
        ]));
  }

  Widget _saveFooter(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border))),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final button = FilledButton(
                          key: const Key('edit-stall-save'),
                          onPressed: _busy ? null : widget.onSave,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 52),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14)),
                          child:
                              Text(widget.saving ? 'Saving…' : 'Save changes'));
                      if (constraints.maxWidth >= 700 &&
                          MediaQuery.textScalerOf(context).scale(14) < 20) {
                        return Row(children: [
                          const Expanded(
                              child: Text(
                                  'Changes appear on your public stall profile.',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13))),
                          const SizedBox(width: 24),
                          SizedBox(width: 240, child: button)
                        ]);
                      }
                      return SizedBox(width: double.infinity, child: button);
                    })))),
      );

  @override
  Widget build(BuildContext context) {
    final compactHeader = MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(14) > 19;
    final preview = compactHeader
        ? IconButton.outlined(
            tooltip: 'Customer preview',
            onPressed: _busy ? null : widget.onPreview,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon:
                const Icon(Icons.visibility_outlined, color: AppColors.primary))
        : OutlinedButton.icon(
            onPressed: _busy ? null : widget.onPreview,
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.visibility_outlined, size: 19),
            label: const Text('Preview'));
    return Scaffold(
      appBar: AppPageAppBar(
          showBackButton: true,
          backLabel: 'Cancel',
          onBack: widget.onCancel,
          backEnabled: !widget.saving && !widget.pickingImage,
          title: const Text('Edit stall'),
          actions: [
            Padding(padding: const EdgeInsets.only(right: 16), child: preview)
          ]),
      body: SafeArea(
          top: false,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: widget.loading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.error != null
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(widget.error!,
                                        textAlign: TextAlign.center),
                                    if (widget.onRetry != null)
                                      TextButton(
                                          onPressed: widget.onRetry,
                                          child: const Text('Retry'))
                                  ])))
                      : Form(
                          key: widget.formKey,
                          onChanged: widget.onFormChanged,
                          child: SingleChildScrollView(
                              key: const PageStorageKey('edit-stall-scroll'),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              child: Center(
                                  child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 1280),
                                      child: LayoutBuilder(
                                          builder: (context, constraints) {
                                        final scale =
                                            MediaQuery.textScalerOf(context)
                                                    .scale(14) /
                                                14;
                                        final wide = constraints.maxWidth >=
                                            860 + (scale - 1).clamp(0, 2) * 240;
                                        final schedule = IgnorePointer(
                                            ignoring: _busy,
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  _hours(context, wide),
                                                  const SizedBox(height: 16),
                                                  _closures(context, wide)
                                                ]));
                                        if (wide) {
                                          return Row(
                                              key: const Key(
                                                  'edit-stall-two-columns'),
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                    flex: 6,
                                                    child: _details(context)),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                    flex: 4, child: schedule)
                                              ]);
                                        }
                                        return Column(
                                            key: const Key(
                                                'edit-stall-single-column'),
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _details(context),
                                              const SizedBox(height: 16),
                                              schedule
                                            ]);
                                      }))))),
            ),
            _saveFooter(context),
          ])),
    );
  }
}
````

## File: lib/features/vendor/profile/stall_profile_draft.dart
````dart
import '../../../core/models/vendor_model.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/utils/vendor_phone.dart';

/// A detached profile snapshot; operational state comes from the loaded stall.
VendorModel buildStallProfileDraft({
  required VendorModel original,
  required String name,
  required String description,
  required String phone,
  required String legacyHours,
  required Iterable<String> categories,
  required Map<int, List<StallHoursInterval>> hours,
  required List<TemporaryClosure> closures,
  String? imageUrl,
}) {
  final selected = categories.toList();
  return original.copyWith(
    stallName: name.trim(),
    description: description.trim(),
    phoneNumber: normalizeVendorPhone(phone) ?? phone.trim(),
    category: selected.isEmpty ? '' : selected.first,
    categories: selected,
    openingHours: legacyHours.trim(),
    imageUrl: imageUrl,
    weeklyHours: {
      for (final entry in hours.entries) entry.key: [...entry.value]
    },
    temporaryClosures: [...closures],
  );
}
````

## File: lib/features/vendor/profile/unsaved_stall_changes_guard.dart
````dart
import 'package:flutter/material.dart';

class UnsavedStallChangesGuard extends StatefulWidget {
  const UnsavedStallChangesGuard(
      {super.key,
      required this.hasChanges,
      required this.saving,
      required this.onSave,
      required this.child});
  final bool hasChanges;
  final bool saving;
  final Future<void> Function() onSave;
  final Widget child;

  @override
  State<UnsavedStallChangesGuard> createState() =>
      UnsavedStallChangesGuardState();
}

class UnsavedStallChangesGuardState extends State<UnsavedStallChangesGuard> {
  bool _allowPop = false;
  bool _dialogOpen = false;

  void close() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> requestLeave() async {
    if (widget.saving || _dialogOpen) return;
    if (!widget.hasChanges) {
      close();
      return;
    }
    _dialogOpen = true;
    final choice = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Save your changes?'),
                content:
                    const Text('Your stall changes have not been saved yet.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, 'keep'),
                      child: const Text('Keep editing')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, 'discard'),
                      child: const Text('Discard changes')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, 'save'),
                      child: const Text('Save changes')),
                ]));
    _dialogOpen = false;
    if (!mounted) return;
    if (choice == 'save') {
      await widget.onSave();
    } else if (choice == 'discard') {
      close();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _allowPop || (!widget.saving && !widget.hasChanges),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !widget.saving) requestLeave();
        },
        child: widget.child,
      );
}
````

## File: lib/features/vendor/reviews/vendor_reply_editor.dart
````dart
import 'package:flutter/material.dart';
import '../../../core/models/stall_review.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../../shared/stall_review_card.dart';

class VendorReplyEditor extends StatefulWidget {
  const VendorReplyEditor({
    super.key,
    required this.review,
    required this.stallName,
    required this.onSave,
  });
  final StallReview review;
  final String stallName;
  final Future<void> Function(String text) onSave;
  @override
  State<VendorReplyEditor> createState() => _VendorReplyEditorState();
}

class _VendorReplyEditorState extends State<VendorReplyEditor> {
  late final TextEditingController _text;
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  bool _allowPop = false;
  String? _error;
  String get _original => widget.review.vendorReply?.text ?? '';
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: _original);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving) return;
    if (_text.text != _original) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard this draft?'),
          content: const Text('Your reply has not been saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep writing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_text.text.trim());
      if (!mounted) return;
      setState(() {
        _allowPop = true;
        _saving = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Could not save your reply. Your draft is still here. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          appBar: AppPageAppBar(
            showBackButton: true,
            backLabel: 'Cancel',
            onBack: _leave,
            backEnabled: !_saving,
            title: Text(widget.review.hasReply ? 'Edit reply' : 'Reply'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Customer review',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      StallReviewCard(
                        review: widget.review,
                        stallName: widget.stallName,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your official reply',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your reply will be visible to everyone under this review.',
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _form,
                        child: TextFormField(
                          controller: _text,
                          enabled: !_saving,
                          minLines: 5,
                          maxLines: 12,
                          maxLength: 1000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Reply',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Write a reply before posting.'
                              : value!.trim().length > 1000
                                  ? 'Use 1,000 characters or fewer.'
                                  : null,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving
                              ? 'Saving…'
                              : _error != null
                                  ? 'Retry'
                                  : widget.review.hasReply
                                      ? 'Save changes'
                                      : 'Post reply',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/vendor/reviews/vendor_review_filters.dart
````dart
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
````

## File: lib/features/vendor/reviews/vendor_reviews_dashboard_card.dart
````dart
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
````

## File: lib/features/vendor/reviews/vendor_reviews_screen.dart
````dart
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
````

## File: test/app_back_button_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_back_button.dart';
import 'package:stallseeker/core/widgets/app_page_app_bar.dart';
import 'package:stallseeker/core/widgets/app_sheet_header.dart';
import 'package:stallseeker/features/shared/info_page.dart';
import 'package:stallseeker/features/vendor/profile/unsaved_stall_changes_guard.dart';

Widget app(Widget Function(BuildContext) page, {double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Builder(
          builder: (context) => Scaffold(
              appBar: const AppPageAppBar(title: Text('Home')),
              body: TextButton(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: page)),
                  child: const Text('Open page')))),
    );

void main() {
  for (final width in [320.0, 390.0, 960.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets('back navigation fits $width px with $scale text',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(
            (_) => Scaffold(
                appBar: AppPageAppBar(
                    title: const Text('Stall details'),
                    actions: [
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_outline))
                    ]),
                body: const Text('Page content')),
            scale: scale));
        expect(find.byType(AppBackButton), findsNothing);
        await tester.tap(find.text('Open page'));
        await tester.pumpAndSettle();
        expect(find.text('Back'), findsOneWidget);
        final back = tester.getRect(find.byType(AppBackButton));
        expect(back.left, closeTo(16, 1));
        expect(back.top, lessThan(80));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();
        expect(find.text('Open page'), findsOneWidget);
        expect(find.text('Page content'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('information pages use the same back navigation', (tester) async {
    await tester.pumpWidget(app((_) => const InfoPage(
        title: 'About StallSeeker', children: [Text('Information')])));
    await tester.tap(find.text('Open page'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBackButton), findsOneWidget);
    expect(tester.getRect(find.byType(AppBackButton)).left, closeTo(16, 1));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open page'), findsOneWidget);
  });

  for (final width in [320.0, 960.0]) {
    testWidgets('sheet close button is at top left at $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => const SizedBox(
                              height: 350,
                              child: Column(children: [
                                AppSheetHeader(title: Text('Saved searches')),
                                Expanded(
                                    child:
                                        Center(child: Text('Sheet content'))),
                              ]))),
                      child: const Text('Open sheet'))))));
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      final header = tester.getRect(find.byType(AppSheetHeader));
      final close = tester.getRect(find.byType(AppBackButton));
      expect(close.left, closeTo(header.left + 16, 1));
      expect(close.top, closeTo(header.top + 12, 1));
      expect(close.top,
          lessThan(tester.getTopLeft(find.text('Saved searches')).dy));
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet content'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a disabled back button cannot leave while saving',
      (tester) async {
    await tester.pumpWidget(app((_) => const Scaffold(
        appBar: AppPageAppBar(title: Text('Saving'), backEnabled: false),
        body: Text('Editor'))));
    await tester.tap(find.text('Open page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Editor'), findsOneWidget);
    expect(find.text('Open page'), findsNothing);
  });

  for (final customBack in [false, true]) {
    testWidgets('back keeps the unsaved-changes prompt (custom: $customBack)',
        (tester) async {
      final guard = GlobalKey<UnsavedStallChangesGuardState>();
      await tester.pumpWidget(app((_) => UnsavedStallChangesGuard(
          key: guard,
          hasChanges: true,
          saving: false,
          onSave: () async {},
          child: Scaffold(
              appBar: AppPageAppBar(
                  title: const Text('Edit stall'),
                  backLabel: 'Cancel',
                  onBack: customBack
                      ? () => guard.currentState!.requestLeave()
                      : null),
              body: const Text('Unsaved editor')))));
      await tester.tap(find.text('Open page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Save your changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved editor'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(find.text('Open page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
````

## File: test/clear_discovery_filters_test.dart
````dart
// Exercise the real discovery screen with read-only data and a map placeholder.
// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_dropdown.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/features/customer/home/discovery_options.dart';

class _SignedOutAuth extends FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;
  @override
  FirebaseAuthPlatform setInitialValues(
          {PigeonUserDetails? currentUser, String? languageCode}) =>
      this;
  @override
  UserPlatform? get currentUser => null;
}

class _DiscoveryFirestore extends FirebaseFirestorePlatform {
  @override
  FirebaseFirestorePlatform delegateFor(
          {required FirebaseApp app, required String databaseId}) =>
      this;
  @override
  CollectionReferencePlatform collection(String path) =>
      _Collection(this, path);
  @override
  QueryPlatform collectionGroup(String path) => _Collection(this, path);
  @override
  DocumentReferencePlatform doc(String path) => _Document(this, path);
}

class _Collection extends CollectionReferencePlatform {
  _Collection(super.firestore, super.path);
  @override
  DocumentReferencePlatform doc([String? path]) =>
      firestore.doc('${this.path}/${path ?? 'generated'}');
  @override
  Stream<QuerySnapshotPlatform> snapshots(
          {bool includeMetadataChanges = false,
          ServerTimestampBehavior serverTimestampBehavior =
              ServerTimestampBehavior.none,
          required ListenSource listenSource}) =>
      Stream.value(QuerySnapshotPlatform([
        if (path == 'vendors')
          DocumentSnapshotPlatform(
              firestore,
              'vendors/stall',
              {
                'stallName': 'Nasi Stall',
                'category': 'Rice',
                'latitude': 3.139,
                'longitude': 101.6869,
                'isOpen': false,
              },
              PigeonSnapshotMetadata(
                  hasPendingWrites: false, isFromCache: true)),
      ], [], SnapshotMetadataPlatform(false, true)));
}

class _Document extends DocumentReferencePlatform {
  _Document(super.firestore, super.path);
}

class _PlaceholderMaps extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
          int creationId, PlatformViewCreatedCallback onPlatformViewCreated,
          {required MapWidgetConfiguration widgetConfiguration,
          MapConfiguration mapConfiguration = const MapConfiguration(),
          MapObjects mapObjects = const MapObjects()}) =>
      const SizedBox.expand();
}

class _NoLocation extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = _SignedOutAuth();
    FirebaseFirestorePlatform.instance = _DiscoveryFirestore();
    GoogleMapsFlutterPlatform.instance = _PlaceholderMaps();
    GeolocatorPlatform.instance = _NoLocation();
  });
  setUp(() => SharedPreferences.setMockInitialValues({
        'guest_search_history_v1': ['Previous search'],
      }));

  for (final width in [320.0, 960.0]) {
    testWidgets('clear all discovery filters in map and list views at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme, home: const CustomerHomeScreen()));
      await tester.pumpAndSettle();

      AppDropdown<String> dropdown(String hint) =>
          tester.widget<AppDropdown<String>>(find.byWidgetPredicate((widget) =>
              widget is AppDropdown<String> && widget.hint == hint));
      Finder chip(String label) => find.widgetWithText(InputChip, label);

      for (final listView in [false, true]) {
        if (listView) {
          final switchView = find.widgetWithText(ActionChip, 'List view');
          await Scrollable.ensureVisible(tester.element(switchView),
              alignment: .5);
          await tester.tap(switchView);
          await tester.pumpAndSettle();
        }
        // Set several filters together, including a schedule and price range.
        dropdown('Choose category').onChanged!('Drinks');
        tester
            .widget<AppDropdown<DiscoverySort>>(
                find.byType(AppDropdown<DiscoverySort>))
            .onChanged!(DiscoverySort.price);
        for (final filter in [
          'Available dishes',
          'Self-collect',
          'Updated in 24h'
        ]) {
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, filter))
              .onSelected!(true);
        }
        await tester.pump();
        await Scrollable.ensureVisible(tester.element(chip('Any price')),
            alignment: .5);
        await tester.tap(chip('Any price'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '5');
        await tester.enterText(find.byType(TextFormField).last, '10');
        await tester.tap(find.text('Apply price range'));
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(tester.element(chip('Open at…')),
            alignment: .5);
        await tester.tap(chip('Open at…'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tomorrow morning'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byType(TextField).first, 'No matching dish');
        await tester.pumpAndSettle();
        expect(dropdown('Choose category').value, 'Drinks');
        expect(dropdown('Choose stall status').displayText, 'Scheduled');

        // The reset stays visible even when the filter strip is scrolled.
        await tester.tap(find.text('Clear filters'));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<TextField>(find.byType(TextField).first)
                .controller!
                .text,
            isEmpty);
        expect(dropdown('Choose category').value, 'All');
        expect(dropdown('Choose stall status').value, 'All');
        expect(dropdown('Choose stall status').displayText, isNull);
        expect(chip('Any price'), findsOneWidget);
        expect(chip('Open at…'), findsOneWidget);
        for (final filter in [
          'Available dishes',
          'Self-collect',
          'Updated in 24h'
        ]) {
          expect(
              tester
                  .widget<FilterChip>(find.widgetWithText(FilterChip, filter))
                  .selected,
              isFalse);
        }
        expect(
            tester
                .widget<AppDropdown<DiscoverySort>>(
                    find.byType(AppDropdown<DiscoverySort>))
                .value,
            DiscoverySort.price);
        expect(find.text(listView ? 'Map view' : 'List view'), findsOneWidget);
        if (listView) {
          expect(find.text('Nasi Stall'), findsOneWidget);
        } else {
          expect(
              tester.widget<GoogleMap>(find.byType(GoogleMap)).markers.length,
              1);
        }
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('guest_search_history_v1'),
            ['Previous search']);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
````

## File: test/customer_discovery_search_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/dish_search_entry.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/discovery_search_filters.dart';
import 'package:stallseeker/features/customer/home/price_range_picker.dart';

VendorModel vendor(String id, String name, {String category = 'Malay Food'}) =>
    VendorModel(
      vendorId: id,
      stallName: name,
      description: '',
      category: category,
      openingHours: '',
      latitude: 3.1,
      longitude: 101.7,
    );

DishSearchEntry dish(String vendorId, String name, double price,
        {bool priceIsKnown = true}) =>
    DishSearchEntry(
      vendorId: vendorId,
      item: MenuItemModel(itemId: name, name: name, price: price),
      priceIsKnown: priceIsKnown,
    );

void main() {
  group('price filtering', () {
    test('includes both boundaries and supports either open end', () {
      const range = MenuPriceRange(minimum: 5, maximum: 10);
      expect(range.contains(dish('a', 'Lower', 5)), isTrue);
      expect(range.contains(dish('a', 'Upper', 10)), isTrue);
      expect(range.contains(dish('a', 'Low', 4.99)), isFalse);
      expect(range.contains(dish('a', 'High', 10.01)), isFalse);
      expect(const MenuPriceRange(minimum: 5).contains(dish('a', 'High', 100)),
          isTrue);
      expect(const MenuPriceRange(maximum: 10).contains(dish('a', 'Low', 0)),
          isTrue);
    });

    test('missing or invalid prices cannot masquerade as free menu items', () {
      const range = MenuPriceRange(minimum: 0, maximum: 0);
      expect(range.contains(dish('a', 'Actual free item', 0)), isTrue);
      expect(
          range.contains(dish('a', 'No saved price', 0, priceIsKnown: false)),
          isFalse);
      expect(range.contains(dish('a', 'Negative', -1)), isFalse);
      expect(range.contains(dish('a', 'Invalid', double.nan)), isFalse);
      expect(range.contains(dish('a', 'Infinite', double.infinity)), isFalse);
    });

    test('a cheap unrelated dish cannot qualify an expensive dish search', () {
      final seller = vendor('a', 'Warung A');
      final menu = [dish('a', 'Nasi lemak', 12), dish('a', 'Teh ais', 3)];
      const range = MenuPriceRange(maximum: 5);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'nasi', priceRange: range),
          isFalse);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'warung', priceRange: range),
          isTrue);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'malay', priceRange: range),
          isTrue);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'nasi'),
          isTrue);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: const [], query: '', priceRange: range),
          isFalse);
    });
  });

  group('live search suggestions', () {
    test('prefix matches outrank contains/history and labels are distinct', () {
      final suggestions = buildDiscoverySuggestions(
        query: '  NASI  ',
        vendors: [vendor('a', 'Nasi Corner')],
        dishes: [
          dish('a', 'Nasi lemak', 5),
          dish('a', '  NASI   lemak  ', 7),
          dish('a', 'Special nasi goreng', 6),
        ],
        categories: const ['Malay Food'],
        recentSearches: const ['My nasi spot', 'nasi lemak'],
      );
      expect(suggestions.map((item) => item.label), [
        'Nasi lemak',
        'Nasi Corner',
        'Special nasi goreng',
        'My nasi spot',
      ]);
      expect(suggestions.first.kind, DiscoverySuggestionKind.dish);
      expect(suggestions.first.isRecent, isTrue);
    });

    test('keeps dish, stall, category and history suggestions within budget',
        () {
      final suggestions = buildDiscoverySuggestions(
        query: 'burger',
        vendors: [vendor('a', 'Burger Corner', category: 'Burger')],
        dishes: [
          dish('a', 'Burger ayam', 5),
          dish('a', 'Burger premium', 20),
          dish('orphan', 'Burger elsewhere', 4),
        ],
        categories: const ['Burger', 'Malay Food'],
        recentSearches: const ['Burger favourite'],
        priceRange: const MenuPriceRange(maximum: 10),
      );
      expect(suggestions.map((item) => item.label), [
        'Burger',
        'Burger ayam',
        'Burger Corner',
        'Burger favourite',
      ]);
      // Exact category matches appear first even before dish prefix matches.
    });

    test('empty input keeps history order and filters duplicates', () {
      final suggestions = buildDiscoverySuggestions(
        query: '',
        vendors: const [],
        dishes: const [],
        categories: const [],
        recentSearches: const ['Nasi lemak', 'burger', ' NASI  LEMAK '],
      );
      expect(suggestions.map((item) => item.label), ['Nasi lemak', 'burger']);
    });
  });

  testWidgets(
      'price picker validates reversed bounds and applies exact amounts',
      (tester) async {
    MenuPriceRange? selected;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              selected = await showPriceRangePicker(context);
            },
            child: const Text('Choose price'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Choose price'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).last, '5');
    await tester.tap(find.text('Apply price range'));
    await tester.pumpAndSettle();
    expect(find.text('Must be at least the minimum'), findsOneWidget);
    expect(selected, isNull);
    await tester.enterText(find.byType(TextFormField).last, '12.50');
    await tester.tap(find.text('Apply price range'));
    await tester.pumpAndSettle();
    expect(selected?.minimum, 10);
    expect(selected?.maximum, 12.5);

    await tester.tap(find.text('Choose price'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(selected?.isActive, isFalse);
  });
}
````

## File: test/demo_orders_screen_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/features/shared/demo_orders_screen.dart';

void main() {
  testWidgets('customer bookings only show Active and History', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DemoOrdersScreen(
        isVendor: false,
        accountId: 'test-customer',
        liveBookings: Stream.value(<DemoOrder>[]),
      ),
    ));
    expect(find.text('Past demos'), findsNothing);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No bookings in this section yet.'), findsOneWidget);
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(find.text('No bookings in this section yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
````

## File: test/discovery_options_test.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stallseeker/core/models/dish_search_entry.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/discovery_options.dart';
import 'package:stallseeker/features/customer/home/discovery_search_filters.dart';

VendorModel vendor(String id, {DateTime? created, DateTime? updated}) =>
    VendorModel(
        vendorId: id,
        stallName: id,
        category: 'Burger',
        openingHours: '',
        description: '',
        latitude: id == 'a' ? 3.1 : 3.2,
        longitude: 101.7,
        createdAt: created,
        updatedAt: updated);

DishSearchEntry dish(String owner, String id, double price,
        {bool known = true, String status = 'available', DateTime? updated}) =>
    DishSearchEntry(
        vendorId: owner,
        priceIsKnown: known,
        item: MenuItemModel(
            itemId: id,
            name: id,
            price: price,
            status: status,
            statusUpdatedAt: updated));

void main() {
  test('legacy category records remain readable and multiple categories filter',
      () {
    final legacy = VendorModel.fromMap({'category': 'Burger'}, 'old');
    expect(legacy.allCategories, ['Burger']);
    final multiple = VendorModel.fromMap({
      'category': 'Burger',
      'categories': ['Burger', 'Beverages', 'Burger'],
    }, 'new');
    expect(multiple.allCategories, ['Burger', 'Beverages']);
    expect(multiple.hasCategory('Beverages'), isTrue);
    expect(multiple.toProfileMap()['categories'], ['Burger', 'Beverages']);
    expect(
        vendorMatchesQueryAndPrice(
            vendor: multiple, dishes: [], query: 'beverages'),
        isTrue);
    expect(multiple.copyWith(stallName: 'Renamed').allCategories,
        multiple.allCategories);
  });

  test('dish search handles alternatives, abbreviations and small misspellings',
      () {
    for (final pair in [
      ['burgre', 'Burger ayam'],
      ['burgr', 'Burger'],
      ['mee grg', 'Mi goreng'],
      ['banana fritters', 'Goreng pisang'],
      ['roti prata', 'Roti canai'],
      ['coconut rice', 'Nasi lemak'],
      ['char kway teow', 'Char kuey teow'],
    ]) {
      expect(discoveryMatches(pair[0], pair[1]), isTrue,
          reason: pair.toString());
    }
    expect(discoveryMatches('burger', 'Nasi lemak'), isFalse);
    expect(discoveryMatches('teh', 'mee'), isFalse);
    expect(discoverySearchScore('Burger', 'Burger'), 0);
    expect(discoverySearchScore('burgre', 'Burger'), greaterThan(0));
  });

  test('sorting uses real prices and ratings, with unknowns last', () {
    final vendors = [vendor('a'), vendor('b'), vendor('c')];
    final menus = {
      'a': [dish('a', 'Burger', 8)],
      'b': [dish('b', 'Burger', 5)],
      'c': [dish('c', 'Burger', 0, known: false)],
    };
    final ratings = {
      'a': const StallRatingSummary(4.8, 5),
      'b': const StallRatingSummary(4.1, 12),
      'c': const StallRatingSummary(0, 0)
    };
    List<String> sort(DiscoverySort option) => (vendors.toList()
          ..sort((a, b) => compareDiscoveryVendors(a, b,
              sort: option,
              center: const LatLng(3.1, 101.7),
              ratings: ratings,
              dishes: menus)))
        .map((v) => v.vendorId)
        .toList();
    expect(sort(DiscoverySort.price), ['b', 'a', 'c']);
    expect(sort(DiscoverySort.rating), ['a', 'b', 'c']);
    expect(sort(DiscoverySort.distance).first, 'a');
  });

  test('newest sorting does not invent dates for old profiles', () {
    final now = DateTime.utc(2026, 10, 24);
    final values = [
      vendor('unknown'),
      vendor('old', created: now.subtract(const Duration(days: 2))),
      vendor('new', created: now)
    ];
    values.sort((a, b) => compareDiscoveryVendors(a, b,
        sort: DiscoverySort.newest, center: null, ratings: {}, dishes: {}));
    expect(values.map((v) => v.vendorId), ['new', 'old', 'unknown']);
  });

  test('recent means profile or menu update within 24h, not live GPS', () {
    final now = DateTime.utc(2026, 10, 24, 10);
    final stall = VendorModel.fromMap(
        {'locationUpdatedAt': Timestamp.fromDate(now)}, 'a');
    expect(stallUpdatedRecently(stall, [], now: now), isFalse);
    expect(
        stallUpdatedRecently(
            stall,
            [
              dish('a', 'food', 5,
                  updated: now.subtract(const Duration(hours: 2)))
            ],
            now: now),
        isTrue);
    expect(
        stallUpdatedRecently(
            stall,
            [
              dish('a', 'food', 5,
                  updated: now.subtract(const Duration(hours: 25)))
            ],
            now: now),
        isFalse);
    expect(dishIsAvailable(dish('a', 'food', 5, status: 'low_stock')), isTrue);
    expect(
        dishIsAvailable(dish('a', 'food', 5, status: 'out_of_stock')), isFalse);
  });

  test('menu details round trip without requiring them on old dishes', () {
    final item = MenuItemModel(
        itemId: 'dish',
        name: 'Nasi Lemak',
        price: 6,
        description: 'Coconut rice',
        portionSize: '1 plate',
        ingredients: ['Rice', 'Peanuts']);
    final restored = MenuItemModel.fromMap({
      ...item.toMap(),
      'statusUpdatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 24)),
    }, 'dish');
    expect(restored.description, 'Coconut rice');
    expect(restored.portionSize, '1 plate');
    expect(restored.ingredients, ['Rice', 'Peanuts']);
    expect(
        MenuItemModel.fromMap({'name': 'Old dish', 'price': 5}, 'old')
            .ingredients,
        isEmpty);
  });
}
````

## File: test/edit_stall_view_test.dart
````dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/vendor/profile/edit_stall_view.dart';
import 'package:stallseeker/features/vendor/profile/stall_profile_draft.dart';

class _Harness extends StatefulWidget {
  const _Harness(
      {this.saving = false,
      this.loading = false,
      this.picking = false,
      this.onAction});
  final bool saving, loading, picking;
  final ValueChanged<String>? onAction;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: 'Uncle John Drink Stall');
  final description = TextEditingController(
      text: 'Freshly brewed teh tarik and refreshing local drinks.');
  final phone = TextEditingController(text: '012-345 6789');
  final categories = <String>{'Beverages'};
  Map<int, List<StallHoursInterval>> hours = {
    for (var day = 1; day <= 5; day++)
      day: [const StallHoursInterval(540, 1020)]
  };
  List<TemporaryClosure> closures = [];
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EditStallView(
        formKey: form,
        nameController: name,
        descriptionController: description,
        phoneController: phone,
        image: Container(
            height: 180,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: FilledButton.icon(
                onPressed: widget.saving || widget.picking
                    ? null
                    : () => widget.onAction?.call('photo'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Change photo'))),
        categoryOptions: const ['Beverages', 'Burger', 'Malay Food'],
        selectedCategories: categories,
        hours: hours,
        closures: closures,
        loading: widget.loading,
        saving: widget.saving,
        pickingImage: widget.picking,
        onCategoryChanged: (category, selected) => setState(() {
          if (selected) {
            categories.add(category);
          } else {
            categories.remove(category);
          }
        }),
        onScheduleChanged: (nextHours, nextClosures) => setState(() {
          hours = nextHours;
          closures = nextClosures;
        }),
        onFormChanged: () => setState(() {}),
        onCancel: () => widget.onAction?.call('cancel'),
        onSave: () {
          if (form.currentState!.validate()) {
            widget.onAction?.call('save:${name.text}');
          }
        },
        onPreview: () => widget.onAction?.call('preview:${name.text}'),
      );
}

ThemeData _previewTheme() {
  final theme = AppTheme.lightTheme;
  if (!const bool.fromEnvironment('EDIT_STALL_PREVIEW')) {
    return theme;
  }
  return theme.copyWith(
    appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle:
            theme.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Roboto')),
    chipTheme: theme.chipTheme.copyWith(
        labelStyle: theme.chipTheme.labelStyle?.copyWith(fontFamily: 'Roboto')),
  );
}

Widget _app(
        {double scale = 1,
        bool saving = false,
        bool loading = false,
        bool picking = false,
        ValueChanged<String>? onAction}) =>
    MaterialApp(
      theme: _previewTheme(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: RepaintBoundary(
          key: const Key('edit-stall-preview'),
          child: _Harness(
              saving: saving,
              loading: loading,
              picking: picking,
              onAction: onAction)),
    );
void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('EDIT_STALL_PREVIEW')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('edit-stall-preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('tmp/edit-stall-previews').create(recursive: true);
    await File('tmp/edit-stall-previews/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('EDIT_STALL_PREVIEW')) return;
    const root = String.fromEnvironment('PREVIEW_FONT_ROOT');
    final font = FontLoader('Roboto');
    for (final name in ['Regular', 'Medium']) {
      font.addFont(Future.value(ByteData.sublistView(
          await File('$root/Roboto-$name.ttf').readAsBytes())));
    }
    await font.load();
    final fallback = FontLoader('Ahem')
      ..addFont(Future.value(ByteData.sublistView(
          await File('$root/Roboto-Regular.ttf').readAsBytes())));
    await fallback.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('draft changes profile fields without changing live operational state',
      () {
    final original = VendorModel(
        vendorId: 'v',
        stallName: 'Old name',
        description: 'Old description',
        category: 'Beverages',
        openingHours: '9 AM – 5 PM',
        isOpen: true,
        latitude: 3.14,
        longitude: 101.69,
        selfCollectEnabled: true,
        locationSharingActive: true,
        locationUpdatedAt: DateTime.utc(2026, 10, 25),
        imageUrl: 'https://example.com/old.jpg');
    final hours = {
      1: [const StallHoursInterval(1320, 120)]
    };
    final closures = [
      TemporaryClosure(DateTime.utc(2026, 10, 26), DateTime.utc(2026, 10, 27))
    ];
    final draft = buildStallProfileDraft(
        original: original,
        name: ' New name ',
        description: ' New description ',
        phone: '012-345 6789',
        legacyHours: original.openingHours,
        categories: ['Beverages', 'Burger'],
        hours: hours,
        closures: closures);
    expect(draft.stallName, 'New name');
    expect(draft.phoneNumber, '+60123456789');
    expect(draft.allCategories, ['Beverages', 'Burger']);
    expect(draft.isOpen, true);
    expect(draft.selfCollectEnabled, true);
    expect(draft.latitude, original.latitude);
    expect(draft.longitude, original.longitude);
    expect(draft.locationSharingActive, true);
    expect(draft.locationUpdatedAt, original.locationUpdatedAt);
    expect(draft.imageUrl, original.imageUrl);
    expect(original.stallName, 'Old name');
    hours[1]!.clear();
    closures.clear();
    expect(draft.weeklyHours[1], hasLength(1));
    expect(draft.temporaryClosures, hasLength(1));
  });
  for (final size in [
    const Size(320, 740),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(960, 700),
    const Size(1280, 800)
  ]) {
    testWidgets('responsive Edit stall at ${size.width} × ${size.height}',
        (tester) async {
      _viewport(tester, size);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final wide = size.width >= 900;
      expect(
          find.byKey(Key(
              wide ? 'edit-stall-two-columns' : 'edit-stall-single-column')),
          findsOneWidget);
      final details =
          tester.getRect(find.byKey(const Key('edit-stall-details')));
      final hours = tester.getRect(find.byKey(const Key('edit-stall-hours')));
      if (wide) {
        expect(hours.left, greaterThan(details.right));
        expect(hours.top, closeTo(details.top, 1));
      } else {
        expect(hours.top, greaterThan(details.bottom));
      }
      final save = find.byKey(const Key('edit-stall-save'));
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(size.height));
      expect(tester.getRect(save).top, greaterThan(size.height - 100));
      expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'edit-stall-${size.width.toInt()}');
    });
  }
  testWidgets(
      'Save stays fixed while scrolling and opening hours expands on phone',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await tester.pumpWidget(_app());
    final save = find.byKey(const Key('edit-stall-save'));
    final before = tester.getRect(save);
    expect(find.text('Monday'), findsNothing);
    await tester.ensureVisible(find.text('Opening hours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opening hours'));
    await tester.pumpAndSettle();
    expect(find.text('Monday'), findsOneWidget);
    expect(tester.getRect(save), before);
    await tester.ensureVisible(find.text('Monday'));
    await tester.tap(find.text('Monday'));
    await tester.pumpAndSettle();
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.hours[1], isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'hours sheet edits the draft and closing it does not save the profile',
      (tester) async {
    _viewport(tester, const Size(1280, 800));
    final actions = <String>[];
    await tester.pumpWidget(_app(onAction: actions.add));
    await tester.tap(find.text('Edit weekly hours'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly opening hours'), findsOneWidget);
    await tester.tap(find.text('Monday').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(
        tester.state<_HarnessState>(find.byType(_Harness)).hours[1], isEmpty);
    expect(actions, isEmpty);
  });
  testWidgets(
      'category chooser keeps multiple selections and form edits on resize',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await tester.pumpWidget(_app());
    await tester.enterText(
        find.byType(TextFormField).first, 'My updated stall');
    await tester.ensureVisible(find.text('Choose categories'));
    await tester.tap(find.text('Choose categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Burger'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(tester.state<_HarnessState>(find.byType(_Harness)).categories,
        {'Beverages', 'Burger'});
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-stall-two-columns')), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'My updated stall');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Preview reads unsaved text and does not trigger Save',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final actions = <String>[];
    await tester.pumpWidget(_app(onAction: actions.add));
    await tester.enterText(find.byType(TextFormField).first, 'New stall name');
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(actions, ['preview:New stall name']);
    await tester.tap(find.text('Cancel'));
    expect(actions.last, 'cancel');
  });
  testWidgets('fixed Save validates and uses the latest fields',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final actions = <String>[];
    await tester.pumpWidget(_app(onAction: actions.add));
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.tap(find.byKey(const Key('edit-stall-save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your stall name.'), findsOneWidget);
    expect(actions, isEmpty);
    await tester.enterText(find.byType(TextFormField).first, 'New name');
    await tester.tap(find.byKey(const Key('edit-stall-save')));
    await tester.pumpAndSettle();
    expect(actions, ['save:New name']);
  });
  testWidgets(
      'Save and Preview disable during saving, loading and photo selection',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    for (final mode in ['saving', 'loading', 'picking']) {
      await tester.pumpWidget(_app(
          saving: mode == 'saving',
          loading: mode == 'loading',
          picking: mode == 'picking'));
      await tester.pump();
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('edit-stall-save')))
              .onPressed,
          isNull);
      expect(
          tester
              .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, 'Preview'))
              .onPressed,
          isNull);
      expect(tester.takeException(), isNull);
    }
  });
  for (final width in [320.0, 960.0]) {
    testWidgets('large text fits $width and footer remains above the keyboard',
        (tester) async {
      _viewport(tester, Size(width, 900));
      await tester.pumpWidget(_app(scale: 1.6));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final save = tester.getRect(find.byKey(const Key('edit-stall-save')));
      expect(save.bottom, lessThanOrEqualTo(600));
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Opening hours'));
      await tester.tap(find.text('Opening hours'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Opens 9:00 AM').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
````

## File: test/map_marker_focus_test.dart
````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/map_marker_focus.dart';

void main() {
  final bounds = LatLngBounds(
    southwest: const LatLng(3.10, 101.65),
    northeast: const LatLng(3.18, 101.73),
  );
  final nearby = VendorModel(
    vendorId: 'nearby',
    stallName: 'Nearby stall',
    description: '',
    category: 'Drinks',
    openingHours: '',
    latitude: 3.1405,
    longitude: 101.6865,
  );
  final distant = VendorModel(
    vendorId: 'distant',
    stallName: 'Distant stall',
    description: '',
    category: 'Drinks',
    openingHours: '',
    latitude: 3.16,
    longitude: 101.71,
  );

  test('selects the nearest stall when the map settles over its marker', () {
    final focused = stallNearMapCenter(
      center: const LatLng(3.14, 101.686),
      bounds: bounds,
      vendors: [distant, nearby],
    );
    expect(focused?.vendorId, 'nearby');
  });

  test('does not select a stall away from the map center', () {
    final focused = stallNearMapCenter(
      center: const LatLng(3.14, 101.686),
      bounds: bounds,
      vendors: [distant],
    );
    expect(focused, isNull);
  });
}
````

## File: test/map_marker_guide_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/customer/home/map_marker_guide.dart';

void main() {
  for (final width in [320.0, 390.0, 420.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
          'marker guide reserves enough space at $width px / $scale text',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Builder(builder: (context) {
                return SizedBox(
                  height: MapMarkerGuide.heightFor(context, width) + 112,
                  child: const Column(children: [
                    MapMarkerGuide(),
                    SizedBox(height: 112, child: Text('Stall card')),
                  ]),
                );
              }),
            ),
          ),
        ));
        expect(find.text('Search location'), findsOneWidget);
        expect(find.text('Other stalls'), findsOneWidget);
        expect(find.text('Selected stall'), findsOneWidget);
        expect(tester.getBottomLeft(find.byType(MapMarkerGuide)).dy,
            lessThanOrEqualTo(tester.getTopLeft(find.text('Stall card')).dy));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
````

## File: test/recent_changes_test.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/utils/vendor_phone.dart';
import 'package:stallseeker/features/vendor/profile/stall_schedule_editor.dart';

void main() {
  group('vendor phone', () {
    test('normalizes common Malaysian mobile and landline formats', () {
      expect(normalizeVendorPhone('012-345 6789'), '+60123456789');
      expect(normalizeVendorPhone('+60 12 345 6789'), '+60123456789');
      expect(normalizeVendorPhone('03-1234 5678'), '+60312345678');
    });

    test('rejects blank, foreign and implausible numbers', () {
      expect(normalizeVendorPhone(''), isNull);
      expect(normalizeVendorPhone('+44 20 1234 5678'), isNull);
      expect(normalizeVendorPhone('01234'), isNull);
    });
  });

  group('structured hours and closures', () {
    test('round-trips weekday intervals and rejects invalid ranges', () {
      final hours = <int, List<StallHoursInterval>>{
        1: [const StallHoursInterval(9 * 60, 12 * 60),
            const StallHoursInterval(13 * 60, 17 * 60)],
        6: [const StallHoursInterval(20 * 60, 2 * 60)],
      };
      final parsed = parseWeeklyHours(serializeWeeklyHours(hours));
      expect(parsed[1]!.map((range) => range.openMinute), [540, 780]);
      expect(parsed[6]!.single.closeMinute, 120);
      expect(StallHoursInterval.fromMap({'open': 540, 'close': 540}), isNull);
      expect(StallHoursInterval.fromMap({'open': -1, 'close': 600}), isNull);
    });

    test('closure start is inclusive and end is exclusive', () {
      final start = DateTime.utc(2026, 9, 18, 2);
      final end = start.add(const Duration(hours: 3));
      final closure = TemporaryClosure(start, end);
      final parsed = TemporaryClosure.fromMap(closure.toMap())!;
      expect(parsed.contains(start), isTrue);
      expect(parsed.contains(end.subtract(const Duration(milliseconds: 1))),
          isTrue);
      expect(parsed.contains(end), isFalse);
      expect(TemporaryClosure.fromMap({
        'startAt': Timestamp.fromDate(end),
        'endAt': Timestamp.fromDate(start),
      }), isNull);
    });

    test('active closure hides an otherwise open stall', () {
      final now = DateTime.now();
      final vendor = VendorModel(
        vendorId: 'vendor-a', stallName: 'Test', description: '',
        category: 'Malay Food', openingHours: '', isOpen: true,
        temporaryClosures: [TemporaryClosure(
          now.subtract(const Duration(minutes: 1)),
          now.add(const Duration(minutes: 1)))],
      );
      expect(vendor.isTemporarilyClosed, isTrue);
      expect(vendor.isOpenNow, isFalse);
      expect(vendor.copyWith(temporaryClosures: []).isOpenNow, isTrue);
    });
  });

  test('old dishes get a section, and stock time comes from Firestore', () {
    final legacy = MenuItemModel.fromMap(
      {'name': 'Nasi lemak', 'price': 5.5, 'status': 'available'}, 'dish-1');
    expect(legacy.section, 'Main menu');
    expect(legacy.statusUpdatedAt, isNull);

    final updated = DateTime.utc(2026, 9, 18, 3);
    final current = MenuItemModel.fromMap({
      'name': 'Teh ais', 'price': 2,
      'section': 'Drinks', 'status': 'low_stock',
      'statusUpdatedAt': Timestamp.fromDate(updated),
    }, 'dish-2');
    expect(current.section, 'Drinks');
    expect(current.statusUpdatedAt!.toUtc(), updated);
  });

  testWidgets('vendor can toggle a day and add a second time period',
      (tester) async {
    var hours = <int, List<StallHoursInterval>>{};
    final closures = <TemporaryClosure>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        child: StallScheduleEditor(hours: hours, closures: closures,
          onChanged: (nextHours, _) => setState(() => hours = nextHours))),
    ))));

    await tester.tap(find.text('Monday').first);
    await tester.pump();
    expect(hours[1], hasLength(1));
    expect(hours[1]!.single.openMinute, 540);

    await tester.tap(find.text('Add time').first);
    await tester.pump();
    expect(hours[1], hasLength(2));

    await tester.tap(find.byTooltip('Remove time').first);
    await tester.pump();
    expect(hours[1], hasLength(1));
  });
}
````

## File: test/saved_location_test.dart
````dart
// Firebase SDK references are faked only in tests to verify local storage and
// current-user routing without a Firebase app or network. Server-rule permission
// enforcement is tested separately with the emulator.
// ignore_for_file: subtype_of_sealed_class

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stallseeker/core/models/saved_location.dart';
import 'package:stallseeker/core/services/saved_location_service.dart';

Map<String, dynamic> locationMap({bool home = false}) => {
      'name': home ? 'Home' : 'Campus',
      'address': 'Bangi, Selangor',
      'latitude': 2.9213,
      'longitude': 101.7753,
      'isHome': home,
    };

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);
  @override
  User? currentUser;
}

class _User extends Fake implements User {
  _User(this.uid, {this.isAnonymous = false});
  @override
  final String uid;
  @override
  final bool isAnonymous;
}

class _Firestore extends Fake implements FirebaseFirestore {
  final records = <String, Map<String, dynamic>>{};
  final deleted = <String>[];

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.database, this.path);
  final _Firestore database;
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(database, '${this.path}/${path ?? 'generated-id'}');

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _Snapshot([
        for (final record in database.records.entries)
          if (record.key.startsWith('$path/') &&
              !record.key.substring(path.length + 1).contains('/'))
            _QueryDocument(record.key.split('/').last, record.value),
      ]);
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.database, this.path);
  final _Firestore database;
  @override
  final String path;
  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection(database, '$path/$collectionPath');

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    database.records[path] = Map.of(data);
  }

  @override
  Future<void> delete() async {
    database.records.remove(path);
    database.deleted.add(path);
  }
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _QueryDocument extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _QueryDocument(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('saved location validation', () {
    test('round-trips the exact map coordinate and selected place label', () {
      final location = SavedLocation.fromMap('campus', locationMap())!;
      expect(location.coordinates, const LatLng(2.9213, 101.7753));
      expect(location.selection.coordinates, location.coordinates);
      expect(location.selection.label, 'Campus · Bangi, Selangor');
      expect(SavedLocation.fromMap(location.id, location.toMap())!.toMap(),
          location.toMap());
    });

    test('rejects non-numeric, non-finite and out-of-range raw coordinates',
        () {
      for (final entry in <MapEntry<String, Object>>[
        const MapEntry('latitude', '2.9'),
        const MapEntry('longitude', '101.7'),
        const MapEntry('latitude', double.nan),
        const MapEntry('longitude', double.infinity),
        const MapEntry('latitude', 90.01),
        const MapEntry('latitude', -90.01),
        const MapEntry('longitude', 180.01),
        const MapEntry('longitude', -180.01),
      ]) {
        expect(
            SavedLocation.fromMap(
                'campus', {...locationMap(), entry.key: entry.value}),
            isNull);
      }
      expect(
          SavedLocation.fromMap('campus', {
            ...locationMap(),
            'latitude': -90,
            'longitude': -180,
          }),
          isNotNull);
    });

    test('requires bounded name/address strings and a Home-consistent flag',
        () {
      for (final overrides in <Map<String, dynamic>>[
        {'name': '  '},
        {'name': List.filled(61, 'x').join()},
        {'name': 3},
        {'address': ''},
        {'address': List.filled(501, 'x').join()},
        {'address': null},
        {'isHome': 'true'},
        {'isHome': true},
      ]) {
        expect(
            SavedLocation.fromMap('campus', {...locationMap(), ...overrides}),
            isNull);
      }
      expect(SavedLocation.fromMap('home', locationMap()), isNull);
      expect(SavedLocation.fromMap('home', locationMap(home: true))?.isHome,
          isTrue);
      expect(
          SavedLocation.fromMap('home', {
            ...locationMap(home: true),
            'name': 'Office',
          }),
          isNull);
      for (final id in ['', 'folder/campus', '.', '..']) {
        expect(SavedLocation.fromMap(id, locationMap()), isNull);
      }
    });
  });

  group('guest saved places', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('saves locally, replaces Home, edits custom pins and deletes them',
        () async {
      final database = _Firestore();
      final service = SavedLocationService(
          auth: _Auth(_User('guest-1', isAnonymous: true)),
          firestore: database);
      await service.save(
          name: 'Ignored Home name',
          address: 'First address',
          coordinates: const LatLng(3.1, 101.7),
          isHome: true);
      await service.save(
          name: 'Home',
          address: 'Updated home',
          coordinates: const LatLng(3.2, 101.8),
          isHome: true);
      await service.save(
          name: '  Office  ',
          address: '  Office address  ',
          coordinates: const LatLng(3.3, 101.9),
          isHome: false,
          id: 'office');
      var locations = await service.load();
      expect(locations.map((place) => place.id), ['home', 'office']);
      expect(locations.first.name, 'Home');
      expect(locations.first.address, 'Updated home');
      expect(locations.first.coordinates, const LatLng(3.2, 101.8));
      expect(locations.last.name, 'Office');
      expect(locations.last.address, 'Office address');
      await service.save(
          name: 'Campus',
          address: 'Campus address',
          coordinates: const LatLng(2.9, 101.7),
          isHome: false,
          id: 'office');
      locations = await service.load();
      expect(locations, hasLength(2));
      expect(locations.last.name, 'Campus');
      await service.delete('office');
      expect((await service.load()).single.id, 'home');
      expect(database.records, isEmpty);
      expect(database.deleted, isEmpty);
    });

    test('ignores corrupt local entries without losing valid pins', () async {
      SharedPreferences.setMockInitialValues({
        'guest_saved_locations_v1': [
          'invalid JSON',
          jsonEncode({'id': 'broken', 'name': 'Missing coordinates'}),
          jsonEncode({'id': 'campus', ...locationMap()}),
          jsonEncode({'id': 'home', ...locationMap(home: true)}),
          jsonEncode({'id': 'home', ...locationMap(home: true)}),
        ],
      });
      final service =
          SavedLocationService(auth: _Auth(null), firestore: _Firestore());
      final locations = await service.load();
      expect(locations.map((place) => place.id), ['home', 'campus']);
      expect(locations.where((place) => place.isHome), hasLength(1));
    });
  });

  test('cloud load/save/delete use the currently authenticated owner path',
      () async {
    final database = _Firestore();
    final auth = _Auth(_User('alice'));
    final service = SavedLocationService(auth: auth, firestore: database);
    await service.save(
        name: 'Home',
        address: 'Alice home',
        coordinates: const LatLng(3.1, 101.7),
        isHome: true);
    expect(database.records.keys, ['users/alice/savedLocations/home']);
    expect((await service.load()).single.address, 'Alice home');

    auth.currentUser = _User('bob');
    expect(await service.load(), isEmpty);
    await service.save(
        name: 'Campus',
        address: 'Bob campus',
        coordinates: const LatLng(2.9, 101.7),
        isHome: false,
        id: 'campus');
    expect(database.records.keys, contains('users/bob/savedLocations/campus'));
    expect((await service.load()).single.address, 'Bob campus');
    await service.delete('campus');
    expect(database.deleted, ['users/bob/savedLocations/campus']);
    expect(database.records.keys, ['users/alice/savedLocations/home']);
  });
}
````

## File: test/saved_search_access_test.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/services/saved_search_service.dart';

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.currentUser);
  @override
  final User? currentUser;
}

class _User extends Fake implements User {
  _User(this.isAnonymous, this.emailVerified);
  @override
  final bool isAnonymous;
  @override
  final bool emailVerified;
}

class _Database extends Fake implements FirebaseFirestore {}

void main() {
  test(
      'saved searches reject signed-out, guest and unverified users before accessing data',
      () async {
    for (final user in <User?>[null, _User(true, false), _User(false, false)]) {
      final service =
          SavedSearchService(auth: _Auth(user), firestore: _Database());
      await expectLater(service.load(), throwsStateError);
      await expectLater(service.save('My burgers', {}), throwsStateError);
      expect(() => service.remove('search'), throwsStateError);
    }
  });
}
````

## File: test/show_all_dishes_regression_test.dart
````dart
// Read-only Firebase platform fakes exercise the real stall-details widget.
// The interfaces are already installed FlutterFire dependencies; no package is added.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/customer/vendor_details/vendor_details_screen.dart';

class _SignedOutAuth extends FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;
  @override
  FirebaseAuthPlatform setInitialValues(
          {PigeonUserDetails? currentUser, String? languageCode}) =>
      this;
  @override
  UserPlatform? get currentUser => null;
}

class _ReadOnlyFirestore extends FirebaseFirestorePlatform {
  _ReadOnlyFirestore() {
    menu = StreamController<QuerySnapshotPlatform>.broadcast(
        onListen: () => menuListens++, onCancel: () => menuCancels++);
    reviews = StreamController<QuerySnapshotPlatform>.broadcast(
        onListen: () => reviewListens++, onCancel: () => reviewCancels++);
  }
  late final StreamController<QuerySnapshotPlatform> menu;
  late final StreamController<QuerySnapshotPlatform> reviews;
  int menuListens = 0, menuCancels = 0, reviewListens = 0, reviewCancels = 0;
  @override
  FirebaseFirestorePlatform delegateFor(
          {required FirebaseApp app, required String databaseId}) =>
      this;
  @override
  CollectionReferencePlatform collection(String path) =>
      _ReadOnlyCollection(this, path);
  @override
  DocumentReferencePlatform doc(String path) => _ReadOnlyDocument(this, path);
  QuerySnapshotPlatform snapshot(
          String collectionPath, List<Map<String, Object?>> data) =>
      QuerySnapshotPlatform([
        for (var index = 0; index < data.length; index++)
          DocumentSnapshotPlatform(
              this,
              '$collectionPath/item-$index',
              data[index],
              PigeonSnapshotMetadata(
                  hasPendingWrites: false, isFromCache: true)),
      ], [], SnapshotMetadataPlatform(false, true));
  Future<void> close() async {
    await menu.close();
    await reviews.close();
  }
}

class _ReadOnlyCollection extends CollectionReferencePlatform {
  _ReadOnlyCollection(this.owner, String path) : super(owner, path);
  final _ReadOnlyFirestore owner;
  @override
  DocumentReferencePlatform doc([String? path]) =>
      owner.doc('${this.path}/${path ?? 'generated'}');
  @override
  Stream<QuerySnapshotPlatform> snapshots(
          {bool includeMetadataChanges = false,
          ServerTimestampBehavior serverTimestampBehavior =
              ServerTimestampBehavior.none,
          required ListenSource listenSource}) =>
      path.endsWith('/menu') ? owner.menu.stream : owner.reviews.stream;
}

class _ReadOnlyDocument extends DocumentReferencePlatform {
  _ReadOnlyDocument(super.firestore, super.path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  final firestore = _ReadOnlyFirestore();
  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = _SignedOutAuth();
    FirebaseFirestorePlatform.instance = firestore;
  });
  tearDownAll(firestore.close);
  for (final width in [390.0, 960.0]) {
    testWidgets('Show all dishes keeps the loaded menu and reviews at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });
      firestore.menuListens = 0;
      firestore.menuCancels = 0;
      firestore.reviewListens = 0;
      firestore.reviewCancels = 0;
      final vendor = VendorModel(
          vendorId: 'seller',
          stallName: 'Burger Pak Ali',
          description: 'Fresh burgers',
          category: 'Burger',
          openingHours: '9 AM – 5 PM');
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: VendorDetailsScreen(
              vendor: vendor,
              initialDishId: 'item-0',
              previewOnly: true,
              draftPreview: true)));
      await tester.pump();
      // A live broadcast emits once. No future database update should be needed
      // merely to remove the selected-dish filter and reveal cached dishes.
      firestore.menu.add(firestore.snapshot('vendors/seller/menu', [
        {
          'name': 'Beef burger',
          'price': 8.0,
          'status': 'available',
          'section': 'Burgers'
        },
        {
          'name': 'Chicken burger',
          'price': 7.0,
          'status': 'available',
          'section': 'Burgers'
        },
      ]));
      firestore.reviews.add(firestore.snapshot('stallReviews/seller/entries', [
        {
          'customerName': 'Aina',
          'rating': 4,
          'text': 'Customer feedback remains visible',
          'photoUrls': <String>[]
        },
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Beef burger'), findsOneWidget);
      expect(find.text('Chicken burger'), findsNothing);
      expect(find.text('Customer feedback remains visible'), findsOneWidget);
      expect(firestore.menuListens, 1);
      expect(firestore.reviewListens, 1);
      await tester.ensureVisible(find.text('Show all dishes'));
      await tester.tap(find.text('Show all dishes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Chicken burger'), findsOneWidget,
          reason:
              'Clearing a local filter must reveal already-loaded dishes without another server event.');
      expect(find.text('Beef burger'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Customer feedback remains visible'), findsOneWidget);
      expect(firestore.menuListens, 1);
      expect(firestore.menuCancels, 0);
      expect(firestore.reviewListens, 1);
      expect(firestore.reviewCancels, 0);
      // The preserved subscription must still accept real menu updates.
      firestore.menu.add(firestore.snapshot('vendors/seller/menu', [
        {
          'name': 'Beef burger',
          'price': 8.0,
          'status': 'available',
          'section': 'Burgers'
        },
        {
          'name': 'Chicken burger',
          'price': 7.0,
          'status': 'available',
          'section': 'Burgers'
        },
        {
          'name': 'Fish burger',
          'price': 9.0,
          'status': 'available',
          'section': 'Burgers'
        },
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Fish burger'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
````

## File: test/unsaved_stall_changes_guard_test.dart
````dart
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
````

## File: test/vendor_reviews_test.dart
````dart
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
````

## File: lib/core/constants/firestore_collections.dart
````dart
class FirestoreCollections {
  static const String users = 'users';
  static const String vendors = 'vendors';
  static const String menus = 'menus';
  static const String follows = 'follows';
}
````

## File: lib/core/models/dish_search_entry.dart
````dart
import 'menu_item_model.dart';

class DishSearchEntry {
  const DishSearchEntry({
    required this.vendorId,
    required this.item,
    this.priceIsKnown = true,
  });

  final String vendorId;
  final MenuItemModel item;
  // Older menu records may not contain a price. Their model fallback of zero
  // must not make them appear as free dishes in a price filter.
  final bool priceIsKnown;
}
````

## File: lib/core/models/stall_review.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;

class VendorReviewReply {
  const VendorReviewReply({
    required this.text,
    this.createdAt,
    this.updatedAt,
    this.reviewUpdatedAt,
    this.edited = false,
  });
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewUpdatedAt;
  final bool edited;
  factory VendorReviewReply.fromMap(Map<String, dynamic> map) =>
      VendorReviewReply(
        text: map['text'] is String ? map['text'] as String : '',
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
        reviewUpdatedAt: _date(map['reviewUpdatedAt']),
        edited: map['edited'] == true,
      );
}

class StallReview {
  const StallReview({
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.text,
    required this.photoUrls,
    this.customerAvatarUrl = '',
    this.createdAt,
    this.updatedAt,
    this.edited = false,
    this.vendorReply,
  });
  final String customerId;
  final String customerName;
  final String customerAvatarUrl;
  final int rating;
  final String text;
  final List<String> photoUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool edited;
  final VendorReviewReply? vendorReply;
  bool get hasReply => vendorReply?.text.trim().isNotEmpty == true;
  DateTime? get postedAt => createdAt ?? updatedAt;
  bool get updatedAfterReply {
    final answeredVersion =
        vendorReply?.reviewUpdatedAt ?? vendorReply?.updatedAt;
    return hasReply &&
        updatedAt != null &&
        answeredVersion != null &&
        updatedAt!.isAfter(answeredVersion);
  }

  factory StallReview.fromMap(Map<String, dynamic> map, String id) =>
      StallReview(
        customerId: id,
        customerName: map['customerName'] is String &&
                (map['customerName'] as String).trim().isNotEmpty
            ? map['customerName'] as String
            : 'Customer',
        customerAvatarUrl: map['customerAvatarUrl'] is String
            ? map['customerAvatarUrl'] as String
            : '',
        rating: map['rating'] is int ? (map['rating'] as int).clamp(1, 5) : 1,
        text: map['text'] is String ? map['text'] as String : '',
        photoUrls: map['photoUrls'] is List
            ? (map['photoUrls'] as List).whereType<String>().take(5).toList()
            : const [],
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
        edited: map['edited'] == true,
        vendorReply: map['vendorReply'] is Map
            ? VendorReviewReply.fromMap(
                Map<String, dynamic>.from(map['vendorReply'] as Map),
              )
            : null,
      );
}

class StallReviewSummary {
  StallReviewSummary(List<StallReview> reviews)
      : total = reviews.length,
        unanswered = reviews.where((review) => !review.hasReply).length,
        updated = reviews.where((review) => review.updatedAfterReply).length,
        average = reviews.isEmpty
            ? null
            : reviews.fold<int>(0, (total, review) => total + review.rating) /
                reviews.length;
  final int total;
  final int unanswered;
  final int updated;
  final double? average;
}
````

## File: lib/core/models/stall_schedule.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Calendar fields in Malaysia, independent of the phone's time zone.
DateTime malaysiaTime(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 8));

DateTime malaysiaInstant(int year, int month, int day, int hour, int minute) =>
    DateTime.utc(year, month, day, hour, minute)
        .subtract(const Duration(hours: 8));

/// True when any scheduled serving time remains in this window after closures.
bool hasScheduledOpening(DateTime start, DateTime end,
    Map<int, List<StallHoursInterval>> hours, List<TemporaryClosure> closures) {
  if (!end.isAfter(start) || hours.isEmpty) return false;
  final first = malaysiaTime(start);
  final last = malaysiaTime(end);
  var day = DateTime.utc(first.year, first.month, first.day)
      .subtract(const Duration(days: 1));
  final lastDay = DateTime.utc(last.year, last.month, last.day);
  while (!day.isAfter(lastDay)) {
    final midnight = malaysiaInstant(day.year, day.month, day.day, 0, 0);
    for (final interval in hours[day.weekday] ?? <StallHoursInterval>[]) {
      var open = midnight.add(Duration(minutes: interval.openMinute));
      var close = midnight.add(Duration(
          minutes: interval.closeMinute +
              (interval.closeMinute < interval.openMinute ? 1440 : 0)));
      if (open.isBefore(start)) open = start;
      if (close.isAfter(end)) close = end;
      if (!close.isAfter(open)) continue;
      var available = <TemporaryClosure>[TemporaryClosure(open, close)];
      for (final closure in closures) {
        final remaining = <TemporaryClosure>[];
        for (final segment in available) {
          if (!closure.end.isAfter(segment.start) ||
              !closure.start.isBefore(segment.end)) {
            remaining.add(segment);
          } else {
            if (closure.start.isAfter(segment.start)) {
              remaining.add(TemporaryClosure(segment.start, closure.start));
            }
            if (closure.end.isBefore(segment.end)) {
              remaining.add(TemporaryClosure(closure.end, segment.end));
            }
          }
        }
        available = remaining;
      }
      if (available.isNotEmpty) return true;
    }
    day = day.add(const Duration(days: 1));
  }
  return false;
}

bool isWithinStallSchedule(DateTime instant,
    Map<int, List<StallHoursInterval>> hours, List<TemporaryClosure> closures) {
  if (hours.isEmpty || closures.any((closure) => closure.contains(instant))) {
    return false;
  }
  final local = malaysiaTime(instant);
  final minute = local.hour * 60 + local.minute;
  for (final interval in hours[local.weekday] ?? <StallHoursInterval>[]) {
    if (interval.closeMinute > interval.openMinute) {
      if (minute >= interval.openMinute && minute < interval.closeMinute) {
        return true;
      }
    } else if (minute >= interval.openMinute) {
      return true;
    }
  }
  final previousDay = local.weekday == 1 ? 7 : local.weekday - 1;
  return (hours[previousDay] ?? <StallHoursInterval>[]).any((interval) =>
      interval.closeMinute < interval.openMinute &&
      minute < interval.closeMinute);
}

/// Weekly hours use Monday=1 through Sunday=7 and minutes after midnight.
class StallHoursInterval {
  const StallHoursInterval(this.openMinute, this.closeMinute);
  final int openMinute;
  final int closeMinute;

  Map<String, int> toMap() => {'open': openMinute, 'close': closeMinute};

  static StallHoursInterval? fromMap(Object? value) {
    if (value is! Map) return null;
    final open = value['open'];
    final close = value['close'];
    if (open is! int ||
        close is! int ||
        open < 0 ||
        open >= 1440 ||
        close < 0 ||
        close >= 1440 ||
        open == close) {
      return null;
    }
    return StallHoursInterval(open, close);
  }
}

class TemporaryClosure {
  const TemporaryClosure(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
  Map<String, Timestamp> toMap() => {
        'startAt': Timestamp.fromDate(start.toUtc()),
        'endAt': Timestamp.fromDate(end.toUtc()),
      };

  static TemporaryClosure? fromMap(Object? value) {
    if (value is! Map) return null;
    final start = value['startAt'];
    final end = value['endAt'];
    if (start is! Timestamp || end is! Timestamp) return null;
    final result = TemporaryClosure(start.toDate(), end.toDate());
    return result.end.isAfter(result.start) ? result : null;
  }
}

Map<int, List<StallHoursInterval>> parseWeeklyHours(Object? value) {
  if (value is! Map) return {};
  final result = <int, List<StallHoursInterval>>{};
  for (var day = 1; day <= 7; day++) {
    final raw = value['$day'];
    if (raw is List) {
      result[day] = raw
          .map(StallHoursInterval.fromMap)
          .whereType<StallHoursInterval>()
          .toList();
    }
  }
  return result;
}

Map<String, List<Map<String, int>>> serializeWeeklyHours(
        Map<int, List<StallHoursInterval>> hours) =>
    {
      for (var day = 1; day <= 7; day++)
        '$day': (hours[day] ?? []).map((interval) => interval.toMap()).toList(),
    };

String formatStallTime(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour < 12 ? 'AM' : 'PM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}
````

## File: lib/core/services/dish_search_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dish_search_entry.dart';
import '../models/menu_item_model.dart';

class DishSearchService {
  DishSearchService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<DishSearchEntry>> watchAllDishes() {
    return _db.collectionGroup('menu').snapshots().map((snapshot) {
      final dishes = <DishSearchEntry>[];
      for (final document in snapshot.docs) {
        final vendorId = document.reference.parent.parent?.id;
        if (vendorId == null || vendorId.isEmpty) continue;
        final data = document.data();
        final price = data['price'];
        dishes.add(DishSearchEntry(
          vendorId: vendorId,
          item: MenuItemModel.fromMap(
              {...data, 'price': price is num ? price : 0}, document.id),
          priceIsKnown: price is num && price.isFinite && price >= 0,
        ));
      }
      dishes.sort((a, b) =>
          a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase()));
      return dishes;
    });
  }
}
````

## File: lib/core/services/local_demo_booking_service.dart
````dart
import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/demo_order.dart';
import '../models/vendor_model.dart';

/// Device-only self-collect bookings for the prototype APK.
/// Nothing here sends a booking to another phone or charges a customer.
class LocalDemoBookingService {
  LocalDemoBookingService({String? actorId}) : _testActorId = actorId;

  static const _bookingsKey = 'self_collect_bookings_v1';
  static const _enabledPrefix = 'self_collect_enabled_v1_';
  static final _changed = StreamController<void>.broadcast();

  final String? _testActorId;

  String? get _actorId =>
      _testActorId ?? FirebaseAuth.instance.currentUser?.uid;

  Future<bool> isSelfCollectEnabled(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_enabledPrefix$vendorId') ?? false;
  }

  Future<void> setSelfCollectEnabled(String vendorId, bool enabled) async {
    if (_actorId != vendorId) throw StateError('Vendor account required.');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool('$_enabledPrefix$vendorId', enabled)) {
      throw StateError('Could not save booking preference.');
    }
    _changed.add(null);
  }

  Stream<List<DemoOrder>> watchCustomerOrders(String customerId) =>
      _watch((booking) => booking.customerId == customerId);

  Stream<List<DemoOrder>> watchVendorOrders(String vendorId) =>
      _watch((booking) => booking.vendorId == vendorId);

  Stream<List<DemoOrder>> _watch(bool Function(DemoOrder) include) async* {
    Future<List<DemoOrder>> current() async {
      final bookings = (await _load()).where(include).toList();
      bookings.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return bookings;
    }

    yield await current();
    yield* _changed.stream.asyncMap((_) => current());
  }

  Future<String> requestOrder(VendorModel vendor, List<DemoOrderItem> items,
      {String? customerName, String specialInstructions = ''}) async {
    final customerId = _actorId;
    if (customerId == null || customerId == vendor.vendorId) {
      throw StateError('Customer account required.');
    }
    if (!await isSelfCollectEnabled(vendor.vendorId)) {
      throw StateError('Self-collect booking is unavailable.');
    }
    if (items.isEmpty || items.any((item) => item.quantity < 1)) {
      throw ArgumentError('Choose at least one dish.');
    }
    final user =
        _testActorId == null ? FirebaseAuth.instance.currentUser : null;
    final name = customerName?.trim().isNotEmpty == true
        ? customerName!.trim()
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : user?.email?.split('@').first ?? 'Customer');
    final now = DateTime.now();
    final booking = DemoOrder(
      id: '${now.microsecondsSinceEpoch}_$customerId',
      customerId: customerId,
      vendorId: vendor.vendorId,
      customerName: name,
      stallName: vendor.stallName,
      status: 'requested',
      items: items,
      totalCents: items.fold(0, (sum, item) => sum + item.subtotalCents),
      createdAt: now,
      specialInstructions: specialInstructions.trim(),
      pickupLatitude: vendor.hasValidLocation ? vendor.latitude : null,
      pickupLongitude: vendor.hasValidLocation ? vendor.longitude : null,
    );
    final bookings = await _load();
    bookings.insert(0, booking);
    await _save(bookings);
    return booking.id;
  }

  Future<void> removeAccountData(String accountId) async {
    final bookings = await _load();
    await _save(bookings
        .where((booking) =>
            booking.customerId != accountId && booking.vendorId != accountId)
        .toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_enabledPrefix$accountId');
  }

  Future<void> respond(String bookingId, {required bool accept}) =>
      _update(bookingId, (booking) {
        if (_actorId != booking.vendorId ||
            booking.effectiveStatus != 'requested') {
          throw StateError('This booking can no longer be answered.');
        }
        return booking.withStatus(accept ? 'confirmed' : 'rejected');
      });

  Future<void> advance(String bookingId) => _update(bookingId, (booking) {
        if (_actorId != booking.vendorId) {
          throw StateError('Vendor account required.');
        }
        final next = switch (booking.effectiveStatus) {
          'confirmed' => 'preparing',
          'preparing' => 'ready',
          'ready' => 'collected',
          _ => null,
        };
        if (next == null) throw StateError('This booking cannot advance.');
        return booking.withStatus(next);
      });

  Future<void> cancel(String bookingId) => _update(bookingId, (booking) {
        final status = booking.effectiveStatus;
        final customerCanCancel =
            _actorId == booking.customerId && status == 'requested';
        final vendorCanCancel = _actorId == booking.vendorId &&
            {'requested', 'confirmed', 'preparing', 'ready'}.contains(status);
        if (!customerCanCancel && !vendorCanCancel) {
          throw StateError('This booking cannot be cancelled.');
        }
        return booking.withStatus('cancelled');
      });

  Future<void> _update(
      String bookingId, DemoOrder Function(DemoOrder) change) async {
    final bookings = await _load();
    final index = bookings.indexWhere((booking) => booking.id == bookingId);
    if (index < 0) throw StateError('Booking not found on this device.');
    bookings[index] = change(bookings[index]);
    await _save(bookings);
  }

  Future<List<DemoOrder>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bookingsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => DemoOrder.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _save(List<DemoOrder> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_bookingsKey,
        jsonEncode(bookings.map((booking) => booking.toMap()).toList()))) {
      throw StateError('Could not save booking on this device.');
    }
    _changed.add(null);
  }
}
````

## File: lib/core/services/notification_history_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

/// The server creates history records. Clients can read their own records
/// and mark them read, but cannot invent or edit alert content.
class NotificationHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<List<NotificationModel>> watch(String uid,
          {int limit = 50}) =>
      _inbox(uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList());

  // Cap the badge query; the UI displays 99+ rather than a misleading exact count.
  Stream<int> watchUnreadCount(String uid) => _inbox(uid)
      .where('isRead', isEqualTo: false)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  Future<void> markRead(String uid, String notificationId) async {
    _requireOwner(uid);
    await _inbox(uid)
        .doc(notificationId)
        .update({'isRead': true}).timeout(const Duration(seconds: 10));
  }

  Future<void> remove(String uid, String notificationId) async {
    _requireOwner(uid);
    await _inbox(uid)
        .doc(notificationId)
        .delete()
        .timeout(const Duration(seconds: 10));
  }

  /// Marks only the records the screen displayed. A new alert arriving during
  /// this operation remains unread, and writes stay below the batch limit.
  Future<void> markDisplayedRead(
      String uid, Iterable<NotificationModel> items) async {
    _requireOwner(uid);
    final ids = items
        .where((item) => !item.isRead)
        .map((item) => item.id)
        .toSet()
        .toList();
    for (var start = 0; start < ids.length; start += 400) {
      _requireOwner(uid);
      final batch = _db.batch();
      for (final id in ids.skip(start).take(400)) {
        batch.update(_inbox(uid).doc(id), {'isRead': true});
      }
      await batch.commit().timeout(const Duration(seconds: 10));
    }
  }

  void _requireOwner(String uid) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError('Sign in to read your notifications.');
    }
  }
}
````

## File: lib/core/services/search_history_service.dart
````dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  SearchHistoryService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  static const _guestKey = 'guest_search_history_v1';
  static const _limit = 10;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  bool get _usesLocalHistory {
    final user = _auth.currentUser;
    return user == null || user.isAnonymous;
  }

  Future<List<String>> loadRecent() async {
    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      return (preferences.getStringList(_guestKey) ?? const <String>[])
          .take(_limit)
          .toList();
    }

    final uid = _auth.currentUser!.uid;
    final snapshot = await _history(uid)
        .orderBy('searchedAt', descending: true)
        .limit(_limit)
        .get();
    return snapshot.docs
        .map((document) => document.data()['query'])
        .whereType<String>()
        .where((query) => query.trim().isNotEmpty)
        .toList();
  }

  /// Retry-safe: the local copy is removed only after every account write succeeds.
  Future<void> mergeGuestHistoryIntoCustomerAccount() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) return;
    final preferences = await SharedPreferences.getInstance();
    final guest = preferences.getStringList(_guestKey) ?? const <String>[];
    if (guest.isEmpty) return;
    final account = await loadRecent();
    final seen = <String>{};
    final merged = <String>[];
    for (final raw in [...guest, ...account]) {
      final query = _clean(raw);
      if (query.isNotEmpty && seen.add(query.toLowerCase())) {
        merged.add(query);
      }
      if (merged.length == _limit) break;
    }
    for (final query in merged.reversed) {
      if (_auth.currentUser?.uid != user.uid) return;
      await save(query);
    }
    if (_auth.currentUser?.uid == user.uid) {
      await preferences.remove(_guestKey);
    }
  }

  Future<void> save(String rawQuery) async {
    final query = _clean(rawQuery);
    if (query.isEmpty) return;

    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      final recent = preferences.getStringList(_guestKey) ?? <String>[];
      final normalized = query.toLowerCase();
      recent.removeWhere((item) => item.toLowerCase() == normalized);
      recent.insert(0, query);
      await preferences.setStringList(_guestKey, recent.take(_limit).toList());
      return;
    }

    final uid = _auth.currentUser!.uid;
    await _history(uid).doc(_documentId(query)).set({
      'query': query,
      'normalizedQuery': query.toLowerCase(),
      'searchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String rawQuery) async {
    final query = _clean(rawQuery);
    if (query.isEmpty) return;
    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      final recent = preferences.getStringList(_guestKey) ?? <String>[];
      recent.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      await preferences.setStringList(_guestKey, recent);
      return;
    }
    await _history(_auth.currentUser!.uid).doc(_documentId(query)).delete();
  }

  Future<void> clear() async {
    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_guestKey);
      return;
    }
    final snapshot = await _history(_auth.currentUser!.uid).get();
    final batch = _db.batch();
    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      _db.collection('users').doc(uid).collection('searchHistory');

  String _clean(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.length <= 100 ? cleaned : cleaned.substring(0, 100);
  }

  String _documentId(String query) =>
      base64Url.encode(utf8.encode(query.toLowerCase())).replaceAll('=', '');
}
````

## File: lib/core/services/stall_review_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stall_review.dart';

class StallReviewService {
  StallReviewService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  DocumentReference<Map<String, dynamic>> _review(
    String vendorId,
    String customerId,
  ) => _db
      .collection('stallReviews')
      .doc(vendorId)
      .collection('entries')
      .doc(customerId);

  Stream<List<StallReview>> watchReviews(String vendorId) => _db
      .collection('stallReviews')
      .doc(vendorId)
      .collection('entries')
      .snapshots()
      .map((snapshot) {
        final reviews = snapshot.docs
            .map((doc) => StallReview.fromMap(doc.data(), doc.id))
            .toList();
        reviews.sort(
          (a, b) =>
              (b.postedAt ?? DateTime(0)).compareTo(a.postedAt ?? DateTime(0)),
        );
        return reviews;
      });

  Future<void> saveReview(
    String vendorId,
    String customerId,
    String customerName,
    int rating,
    String text,
    List<String> photoUrls, {
    String customerAvatarUrl = '',
  }) async {
    if (rating < 1 ||
        rating > 5 ||
        photoUrls.length > 5 ||
        text.trim().length > 1000) {
      throw ArgumentError('Invalid review');
    }
    final ref = _review(vendorId, customerId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final old = snapshot.data();
      final name = customerName.trim().isEmpty
          ? 'Customer'
          : customerName.trim();
      // Merge only customer fields. A concurrent owner reply is never replaced.
      transaction.set(ref, {
        'customerId': customerId,
        'customerName': name.length > 80 ? name.substring(0, 80) : name,
        'customerAvatarUrl':
            customerAvatarUrl.startsWith('https://') &&
                customerAvatarUrl.length <= 2048
            ? customerAvatarUrl
            : '',
        'rating': rating,
        'text': text.trim(),
        'photoUrls': photoUrls,
        'createdAt':
            old?['createdAt'] ??
            old?['updatedAt'] ??
            FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'edited': snapshot.exists,
      }, SetOptions(merge: true));
    });
  }

  Future<void> saveVendorReply(
    String vendorId,
    StallReview review,
    String text,
  ) async {
    final reply = text.trim();
    if (reply.isEmpty || reply.length > 1000) {
      throw ArgumentError('Enter a reply between 1 and 1,000 characters.');
    }
    final ref = _review(vendorId, review.customerId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('This review was deleted.');
      final data = snapshot.data()!;
      final old = data['vendorReply'] is Map
          ? data['vendorReply'] as Map
          : null;
      // Record the version visible in the editor. If the customer edited while
      // the editor was open, the updated-after-reply indicator remains visible.
      transaction.update(ref, {
        'vendorReply': {
          'text': reply,
          'createdAt': old?['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'edited': old != null,
          'reviewUpdatedAt': review.updatedAt == null
              ? data['updatedAt']
              : Timestamp.fromDate(review.updatedAt!),
        },
      });
    });
  }

  Future<void> deleteVendorReply(String vendorId, String customerId) => _review(
    vendorId,
    customerId,
  ).update({'vendorReply': FieldValue.delete()});

  // The single reply belongs to the same document and disappears atomically.
  Future<void> deleteReview(String vendorId, String customerId) =>
      _review(vendorId, customerId).delete();
}
````

## File: lib/core/services/vendor_location_service.dart
````dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Shares an open vendor's location, including while the app is backgrounded.
/// Android keeps the stream alive with a visible foreground-service
/// notification; iOS uses the location background mode.
class VendorLocationService extends ChangeNotifier {
  VendorLocationService._();
  static final instance = VendorLocationService._();
  StreamSubscription<Position>? _positionSubscription;
  Future<void> _writes = Future<void>.value();
  String? _vendorId;
  int _generation = 0;
  String? error;
  bool get isSharing => _vendorId != null;

  Future<void> _operations = Future<void>.value();
  int _request = 0;

  Future<void> start(String vendorId) {
    final request = ++_request;
    _operations = _operations.catchError((Object _) {}).then((_) async {
      await _pause();
      if (request != _request ||
          FirebaseAuth.instance.currentUser?.uid != vendorId) {
        return;
      }
      _vendorId = vendorId;
      error = null;
      final generation = ++_generation;
      notifyListeners();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings(),
      ).listen(
        (position) => _queuePosition(vendorId, generation, position),
        onError: (Object _) {
          if (generation == _generation) {
            error = 'Location could not update. Check GPS and your connection.';
            notifyListeners();
          }
        },
      );
    });
    return _operations;
  }

  Future<void> pause() {
    ++_request;
    ++_generation;
    _operations = _operations.catchError((Object _) {}).then((_) => _pause());
    return _operations;
  }

  LocationSettings _locationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 15),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Stall location sharing is active',
          notificationText:
              'Customers can see your location while your stall is open.',
          notificationChannelName: 'Stall location sharing',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  void _queuePosition(String vendorId, int generation, Position position) {
    _writes = _writes.catchError((Object _) {}).then(
          (_) => _writePosition(vendorId, generation, position),
        );
  }

  Future<void> _writePosition(
      String vendorId, int generation, Position position) async {
    try {
      if (generation != _generation ||
          FirebaseAuth.instance.currentUser?.uid != vendorId) {
        return;
      }
      final ref =
          FirebaseFirestore.instance.collection('vendors').doc(vendorId);
      // Do not reopen a stall closed by another screen/device.
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = await tx.get(ref);
        if (generation != _generation || doc.data()?['isOpen'] != true) {
          return;
        }
        tx.update(ref, {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
          'locationSharingActive': true,
        });
      }).timeout(const Duration(seconds: 8));
      if (generation == _generation) {
        error = null;
      }
    } catch (_) {
      if (generation == _generation) {
        error = 'Location could not update. Check GPS and your connection.';
      }
    }
    if (generation == _generation) {
      notifyListeners();
    }
  }

  Future<void> _pause() async {
    ++_generation;
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
    final id = _vendorId;
    _vendorId = null;
    // Finish queued writes before writing the paused state.
    await _writes.catchError((Object _) {});
    if (id != null && FirebaseAuth.instance.currentUser?.uid == id) {
      try {
        await FirebaseFirestore.instance.collection('vendors').doc(id).update({
          'locationSharingActive': false,
        }).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Customers also expire old timestamps if this device is offline/killed.
      }
    }
    notifyListeners();
  }
}
````

## File: lib/core/widgets/app_dropdown.dart
````dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.hint = 'Select an option',
    this.displayText,
    this.icon,
    this.width,
    this.compact = false,
    this.iconOnly = false,
  });

  final Map<T, String> options;
  final ValueChanged<T>? onChanged;
  final T? value;
  final String? label;
  final String hint;
  final String? displayText;
  final IconData? icon;
  final double? width;
  final bool compact;
  final bool iconOnly;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _open = false;

  static const _accent = AppColors.primary;

  void _setOpen(bool value) {
    if (mounted && _open != value) {
      setState(() => _open = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth =
            math.max(48.0, MediaQuery.sizeOf(context).width - 32);

        final buttonWidth = widget.iconOnly
            ? 48.0
            : math.min(
                widget.width ??
                    (constraints.hasBoundedWidth
                        ? constraints.maxWidth
                        : 180.0),
                screenWidth,
              );

        final menuWidth =
            widget.iconOnly ? math.min(260.0, screenWidth) : buttonWidth;

        final enabled = widget.onChanged != null;
        final text =
            widget.displayText ?? widget.options[widget.value] ?? widget.hint;

        return SizedBox(
          width: buttonWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: const Color(0xFFF3F4F6),
                  focusColor: const Color(0xFFF3F4F6),
                  highlightColor: const Color(0xFFF3F4F6),
                ),
                child: PopupMenuButton<T>(
                  enabled: enabled,
                  tooltip: widget.label ?? widget.hint,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 6),
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 8,
                  shadowColor: const Color(0x26000000),
                  menuPadding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  constraints: BoxConstraints(
                    minWidth: menuWidth,
                    maxWidth: menuWidth,
                    maxHeight: 280,
                  ),
                  onOpened: () => _setOpen(true),
                  onCanceled: () => _setOpen(false),
                  onSelected: (value) {
                    _setOpen(false);
                    widget.onChanged?.call(value);
                  },
                  itemBuilder: (_) {
                    return widget.options.entries.map((option) {
                      final selected = option.key == widget.value;

                      return PopupMenuItem<T>(
                        value: option.key,
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.value,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      selected ? _accent : AppColors.textDark,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_rounded,
                                  size: 19, color: _accent),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: SizedBox(
                    width: buttonWidth,
                    height: widget.iconOnly
                        ? 48
                        : widget.compact
                            ? 40
                            : 52,
                    child: widget.iconOnly
                        ? Icon(
                            widget.icon ?? Icons.more_vert,
                            size: 22,
                            color: !enabled
                                ? Colors.grey
                                : _open
                                    ? _accent
                                    : AppColors.textDark,
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: enabled
                                  ? Colors.white
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  if (widget.icon != null) ...[
                                    Icon(
                                      widget.icon,
                                      size: 18,
                                      color:
                                          _open ? _accent : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: widget.compact ? 12 : 14,
                                        color: enabled
                                            ? AppColors.textDark
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _open
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: enabled
                                        ? AppColors.textDark
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
````

## File: lib/features/auth/screens/email_verification_screen.dart
````dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  bool _isSending = false;
  bool _isChecking = false;
  bool _messageIsError = false;
  String? _message;
  Timer? _cooldownTimer;
  int _resendSeconds = 0;

  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendLink());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isSending && !_isChecking) {
      _checkVerification(quiet: true);
    }
  }

  Future<void> _sendLink() async {
    if (!mounted || _isSending || _isChecking || _resendSeconds > 0) return;
    setState(() {
      _isSending = true;
      _message = null;
    });
    final error = await _authService.sendEmailVerificationLink();
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _messageIsError = error != null;
      _message = error ?? 'Verification email sent to $_email.';
      if (error == null) _resendSeconds = 60;
    });
    if (error == null) _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _checkVerification({bool quiet = false}) async {
    if (_isChecking || _isSending) return;
    setState(() {
      _isChecking = true;
      if (!quiet) _message = null;
    });
    final error = await _authService.refreshEmailVerification();
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      if (!quiet || error == null) {
        _messageIsError = error != null;
        _message = error ?? 'Email verified successfully.';
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_unread_outlined,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 20),
                    Text('Verify your email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a verification link to $_email. Open the email, tap the link, then return here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _messageIsError
                                  ? Colors.red
                                  : Colors.green.shade700)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isChecking || _isSending
                          ? null
                          : () => _checkVerification(),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh),
                      label: Text(_isChecking
                          ? 'Checking…'
                          : 'I Have Verified My Email'),
                    ),
                    TextButton(
                      onPressed: _isSending || _isChecking || _resendSeconds > 0
                          ? null
                          : _sendLink,
                      child: Text(_isSending
                          ? 'Sending email…'
                          : _resendSeconds > 0
                              ? 'Resend in ${_resendSeconds}s'
                              : 'Resend verification email'),
                    ),
                    TextButton(
                      onPressed: _isChecking ? null : _authService.signOut,
                      child: const Text('Use a different account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/auth/screens/forgot_password_screen.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/account_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;
  bool _sent = false;
  String? _error;
  String _sentTo = '';
  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || _seconds > 0) {
      return;
    }
    if (!_sent && !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final address = _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await AuthService().resetPassword(email: address);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
      if (error == null) {
        _sent = true;
        _sentTo = address;
        _seconds = 60;
      }
    });
    if (error == null) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          }
        });
        if (_seconds == 0) {
          timer.cancel();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      AccountLayout(title: 'Forgot password', busy: _busy, children: [
        const SizedBox(height: 24),
        AccountIntro(
            icon: _sent
                ? Icons.mark_email_read_outlined
                : Icons.lock_reset_rounded,
            title: _sent ? 'Check your email' : 'Reset your password',
            body: _sent
                ? 'If an account uses $_sentTo, you will receive a link to reset its password.'
                : 'Enter the email address linked to your account. We will send you a reset link.'),
        if (!_sent) ...[
          Form(
              key: _form,
              child: TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  decoration: accountField('Email address'),
                  validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch((v ?? '').trim())
                      ? null
                      : 'Enter a valid email address.',
                  onFieldSubmitted: (_) => _send())),
          const SizedBox(height: 24),
          AccountError(_error),
          AccountButton(
              label: _seconds > 0
                  ? 'Send again in ${_seconds}s'
                  : 'Send reset link',
              busy: _busy,
              onPressed: _seconds > 0 ? null : _send),
          const SizedBox(height: 20),
          const Text(
              'Signed up with Google? Use Continue with Google to sign in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF707078), height: 1.5)),
        ] else ...[
          const Text(
              'Open the email and follow the link to choose a new password. Check Spam or Junk if it is missing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF707078), height: 1.5)),
          const SizedBox(height: 28),
          AccountError(_error),
          const SizedBox(height: 12),
          TextButton(
              onPressed: _busy || _seconds > 0 ? null : _send,
              child: Text(_busy
                  ? 'Sending…'
                  : _seconds > 0
                      ? 'Resend in ${_seconds}s'
                      : 'Resend email')),
          TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _sent = false;
                        _error = null;
                      }),
              child: const Text('Use another email')),
        ],
      ]);
}
````

## File: lib/features/customer/home/discovery_search_filters.dart
````dart
import 'discovery_options.dart';
import '../../../core/models/dish_search_entry.dart';
import '../../../core/models/vendor_model.dart';

String normalizeDiscoveryQuery(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

class MenuPriceRange {
  const MenuPriceRange({this.minimum, this.maximum});

  final double? minimum;
  final double? maximum;

  bool get isActive => minimum != null || maximum != null;

  bool contains(DishSearchEntry dish) =>
      dish.priceIsKnown &&
      dish.item.price.isFinite &&
      dish.item.price >= 0 &&
      (minimum == null || dish.item.price >= minimum!) &&
      (maximum == null || dish.item.price <= maximum!);

  String get label {
    String amount(double value) => value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    if (minimum != null && maximum != null) {
      return 'RM ${amount(minimum!)}–${amount(maximum!)}';
    }
    if (minimum != null) return 'RM ${amount(minimum!)}+';
    if (maximum != null) return 'Up to RM ${amount(maximum!)}';
    return 'Any price';
  }
}

/// For a dish query, the matching dish itself must meet the price range.
/// Stall/category queries can match any genuinely priced dish on that menu.
bool vendorMatchesQueryAndPrice({
  required VendorModel vendor,
  required Iterable<DishSearchEntry> dishes,
  required String query,
  MenuPriceRange? priceRange,
}) {
  final normalized = normalizeDiscoveryQuery(query);
  final vendorMatches = discoveryMatches(normalized, vendor.stallName) ||
      vendor.allCategories
          .any((category) => discoveryMatches(normalized, category));
  final matchingDishes = normalized.isEmpty
      ? dishes
      : dishes.where((dish) => discoveryMatches(normalized, dish.item.name));
  if (priceRange == null || !priceRange.isActive) {
    return normalized.isEmpty || vendorMatches || matchingDishes.isNotEmpty;
  }
  // Do not let a cheap unrelated menu item make an expensive dish match.
  if (matchingDishes.isNotEmpty) {
    return matchingDishes.any(priceRange.contains);
  }
  return vendorMatches && dishes.any(priceRange.contains);
}

enum DiscoverySuggestionKind { dish, stall, category, recent }

class DiscoverySuggestion {
  const DiscoverySuggestion({
    required this.label,
    required this.kind,
    this.isRecent = false,
  });

  final String label;
  final DiscoverySuggestionKind kind;
  final bool isRecent;

  String get detail => switch (kind) {
        DiscoverySuggestionKind.dish => 'Dish',
        DiscoverySuggestionKind.stall => 'Stall',
        DiscoverySuggestionKind.category => 'Category',
        DiscoverySuggestionKind.recent => 'Recent search',
      };
}

List<DiscoverySuggestion> buildDiscoverySuggestions({
  required String query,
  required Iterable<VendorModel> vendors,
  required Iterable<DishSearchEntry> dishes,
  required Iterable<String> categories,
  required List<String> recentSearches,
  MenuPriceRange? priceRange,
  int limit = 8,
}) {
  final typed = normalizeDiscoveryQuery(query);
  final recentKeys = recentSearches.map(normalizeDiscoveryQuery).toSet();
  final suggestions = <String, DiscoverySuggestion>{};

  void add(String rawLabel, DiscoverySuggestionKind kind) {
    final label = rawLabel.trim().replaceAll(RegExp(r'\s+'), ' ');
    final key = normalizeDiscoveryQuery(label);
    if (key.isEmpty || (typed.isNotEmpty && !discoveryMatches(typed, key))) {
      return;
    }
    final current = suggestions[key];
    if (current == null || kind.index < current.kind.index) {
      suggestions[key] = DiscoverySuggestion(
        label: label,
        kind: kind,
        isRecent: recentKeys.contains(key),
      );
    }
  }

  for (final recent in recentSearches) {
    add(recent, DiscoverySuggestionKind.recent);
  }
  if (typed.isEmpty) return suggestions.values.take(limit).toList();

  final vendorById = {
    for (final vendor in vendors) vendor.vendorId: vendor,
  };
  final eligibleDishes = dishes.where((dish) =>
      vendorById.containsKey(dish.vendorId) &&
      (priceRange == null ||
          !priceRange.isActive ||
          priceRange.contains(dish)));
  final pricedVendorIds = eligibleDishes.map((dish) => dish.vendorId).toSet();
  final eligibleVendors = vendorById.values.where((vendor) =>
      priceRange == null ||
      !priceRange.isActive ||
      pricedVendorIds.contains(vendor.vendorId));

  for (final dish in eligibleDishes) {
    add(dish.item.name, DiscoverySuggestionKind.dish);
  }
  for (final vendor in eligibleVendors) {
    add(vendor.stallName, DiscoverySuggestionKind.stall);
  }
  final offeredCategories = eligibleVendors
      .expand((vendor) => vendor.allCategories.map(normalizeDiscoveryQuery))
      .toSet();
  for (final category in categories) {
    if (offeredCategories.contains(normalizeDiscoveryQuery(category))) {
      add(category, DiscoverySuggestionKind.category);
    }
  }

  int matchRank(String label) {
    final normalized = normalizeDiscoveryQuery(label);
    if (normalized == typed) return 0;
    if (normalized.startsWith(typed)) return 1;
    if (normalized.split(' ').any((word) => word.startsWith(typed))) return 2;
    return 3;
  }

  final ranked = suggestions.values.toList()
    ..sort((a, b) {
      final matchOrder = matchRank(a.label).compareTo(matchRank(b.label));
      if (matchOrder != 0) return matchOrder;
      final sourceOrder = a.kind.index.compareTo(b.kind.index);
      if (sourceOrder != 0) return sourceOrder;
      if (a.kind == DiscoverySuggestionKind.recent) {
        return recentSearches
            .indexWhere((value) =>
                normalizeDiscoveryQuery(value) ==
                normalizeDiscoveryQuery(a.label))
            .compareTo(recentSearches.indexWhere((value) =>
                normalizeDiscoveryQuery(value) ==
                normalizeDiscoveryQuery(b.label)));
      }
      return normalizeDiscoveryQuery(a.label)
          .compareTo(normalizeDiscoveryQuery(b.label));
    });
  return ranked.take(limit).toList();
}
````

## File: lib/features/shared/change_password_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../auth/screens/forgot_password_screen.dart';
import 'account_ui.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.email});
  final String email;
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _hidden = [true, true, true];
  bool _busy = false;
  bool _saved = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    // Do not trim passwords: spaces may be intentional.
    final error = await AuthService()
        .changePassword(_next.text, currentPassword: _current.text);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
      _saved = error == null;
    });
    if (_saved) {
      _current.clear();
      _next.clear();
      _confirm.clear();
    }
  }

  Widget _field(String label, TextEditingController controller, int index,
          String? Function(String?) validator) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: TextFormField(
              controller: controller,
              enabled: !_busy,
              obscureText: _hidden[index],
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: [
                index == 0 ? AutofillHints.password : AutofillHints.newPassword
              ],
              textInputAction:
                  index == 2 ? TextInputAction.done : TextInputAction.next,
              onFieldSubmitted: index == 2 ? (_) => _save() : null,
              validator: validator,
              decoration: accountField(label,
                  suffix: IconButton(
                      tooltip:
                          _hidden[index] ? 'Show password' : 'Hide password',
                      onPressed: () =>
                          setState(() => _hidden[index] = !_hidden[index]),
                      icon: Icon(
                          _hidden[index]
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 21,
                          color: const Color(0xFF707078))))));

  @override
  Widget build(BuildContext context) => AccountLayout(
      title: 'Change password',
      busy: _busy,
      children: _saved
          ? [
              const SizedBox(height: 40),
              const AccountIntro(
                  icon: Icons.check_rounded,
                  title: 'Password changed',
                  body:
                      'Your new password is ready. Use it the next time you sign in.'),
            ]
          : [
              const AccountIntro(
                  icon: Icons.lock_outline_rounded,
                  title: 'Choose a new password',
                  body: 'Confirm your current password, then enter a new one.'),
              Form(
                  key: _form,
                  child: AutofillGroup(
                      child: Column(children: [
                    _field(
                        'Current password',
                        _current,
                        0,
                        (v) => (v ?? '').isEmpty
                            ? 'Enter your current password.'
                            : null),
                    _field('New password', _next, 1, (v) {
                      if ((v ?? '').length < 6) {
                        return 'Use at least 6 characters.';
                      }
                      if (v == _current.text) {
                        return 'Choose a different password.';
                      }
                      return null;
                    }),
                    _field(
                        'Confirm new password',
                        _confirm,
                        2,
                        (v) => v != _next.text
                            ? 'Your passwords do not match.'
                            : null),
                  ]))),
              const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                      'Use a long, unique password. Your account may require extra characters.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF707078),
                          height: 1.4))),
              AccountError(_error),
              AccountButton(
                  label: 'Update password', busy: _busy, onPressed: _save),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                  initialEmail: widget.email))),
                  child: const Text('Forgot your current password?')),
            ]);
}
````

## File: lib/features/shared/info_page.dart
````dart
import '../../core/widgets/app_page_app_bar.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tablet = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppPageAppBar(showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tablet ? 24 : 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 720,
                maxHeight: 900,
              ),
              child: SizedBox.expand(
                child: Material(
                  color: Colors.white,
                  elevation: tablet ? 4 : 0,
                  shadowColor: const Color(0x18000000),
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.textDark,
                          ),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              tablet ? 32 : 20,
                              12,
                              tablet ? 32 : 20,
                              28,
                            ),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: -.3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ...children,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/shared/live_booking_section.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import 'booking_detail_screen.dart';
import 'demo_orders_screen.dart';

class LiveBookingSection extends StatefulWidget {
  const LiveBookingSection({super.key, required this.isVendor});
  final bool isVendor;

  @override
  State<LiveBookingSection> createState() => _LiveBookingSectionState();
}

class _LiveBookingSectionState extends State<LiveBookingSection> {
  final _service = DemoOrderService();
  late final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<DemoOrder>> _bookings = widget.isVendor
      ? _service.watchVendorOrders(_uid)
      : _service.watchCustomerOrders(_uid);

  void _openAll() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DemoOrdersScreen(isVendor: widget.isVendor)));

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: StreamBuilder<List<DemoOrder>>(
            stream: _bookings,
            builder: (context, snapshot) {
              final active =
                  snapshot.data?.where((order) => order.isActive).toList() ??
                      const <DemoOrder>[];
              final unseen = (snapshot.data ?? const <DemoOrder>[])
                  .where((order) => widget.isVendor
                      ? order.effectiveStatus == 'requested' &&
                          order.vendorUnseenRequest
                      : order.customerUnseenReady)
                  .length;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.receipt_long_outlined),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text('Live bookings',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700))),
                      if (unseen > 0)
                        Badge(label: Text(unseen > 99 ? '99+' : '$unseen')),
                      TextButton(
                          onPressed: _openAll, child: const Text('View all')),
                    ]),
                    if (snapshot.hasError)
                      const Text(
                          'Could not load bookings. Check your connection.')
                    else if (!snapshot.hasData)
                      const LinearProgressIndicator()
                    else if (active.isEmpty)
                      Text(widget.isVendor
                          ? 'No active bookings.'
                          : 'No active bookings yet. Your progress will appear here.'),
                    for (final order in active.take(2))
                      BookingSummaryCard(
                        booking: order,
                        isVendor: widget.isVendor,
                        compact: true,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookingDetailScreen(
                                    bookingId: order.id,
                                    isVendor: widget.isVendor))),
                      ),
                    if (active.length > 2)
                      Text('${active.length - 2} more active bookings',
                          style: Theme.of(context).textTheme.bodySmall),
                  ]);
            },
          ),
        ),
      ),
    );
  }
}
````

## File: lib/features/shared/profile_header.dart
````dart
import 'package:flutter/cupertino.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_top_action.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(
      {super.key, required this.name, this.photoUrl, this.size = 100});

  final String name;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: photoUrl == null || photoUrl!.trim().isEmpty
              ? const ColoredBox(
                  color: AppColors.mint,
                  child: Icon(CupertinoIcons.person_fill,
                      size: 58, color: AppColors.primary),
                )
              : Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.mint,
                    child: Icon(CupertinoIcons.person_fill,
                        size: 58, color: AppColors.primary),
                  ),
                ),
        ),
      );
}

class ProfileTopAction extends StatelessWidget {
  const ProfileTopAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) =>
      AppTopAction(label: label, onTap: onTap, icon: icon);
}
````

## File: lib/firebase_options.dart
````dart
// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBPTOZDnYDXxe9VNSzYLXPvso5nIiHTsPc',
    appId: '1:793011933510:web:e9cb5587fb777961911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    authDomain: 'stallseeker-c2ffe.firebaseapp.com',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    measurementId: 'G-KEBYKY2P8P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzTEscU-ljvVtKgSVFs-KN3J3BtDre2Cs',
    appId: '1:793011933510:android:7127576788f40c81911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrE5vzUXqYDTN5UQrbVKzx8LBwiA18mrc',
    appId: '1:793011933510:ios:29aa93bdf1ed90e6911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    iosClientId: '793011933510-gphe3f510j5v4u555g4uo4ls5bm7bnsm.apps.googleusercontent.com',
    iosBundleId: 'com.example.stallseeker',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCrE5vzUXqYDTN5UQrbVKzx8LBwiA18mrc',
    appId: '1:793011933510:ios:29aa93bdf1ed90e6911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    iosClientId: '793011933510-gphe3f510j5v4u555g4uo4ls5bm7bnsm.apps.googleusercontent.com',
    iosBundleId: 'com.example.stallseeker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBPTOZDnYDXxe9VNSzYLXPvso5nIiHTsPc',
    appId: '1:793011933510:web:b99eecd2060151e1911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    authDomain: 'stallseeker-c2ffe.firebaseapp.com',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    measurementId: 'G-QFFLHPN0GT',
  );
}
````

## File: test/app_pill_navigation_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_pill_navigation.dart';

void main() {
  for (final width in [390.0, 960.0]) {
    testWidgets(
        'pill navigation fits ${width.toInt()}px viewport and switches tabs',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var selected = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(builder: (context, setState) {
          return Scaffold(
            extendBody: true,
            body: const ColoredBox(
              key: Key('page-content'),
              color: Colors.green,
              child: SizedBox.expand(),
            ),
            bottomNavigationBar: AppPillNavigation(
              selectedIndex: selected,
              onDestinationSelected: (index) =>
                  setState(() => selected = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.favorite), label: 'Following'),
                NavigationDestination(
                    icon: Icon(Icons.notifications), label: 'Notifications'),
                NavigationDestination(
                    icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          );
        }),
      ));

      expect(tester.takeException(), isNull);
      final bar = tester.getRect(find.byKey(const Key('pill-navigation')));
      expect(bar.left, greaterThanOrEqualTo(12));
      expect(bar.right, lessThanOrEqualTo(width - 12));
      expect(bar.width, closeTo(width < 674 ? width - 24 : 650, 1));
      expect(tester.getRect(find.byKey(const Key('page-content'))).bottom,
          greaterThan(bar.bottom));
      expect(find.byTooltip('Search'), findsNothing);

      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(selected, 3);
      expect(tester.takeException(), isNull);
    });
  }
}
````

## File: test/booking_card_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/features/shared/booking_detail_screen.dart';

void main() {
  for (final isVendor in [false, true]) {
    testWidgets('special instructions appear for vendor=$isVendor',
        (tester) async {
      final booking = DemoOrder.fromMap(const {
        'id': 'with-instructions',
        'customerName': 'Aina',
        'stallName': 'Nasi Stall',
        'specialInstructions': 'Less spicy, please\nNo onions.',
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            BookingSummaryCard(
                booking: booking, isVendor: isVendor, onTap: () {}),
            BookingSpecialInstructionsCard(
                instructions: booking.specialInstructions),
          ]),
        ),
      ));
      expect(find.text('Special instructions: Less spicy, please\nNo onions.'),
          findsOneWidget);
      expect(find.text('Less spicy, please\nNo onions.'), findsOneWidget);
      expect(find.text('Requests are subject to vendor acceptance.'),
          findsOneWidget);
    });
  }

  testWidgets(
      'simultaneous bookings show separate progress and open separately',
      (tester) async {
    final opened = <String>[];
    DemoOrder booking(String id, String status, bool unseen) => DemoOrder(
          id: id,
          customerId: 'customer',
          vendorId: 'vendor',
          customerName: 'Customer',
          stallName: 'Stall $id',
          status: status,
          items: const [],
          totalCents: 1200,
          createdAt: DateTime(2026, 10, 8),
          customerUnseenReady: unseen,
        );

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      BookingSummaryCard(
          booking: booking('first', 'preparing', false),
          isVendor: false,
          onTap: () => opened.add('first')),
      BookingSummaryCard(
          booking: booking('second', 'ready', true),
          isVendor: false,
          onTap: () => opened.add('second')),
    ]))));

    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Ready for collection'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    await tester.tap(find.text('Stall second'));
    expect(opened, ['second']);
  });
}
````

## File: test/booking_cart_view_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/customer/orders/demo_order_cart_screen.dart';

void main() {
  for (final width in [320.0, 390.0, 960.0]) {
    testWidgets('booking cart fits ${width.toInt()}px and updates the total',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final item = MenuItemModel(itemId: 'tea', name: 'Air teh', price: 2);
      final quantities = <String, int>{};
      final instructions = TextEditingController();
      addTearDown(instructions.dispose);
      var submitted = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Your order')),
          body: StatefulBuilder(
              builder: (context, setState) => BookingCartView(
                    stallName: 'Adam stalls',
                    items: [item],
                    quantities: quantities,
                    sending: false,
                    specialInstructionsController: instructions,
                    onQuantityChanged: (item, quantity) =>
                        setState(() => quantities[item.itemId] = quantity),
                    onSubmit: () => submitted = true,
                  )),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Choose an item'), findsOneWidget);
      expect(find.text('RM 0.00'), findsOneWidget);

      final field = find.byType(TextField);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Less spicy, please');
      expect(find.text('Requests are subject to vendor acceptance.'),
          findsOneWidget);
      expect(tester.widget<TextField>(field).maxLength, 500);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      await tester.ensureVisible(find.byTooltip('Add Air teh'));
      await tester.tap(find.byTooltip('Add Air teh'));
      await tester.pump();
      expect(find.text('RM 2.00'), findsNWidgets(2));
      expect(find.text('Continue to payment'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(instructions.text, 'Less spicy, please');

      await tester.tap(find.text('Continue to payment'));
      expect(submitted, isTrue);
      expect(instructions.text, 'Less spicy, please');
    });
  }

  testWidgets('out-of-stock selection cannot count toward payment',
      (tester) async {
    final item = MenuItemModel(
        itemId: 'tea', name: 'Air teh', price: 2, status: 'out_of_stock');
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: BookingCartView(
          stallName: 'Adam stalls',
          items: [item],
          quantities: const {'tea': 1},
          sending: false,
          onQuantityChanged: (_, __) {},
          onSubmit: () {},
        ),
      ),
    ));
    expect(find.text('RM 0.00'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
        isNull);
  });

  testWidgets('special instructions are disabled while submitting',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BookingCartView(
          stallName: 'Stall',
          items: [MenuItemModel(itemId: 'tea', name: 'Tea', price: 2)],
          quantities: const {'tea': 1},
          sending: true,
          onQuantityChanged: (_, __) {},
          onSubmit: () {},
        ),
      ),
    ));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });
}
````

## File: test/demo_booking_service_test.dart
````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/services/local_demo_booking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('device booking persists through vendor and customer status changes',
      () async {
    final vendorService = LocalDemoBookingService(actorId: 'vendor-1');
    final customerService = LocalDemoBookingService(actorId: 'customer-1');
    final vendor = VendorModel(
      vendorId: 'vendor-1',
      stallName: 'Nasi Stall',
      description: '',
      category: 'Food',
      openingHours: '',
      latitude: 3.1,
      longitude: 101.7,
    );

    expect(await vendorService.isSelfCollectEnabled(vendor.vendorId), false);
    await vendorService.setSelfCollectEnabled(vendor.vendorId, true);
    final id = await customerService.requestOrder(
      vendor,
      const [
        DemoOrderItem(
            itemId: 'dish-1',
            name: 'Nasi Lemak',
            unitPriceCents: 650,
            quantity: 2),
      ],
      customerName: 'Aina',
      specialInstructions: '  Less spicy, please  ',
    );

    var vendorBookings =
        await vendorService.watchVendorOrders('vendor-1').first;
    expect(vendorBookings.single.id, id);
    expect(vendorBookings.single.totalCents, 1300);
    expect(vendorBookings.single.status, 'requested');
    expect(vendorBookings.single.specialInstructions, 'Less spicy, please');

    await vendorService.respond(id, accept: true);
    expect(
        (await customerService.watchCustomerOrders('customer-1').first)
            .single
            .status,
        'confirmed');
    await vendorService.advance(id);
    await vendorService.advance(id);
    expect(
        (await customerService.watchCustomerOrders('customer-1').first)
            .single
            .status,
        'ready');
    await vendorService.advance(id);
    vendorBookings = await vendorService.watchVendorOrders('vendor-1').first;
    expect(vendorBookings.single.status, 'collected');
    expect(vendorBookings.single.specialInstructions, 'Less spicy, please');

    await customerService.removeAccountData('customer-1');
    expect(await vendorService.watchVendorOrders('vendor-1').first, isEmpty);
  });

  test('older bookings without special instructions remain readable', () {
    final booking = DemoOrder.fromMap(const {'id': 'old-booking'});
    expect(booking.specialInstructions, isEmpty);
    expect(DemoOrder.fromMap(booking.toMap()).specialInstructions, isEmpty);
  });
}
````

## File: test/discovery_filters_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/services/place_search_service.dart';
import 'package:stallseeker/features/shared/manual_location_dialog.dart';

class FakePlacesSdk extends places.FlutterGooglePlacesSdk {
  FakePlacesSdk({this.failure}) : super('test-key');

  final Object? failure;

  String? lastQuery;
  List<String>? requestedCountries;

  @override
  Future<places.FindAutocompletePredictionsResponse>
      findAutocompletePredictions(
    String query, {
    List<String>? countries,
    List<places.PlaceTypeFilter> placeTypesFilter = const [],
    bool? newSessionToken,
    places.LatLng? origin,
    places.LatLngBounds? locationBias,
    places.LatLngBounds? locationRestriction,
  }) async {
    lastQuery = query;
    requestedCountries = countries;

    final error = failure;
    if (error != null) throw error;

    return const places.FindAutocompletePredictionsResponse([
      places.AutocompletePrediction(
        distanceMeters: null,
        placeId: 'bangi',
        primaryText: 'Bangi',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi, Selangor, Malaysia',
      ),
      places.AutocompletePrediction(
        distanceMeters: null,
        placeId: 'bangi-square',
        primaryText: 'Bangi Square',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi Square, Selangor, Malaysia',
      ),
    ]);
  }
}

class FakePlaceSearchService extends PlaceSearchService {
  FakePlaceSearchService() : super(places: FakePlacesSdk());

  @override
  Future<List<PlaceSuggestion>> search(String query) async {
    return const [
      PlaceSuggestion(
        placeId: 'bangi',
        primaryText: 'Bangi',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi, Selangor, Malaysia',
        coordinates: LatLng(2.9, 101.7),
      ),
      PlaceSuggestion(
        placeId: 'bangi-square',
        primaryText: 'Bangi Square',
        secondaryText: 'Selangor, Malaysia',
        fullText: 'Bangi Square, Selangor, Malaysia',
        coordinates: LatLng(2.91, 101.8),
      ),
    ];
  }
}

void main() {
  group('scheduled opening in Malaysia time', () {
    final hours = <int, List<StallHoursInterval>>{
      1: [const StallHoursInterval(20 * 60, 2 * 60)],
      2: [
        const StallHoursInterval(8 * 60, 12 * 60),
        const StallHoursInterval(14 * 60, 17 * 60),
      ],
      7: [const StallHoursInterval(23 * 60, 60)],
    };

    DateTime at(int day, int hour, [int minute = 0]) =>
        malaysiaInstant(2026, 9, day, hour, minute);

    test(
      'overnight hours include next day and Sunday to Monday rollover',
      () {
        expect(isWithinStallSchedule(at(21, 0, 30), hours, []), isTrue);
        expect(isWithinStallSchedule(at(21, 20), hours, []), isTrue);
        expect(isWithinStallSchedule(at(22, 1, 59), hours, []), isTrue);
        expect(isWithinStallSchedule(at(22, 2), hours, []), isFalse);
        expect(isWithinStallSchedule(at(22, 13), hours, []), isFalse);
      },
    );

    test(
      'no saved schedule is not assumed open at a future time',
      () {
        expect(isWithinStallSchedule(at(22, 10), {}, []), isFalse);
      },
    );

    test(
      'closures override an exact time at inclusive start and exclusive end',
      () {
        final closures = [
          TemporaryClosure(at(22, 9), at(22, 10)),
        ];

        expect(
          isWithinStallSchedule(at(22, 9), hours, closures),
          isFalse,
        );
        expect(
          isWithinStallSchedule(at(22, 10), hours, closures),
          isTrue,
        );
      },
    );

    test(
      'time windows match partial openings but exclude fully closed windows',
      () {
        expect(
          hasScheduledOpening(at(21, 22), at(22, 6), hours, []),
          isTrue,
        );

        expect(
          hasScheduledOpening(
            at(22, 6),
            at(22, 12),
            hours,
            [TemporaryClosure(at(22, 8), at(22, 12))],
          ),
          isFalse,
        );

        expect(
          hasScheduledOpening(
            at(22, 6),
            at(22, 12),
            hours,
            [TemporaryClosure(at(22, 8), at(22, 10))],
          ),
          isTrue,
        );

        expect(
          hasScheduledOpening(
            at(22, 6),
            at(22, 12),
            hours,
            [
              TemporaryClosure(at(22, 8), at(22, 10)),
              TemporaryClosure(at(22, 10), at(22, 12)),
            ],
          ),
          isFalse,
        );
      },
    );
  });

  test('Google Places search requests Malaysian suggestions', () async {
    final sdk = FakePlacesSdk();
    final service = PlaceSearchService(places: sdk);

    final results = await service.search(' bangi ');

    expect(sdk.lastQuery, 'bangi');
    expect(sdk.requestedCountries, ['my']);
    expect(results.length, 2);
    expect(results.last.placeId, 'bangi-square');
    expect(
      results.last.fullText,
      'Bangi Square, Selangor, Malaysia',
    );

    service.dispose();
  });

  test('Google Places errors propagate for fallback handling', () async {
    final service = PlaceSearchService(
      places: FakePlacesSdk(
        failure: StateError('Places API unavailable'),
      ),
    );

    await expectLater(
      service.search('ipoh'),
      throwsA(isA<StateError>()),
    );

    service.dispose();
  });

  testWidgets(
    'customer can change the selected location suggestion',
    (tester) async {
      final service = FakePlaceSearchService();
      LocationSelection? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showManualLocationDialog(
                    context,
                    placeSearch: service,
                  );
                },
                child: const Text('Pick location'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick location'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'bangi');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use location'));
      await tester.pumpAndSettle();

      expect(
        selected?.label,
        'Bangi Square, Selangor, Malaysia',
      );
      expect(selected?.coordinates, const LatLng(2.91, 101.8));
      expect(tester.takeException(), isNull);

      service.dispose();
    },
  );
}
````

## File: test/payment_ui_test.dart
````dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/shared/booking_payment_card.dart';
import 'package:stallseeker/features/vendor/dashboard/vendor_demo_sales.dart';

DemoOrder order(
        {String id = 'order',
        String vendorId = 'seller',
        String? mode = 'test',
        String? payment = 'awaiting_payment',
        bool checkoutFirst = false,
        bool vendorUnseenRequest = false,
        int refund = 0,
        DateTime? paidAt}) =>
    DemoOrder(
        id: id,
        customerId: 'buyer',
        vendorId: vendorId,
        customerName: 'Adam',
        stallName: 'Nasi Lemak Kak Ani',
        status: 'confirmed',
        items: const [],
        totalCents: 1250,
        createdAt: DateTime(2026, 10, 20),
        paymentMode: mode,
        checkoutFirst: checkoutFirst,
        vendorUnseenRequest: vendorUnseenRequest,
        paymentStatus: payment,
        paymentRefundedCents: refund,
        paymentExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
        paymentPaidAt: paidAt);

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('PAYMENT_PREVIEW')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(const Key('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('tmp/payment-previews').create(recursive: true);
    await File('tmp/payment-previews/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Widget app(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: RepaintBoundary(
        key: const Key('preview'),
        child: Scaffold(
            appBar: AppBar(
                title: const Text('StallSeeker',
                    style: TextStyle(fontFamily: 'Roboto'))),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16), child: child))));

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('PAYMENT_PREVIEW')) return;
    const fontRoot = String.fromEnvironment('PREVIEW_FONT_ROOT');
    final bytes = await File('$fontRoot/roboto-regular.ttf').readAsBytes();
    for (final family in ['Roboto', 'Ahem']) {
      final font = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await font.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test(
      'legacy records remain payable outside the app and test payment metadata survives round trips',
      () {
    final legacy = order(mode: null, payment: null);
    expect(legacy.canPrepare, isTrue);
    expect(legacy.hasTestPayment, isFalse);
    final paid = order(payment: 'paid', paidAt: DateTime.utc(2026, 10, 20));
    final decoded = DemoOrder.fromMap(paid.toMap()).withStatus('preparing');
    expect(decoded.paymentStatus, 'paid');
    expect(decoded.paymentPaidAt, paid.paymentPaidAt);
    expect(decoded.paymentMode, 'test');
    expect(order(checkoutFirst: true).toMap()['checkoutFirst'], isTrue);
    expect(DemoOrder.fromMap(order(checkoutFirst: true).toMap()).checkoutFirst,
        isTrue);
    expect(order().canPrepare, isFalse);
    expect(paid.canPrepare, isTrue);
  });

  test('customer may cancel a paid test booking until it is collected', () {
    final paid = order(payment: 'paid');
    for (final status in ['confirmed', 'preparing', 'ready']) {
      expect(paid.withStatus(status).canCustomerCancel, isTrue);
    }
    expect(paid.withStatus('collected').canCustomerCancel, isFalse);
    expect(order(mode: null).canCustomerCancel, isFalse);
    expect(bookingStatusLabel(order(checkoutFirst: true)), 'Awaiting payment');
    expect(bookingStatusLabel(order(checkoutFirst: true, payment: 'paid')),
        'Paid · awaiting preparation');
    expect(
        order(checkoutFirst: true, payment: 'paid', vendorUnseenRequest: true)
            .vendorNeedsAttention,
        isTrue);
    expect(
        order(
                checkoutFirst: true,
                payment: 'pending',
                vendorUnseenRequest: true)
            .vendorNeedsAttention,
        isFalse);
  });

  test(
      'demo sales exclude other stalls, old bookings, unpaid and refunded orders',
      () {
    final now =
        DateTime.utc(2026, 10, 19, 17); // 1am on 20 October in Malaysia.
    final result = DemoSalesSummary.fromOrders([
      order(payment: 'paid', paidAt: now),
      order(payment: 'paid', paidAt: now, refund: 250),
      order(payment: 'paid', paidAt: DateTime.utc(2026, 10, 19, 15)),
      order(vendorId: 'other', payment: 'paid', paidAt: now),
      order(mode: null, payment: 'paid', paidAt: now),
      order(payment: 'refunded', paidAt: now),
      order(payment: 'refund_pending', paidAt: now),
      order(payment: 'pending', paidAt: now),
    ], vendorId: 'seller', now: now);
    expect(result.todayCents, 2250);
    expect(result.totalCents, 3500);
    expect(result.paidOrders, 3);
  });

  testWidgets(
      'customer can pay only eligible bookings and sees payment information',
      (tester) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = 0;
    await tester.pumpWidget(app(BookingPaymentCard(
        booking: order(),
        isVendor: false,
        onPay: () => tapped++,
        onRefresh: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Pay RM 12.50'), findsOneWidget);
    expect(find.text('Complete your payment securely with Stripe.'),
        findsOneWidget);
    expect(find.textContaining('TEST MODE'), findsNothing);
    await tester.tap(find.text('Pay RM 12.50'));
    expect(tapped, 1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, 'customer-payment');

    await tester.pumpWidget(app(BookingPaymentCard(
        booking: order(payment: 'paid'),
        isVendor: false,
        onPay: () => tapped++)));
    expect(find.text('Pay RM 12.50'), findsNothing);
    expect(find.text('Paid'), findsOneWidget);
  });

  testWidgets('vendor and busy payment cards cannot launch checkout',
      (tester) async {
    await tester
        .pumpWidget(app(BookingPaymentCard(booking: order(), isVendor: true)));
    expect(find.text('Pay RM 12.50'), findsNothing);
    expect(find.textContaining('Preparation unlocks'), findsOneWidget);
    await tester.pumpWidget(app(BookingPaymentCard(
        booking: order(),
        isVendor: false,
        busy: true,
        onPay: () => fail('Must not start another payment'))));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });

  testWidgets('sales card uses release wording and fits narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(DemoSalesCard(
        summary: const DemoSalesSummary(
            todayCents: 8500, totalCents: 12500, paidOrders: 8),
        onHistory: () {})));
    await tester.pumpAndSettle();
    expect(find.text('RM 85.00'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
    expect(find.textContaining('TEST MODE'), findsNothing);
    expect(tester.takeException(), isNull);
    await preview(tester, 'vendor-sales');
  });
}
````

## File: test/profile_page_test.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/features/shared/profile_page.dart';

ProfilePage page({
  bool guest = false,
  bool vendor = false,
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
    isVendor: vendor,
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
  testWidgets('follow notification settings are available only to customers',
      (tester) async {
    for (final vendor in [false, true]) {
      await tester
          .pumpWidget(MaterialApp(home: Scaffold(body: page(vendor: vendor))));
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.text('Notifications and Sounds'),
          vendor ? findsNothing : findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

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
````

## File: test/vendor_dashboard_view_test.dart
````dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_pill_navigation.dart';
import 'package:stallseeker/features/vendor/dashboard/vendor_dashboard_view.dart';

final _now = DateTime.utc(2026, 10, 24, 4);

VendorModel _vendor({bool temporaryClosure = false}) => VendorModel(
      vendorId: 'seller',
      stallName: 'Warung Pak Ali',
      description: 'Fresh local favourites',
      category: 'Malay',
      openingHours: '8 AM – 4 PM',
      phoneNumber: '0123456789',
      isOpen: true,
      selfCollectEnabled: true,
      temporaryClosures: temporaryClosure
          ? [
              TemporaryClosure(
                  DateTime.now().subtract(const Duration(hours: 1)),
                  DateTime.now().add(const Duration(hours: 1))),
            ]
          : [],
    );

DemoOrder _booking(String id, String status,
        {bool paid = true, DateTime? createdAt, DateTime? expiresAt}) =>
    DemoOrder(
      id: id,
      customerId: id,
      vendorId: 'seller',
      customerName: id,
      stallName: 'Warung Pak Ali',
      status: status,
      items: const [
        DemoOrderItem(
            itemId: 'dish',
            name: 'Nasi Lemak',
            unitPriceCents: 600,
            quantity: 2),
      ],
      totalCents: 1200,
      createdAt: createdAt ?? _now,
      expiresAt: expiresAt,
      paymentMode: 'test',
      paymentStatus: paid ? 'paid' : 'awaiting_payment',
      paymentPaidAt: paid ? _now : null,
    );

Widget _app({
  List<DemoOrder> bookings = const [],
  VendorModel? vendor,
  bool error = false,
  bool loading = false,
  bool sharing = true,
  bool saving = false,
  String? locationError,
  Set<String> busy = const {},
  double scale = 1,
  ValueChanged<String>? onAction,
}) {
  void action(String name) => onAction?.call(name);
  return MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!),
    home: RepaintBoundary(
      key: const Key('dashboard-preview'),
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: VendorDashboardView(
            vendor: vendor ?? _vendor(),
            bookings: bookings,
            bookingsLoading: loading,
            bookingsError: error,
            saving: saving,
            locationSharing: sharing,
            locationError: locationError,
            busyBookings: busy,
            now: _now,
            onRefresh: () async => action('refresh'),
            onToggleOpen: (open) => action('open:$open'),
            onToggleSelfCollect: (enabled) => action('collect:$enabled'),
            onResumeLocation: () => action('resume'),
            onPreview: () => action('preview'),
            onEditStall: () => action('edit'),
            onMenu: () => action('menu'),
            onStock: () => action('stock'),
            onBookings: () => action('bookings'),
            onPaymentHistory: () => action('history'),
            onOpenBooking: (booking) => action('view:${booking.id}'),
            onAdvanceBooking: (booking) => action('advance:${booking.id}'),
          ),
        ),
        bottomNavigationBar: AppPillNavigation(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.grid_view), label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    ),
  );
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _show(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('DASHBOARD_PREVIEW')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('dashboard-preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('tmp/vendor-dashboard').create(recursive: true);
    await File('tmp/vendor-dashboard/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('DASHBOARD_PREVIEW')) return;
    const fontRoot = String.fromEnvironment('PREVIEW_FONT_ROOT');
    final fonts = FontLoader('Roboto');
    for (final name in ['Regular', 'Medium']) {
      final bytes = await File('$fontRoot/Roboto-$name.ttf').readAsBytes();
      fonts.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await fonts.load();
    final fallback = FontLoader('Ahem')
      ..addFont(Future.value(ByteData.sublistView(
          await File('$fontRoot/Roboto-Regular.ttf').readAsBytes())));
    await fallback.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('stall controls, preview and each quick action are connected',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final actions = <String>[];
    await tester.pumpWidget(_app(onAction: actions.add));
    expect(tester.getTopLeft(find.text('Stall open')).dy,
        lessThan(tester.getTopLeft(find.text('Quick actions')).dy));
    await tester.tap(find.text('Preview'));
    await tester.tap(find.text('Edit stall'));
    await tester.tap(find.text('Menu'));
    await tester.tap(find.text('Stock'));
    await tester.tap(find.text('Bookings').first);
    await tester.tap(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).last);
    expect(actions, [
      'preview',
      'edit',
      'menu',
      'stock',
      'bookings',
      'open:false',
      'collect:false'
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requests come first and expired requests are excluded',
      (tester) async {
    _viewport(tester, const Size(390, 1400));
    final actions = <String>[];
    await tester.pumpWidget(_app(bookings: [
      _booking('Daniel', 'preparing'),
      _booking('Old request', 'requested',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1))),
      _booking('Aisyah', 'requested'),
    ], onAction: actions.add));
    expect(find.text('Old request'), findsNothing);
    expect(tester.getTopLeft(find.text('Aisyah')).dy,
        lessThan(tester.getTopLeft(find.text('Daniel')).dy));
    await _show(tester, find.text('Review booking'));
    await tester.tap(find.text('Review booking'));
    await _show(tester, find.text('Mark ready'));
    await tester.tap(find.text('Mark ready'));
    expect(actions, ['view:Aisyah', 'advance:Daniel']);
    expect(find.textContaining('Collect at'), findsNothing);
    expect(find.textContaining('Booked 24/10'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await _preview(tester, 'dashboard-full');
  });

  testWidgets('unpaid bookings cannot prepare and busy actions are disabled',
      (tester) async {
    _viewport(tester, const Size(390, 1400));
    await tester.pumpWidget(_app(bookings: [
      _booking('Unpaid', 'confirmed', paid: false),
      _booking('Paid', 'confirmed'),
    ], busy: {
      'Paid'
    }, saving: true));
    expect(find.text('Start preparing'), findsNothing);
    expect(find.text('Updating…'), findsOneWidget);
    expect(find.text('View booking'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    for (final control in tester.widgetList<Switch>(find.byType(Switch))) {
      expect(control.onChanged, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('closure and location problems have clear recovery actions',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final actions = <String>[];
    await tester.pumpWidget(
        _app(vendor: _vendor(temporaryClosure: true), onAction: actions.add));
    expect(find.text('Temporarily closed'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch).first).onChanged, isNull);
    await tester.tap(find.text('Manage temporary closure'));
    expect(actions, ['edit']);
    await tester.pumpWidget(
        _app(sharing: true, locationError: 'Check GPS', onAction: actions.add));
    expect(find.text('Check GPS'), findsOneWidget);
    await tester.tap(find.text('Retry location'));
    expect(actions.last, 'resume');
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview counts Malaysia dates and uses release wording',
      (tester) async {
    _viewport(tester, const Size(390, 1400));
    await tester.pumpWidget(_app(bookings: [
      _booking('Today', 'collected', createdAt: DateTime.utc(2026, 10, 23, 16)),
      _booking('Yesterday', 'collected',
          createdAt: DateTime.utc(2026, 10, 23, 15, 59)),
    ]));
    await _show(tester, find.text('Today’s overview'));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('RM 24.00'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
    expect(
        find.textContaining(RegExp(r'test|demo|simulat', caseSensitive: false)),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 720), const Size(960, 1000)]) {
    testWidgets('dashboard fits ${size.width} wide with enlarged text',
        (tester) async {
      _viewport(tester, size);
      await tester.pumpWidget(_app(scale: 1.6, bookings: [
        _booking('A customer with a very long name', 'confirmed'),
        _booking('Another customer', 'preparing'),
      ]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _show(tester, find.text('Today’s overview'));
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [
    const Size(320, 900),
    const Size(390, 1100),
    const Size(768, 1024),
    const Size(960, 700),
    const Size(1280, 800),
  ]) {
    testWidgets('responsive dashboard at ${size.width} × ${size.height}',
        (tester) async {
      _viewport(tester, size);
      await tester.pumpWidget(_app(bookings: [
        _booking('Aina', 'requested'),
        _booking('Daniel', 'preparing'),
        _booking('Farah', 'ready'),
      ]));
      await tester.pumpAndSettle();
      final wide = size.width >= 900;
      expect(
          find.byKey(
              Key(wide ? 'dashboard-two-columns' : 'dashboard-single-column')),
          findsOneWidget);
      final bookings = tester.getTopLeft(find.text('Active bookings'));
      final quickActions = tester.getTopLeft(find.text('Quick actions'));
      if (wide) {
        expect(bookings.dx, lessThan(quickActions.dx));
        expect(bookings.dy, closeTo(quickActions.dy, 1));
        expect(tester.getTopLeft(find.text('Today’s overview')).dx,
            quickActions.dx);
      } else {
        expect(bookings.dy, greaterThan(quickActions.dy));
        if (size.width <= 600) {
          final button = find.widgetWithText(FilledButton, 'Review booking');
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(button).width, greaterThan(size.width - 120));
        }
      }
      expect(find.text('RM 12.00'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await _preview(tester, 'dashboard-${size.width.toInt()}');
    });
  }

  testWidgets('tablet window switches to one column when resized',
      (tester) async {
    _viewport(tester, const Size(1280, 800));
    await tester.pumpWidget(_app());
    expect(find.byKey(const Key('dashboard-two-columns')), findsOneWidget);
    tester.view.physicalSize = const Size(700, 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-single-column')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and failure do not present zero sales as real data',
      (tester) async {
    _viewport(tester, const Size(390, 1400));
    final actions = <String>[];
    await tester.pumpWidget(_app(error: true, onAction: actions.add));
    expect(find.text('Could not load bookings.'), findsOneWidget);
    expect(find.text('RM 0.00'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(actions, ['refresh']);
    await tester.pumpWidget(_app(loading: true));
    expect(find.text('Loading bookings…'), findsOneWidget);
    expect(find.text('No active bookings'), findsNothing);
    expect(find.text('RM 0.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
````

## File: lib/core/models/demo_order.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DemoOrderItem {
  const DemoOrderItem(
      {required this.itemId,
      required this.name,
      required this.unitPriceCents,
      required this.quantity});

  final String itemId;
  final String name;
  final int unitPriceCents;
  final int quantity;

  int get subtotalCents => unitPriceCents * quantity;

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'name': name,
        'unitPriceCents': unitPriceCents,
        'quantity': quantity,
      };

  factory DemoOrderItem.fromMap(Map<String, dynamic> data) => DemoOrderItem(
        itemId: data['itemId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        unitPriceCents: (data['unitPriceCents'] as num?)?.toInt() ?? 0,
        quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      );
}

class DemoOrder {
  const DemoOrder(
      {required this.id,
      required this.customerId,
      required this.vendorId,
      required this.customerName,
      required this.stallName,
      required this.status,
      required this.items,
      required this.totalCents,
      required this.createdAt,
      this.specialInstructions = '',
      this.expiresAt,
      this.pickupLatitude,
      this.pickupLongitude,
      this.paymentMode,
      this.checkoutFirst = false,
      this.paymentStatus,
      this.paymentReference,
      this.paymentExpiresAt,
      this.paymentPaidAt,
      this.paymentRefundedCents = 0,
      this.vendorUnseenRequest = false,
      this.customerUnseenReady = false});

  final String id;
  final String customerId;
  final String vendorId;
  final String customerName;
  final String stallName;
  final String status;
  final List<DemoOrderItem> items;
  final int totalCents;
  final DateTime? createdAt;
  final String specialInstructions;
  final DateTime? expiresAt;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? paymentMode;
  final bool checkoutFirst;
  final String? paymentStatus;
  final String? paymentReference;
  final DateTime? paymentExpiresAt;
  final DateTime? paymentPaidAt;
  final int paymentRefundedCents;

  bool get hasTestPayment => paymentMode == 'test';
  bool get awaitingPayment =>
      hasTestPayment &&
      status == 'confirmed' &&
      {'awaiting_payment', 'pending', 'failed'}.contains(paymentStatus);
  bool get canPay =>
      awaitingPayment &&
      paymentExpiresAt != null &&
      DateTime.now().isBefore(paymentExpiresAt!);
  bool get canPrepare =>
      status == 'confirmed' && (!hasTestPayment || paymentStatus == 'paid');
  bool get canCustomerCancel =>
      effectiveStatus == 'requested' ||
      (hasTestPayment &&
          {'confirmed', 'preparing', 'ready'}.contains(effectiveStatus));
  bool get vendorNeedsAttention =>
      vendorUnseenRequest &&
      (effectiveStatus == 'requested' ||
          (checkoutFirst && paymentStatus == 'paid'));
  int get demoSalesCents => hasTestPayment && paymentStatus == 'paid'
      ? (totalCents - paymentRefundedCents).clamp(0, totalCents)
      : 0;
  final bool vendorUnseenRequest;
  final bool customerUnseenReady;

  String get effectiveStatus {
    if (status == 'requested' &&
        expiresAt != null &&
        DateTime.now().isAfter(expiresAt!)) {
      return 'expired';
    }
    return status;
  }

  bool get isActive => !{'collected', 'rejected', 'cancelled', 'expired'}
      .contains(effectiveStatus);

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'vendorId': vendorId,
        'customerName': customerName,
        'stallName': stallName,
        'status': status,
        'items': items.map((item) => item.toMap()).toList(),
        'totalCents': totalCents,
        'createdAt': createdAt?.toIso8601String(),
        'specialInstructions': specialInstructions,
        'expiresAt': expiresAt?.toIso8601String(),
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'paymentMode': paymentMode,
        'checkoutFirst': checkoutFirst,
        'paymentStatus': paymentStatus,
        'paymentReference': paymentReference,
        'paymentExpiresAt': paymentExpiresAt?.toIso8601String(),
        'paymentPaidAt': paymentPaidAt?.toIso8601String(),
        'paymentRefundedCents': paymentRefundedCents,
        'vendorUnseenRequest': vendorUnseenRequest,
        'customerUnseenReady': customerUnseenReady,
      };

  DemoOrder withStatus(String nextStatus) => DemoOrder(
        id: id,
        customerId: customerId,
        vendorId: vendorId,
        customerName: customerName,
        stallName: stallName,
        status: nextStatus,
        items: items,
        totalCents: totalCents,
        createdAt: createdAt,
        specialInstructions: specialInstructions,
        expiresAt: nextStatus == 'requested' ? expiresAt : null,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        paymentMode: paymentMode,
        checkoutFirst: checkoutFirst,
        paymentStatus: paymentStatus,
        paymentReference: paymentReference,
        paymentExpiresAt: paymentExpiresAt,
        paymentPaidAt: paymentPaidAt,
        paymentRefundedCents: paymentRefundedCents,
        vendorUnseenRequest: vendorUnseenRequest,
        customerUnseenReady: customerUnseenReady,
      );

  factory DemoOrder.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return DemoOrder(
      id: doc.id,
      customerId: data['customerId'] as String? ?? '',
      vendorId: data['vendorId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      stallName: data['stallName'] as String? ?? 'Stall',
      status: data['status'] as String? ?? 'requested',
      items: rawItems
          .whereType<Map>()
          .map((item) => DemoOrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      specialInstructions: data['specialInstructions'] as String? ?? '',
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      pickupLatitude: (data['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickupLongitude'] as num?)?.toDouble(),
      paymentMode: data['paymentMode'] as String?,
      checkoutFirst: data['checkoutFirst'] == true,
      paymentStatus: data['paymentStatus'] as String?,
      paymentReference: data['paymentReference'] as String?,
      paymentExpiresAt: (data['paymentExpiresAt'] as Timestamp?)?.toDate(),
      paymentPaidAt: (data['paymentPaidAt'] as Timestamp?)?.toDate(),
      paymentRefundedCents:
          (data['paymentRefundedCents'] as num?)?.toInt() ?? 0,
      vendorUnseenRequest: data['vendorUnseenRequest'] == true,
      customerUnseenReady: data['customerUnseenReady'] == true,
    );
  }

  factory DemoOrder.fromMap(Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return DemoOrder(
      id: data['id'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      vendorId: data['vendorId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      stallName: data['stallName'] as String? ?? 'Stall',
      status: data['status'] as String? ?? 'requested',
      items: rawItems
          .whereType<Map>()
          .map((item) => DemoOrderItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalCents: (data['totalCents'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
      specialInstructions: data['specialInstructions'] as String? ?? '',
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? ''),
      pickupLatitude: (data['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (data['pickupLongitude'] as num?)?.toDouble(),
      paymentMode: data['paymentMode'] as String?,
      checkoutFirst: data['checkoutFirst'] == true,
      paymentStatus: data['paymentStatus'] as String?,
      paymentReference: data['paymentReference'] as String?,
      paymentExpiresAt:
          DateTime.tryParse(data['paymentExpiresAt'] as String? ?? ''),
      paymentPaidAt: DateTime.tryParse(data['paymentPaidAt'] as String? ?? ''),
      paymentRefundedCents:
          (data['paymentRefundedCents'] as num?)?.toInt() ?? 0,
      vendorUnseenRequest: data['vendorUnseenRequest'] == true,
      customerUnseenReady: data['customerUnseenReady'] == true,
    );
  }
}

String demoOrderStatusLabel(String status) => switch (status) {
      'requested' => 'Booking requested',
      'confirmed' => 'Booking confirmed',
      'preparing' => 'Preparing',
      'ready' => 'Ready for collection',
      'collected' => 'Collected',
      'rejected' => 'Rejected',
      'cancelled' => 'Cancelled',
      'expired' => 'Expired',
      _ => status,
    };

String bookingStatusLabel(DemoOrder booking) {
  if (booking.checkoutFirst && booking.status == 'confirmed') {
    return booking.paymentStatus == 'paid'
        ? 'Paid · awaiting preparation'
        : 'Awaiting payment';
  }
  return demoOrderStatusLabel(booking.effectiveStatus);
}
````

## File: lib/core/models/notification_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel(
      {required this.id,
      required this.vendorId,
      required this.title,
      required this.body,
      required this.createdAt,
      required this.isRead,
      this.itemId,
      this.type = 'vendor_opened'});

  final String id;
  final String vendorId;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool isRead;
  final String? itemId;
  final String type;

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    final time = data['createdAt'];
    return NotificationModel(
      id: id,
      vendorId: data['vendorId'] is String ? data['vendorId'] as String : '',
      title: data['title'] is String ? data['title'] as String : 'Stall update',
      body: data['body'] is String ? data['body'] as String : '',
      createdAt: time is Timestamp ? time.toDate() : null,
      isRead: data['isRead'] == true,
      itemId: data['itemId'] is String ? data['itemId'] as String : null,
      type: data['type'] is String ? data['type'] as String : 'vendor_opened',
    );
  }
}

// represent saved notifcation
````

## File: lib/core/services/demo_order_service.dart
````dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/demo_order.dart';
import '../models/vendor_model.dart';

/// Live self-collect bookings shared between customer and vendor accounts.
/// The old same-phone demo is read separately by LocalDemoBookingService.
class DemoOrderService {
  DemoOrderService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<DemoOrder>> watchCustomerOrders(String customerId) => _watch(_db
      .collection('bookings')
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true));

  Stream<List<DemoOrder>> watchVendorOrders(String vendorId) => _watch(_db
          .collection('bookings')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true))
      .map((orders) => orders
          .where((order) => !order.checkoutFirst || order.paymentPaidAt != null)
          .toList());

  Stream<List<DemoOrder>> _watch(Query<Map<String, dynamic>> query) => query
      .snapshots()
      .map((snapshot) => snapshot.docs.map(DemoOrder.fromDocument).toList());

  Stream<DemoOrder?> watchBooking(String bookingId) => _db
      .collection('bookings')
      .doc(bookingId)
      .snapshots()
      .map((doc) => doc.exists ? DemoOrder.fromDocument(doc) : null);

  Stream<int> watchUnseenCount(String uid, {required bool isVendor}) =>
      (isVendor ? watchVendorOrders(uid) : watchCustomerOrders(uid)).map(
          (orders) => orders
              .where((booking) => isVendor
                  ? booking.vendorNeedsAttention
                  : booking.customerUnseenReady)
              .length);

  Future<String> requestOrder(VendorModel vendor, List<DemoOrderItem> items,
      {String specialInstructions = ''}) async {
    final random = Random.secure();
    final key = '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0')}'
        '${random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0')}';
    final result = await _functions.httpsCallable('createBooking').call({
      'vendorId': vendor.vendorId,
      'requestKey': key,
      'specialInstructions': specialInstructions.trim(),
      'items': [
        for (final item in items)
          {'itemId': item.itemId, 'quantity': item.quantity}
      ],
    });
    return (result.data as Map)['bookingId'] as String;
  }

  Future<void> respond(String bookingId, {required bool accept}) =>
      _action(bookingId, accept ? 'accept' : 'reject');

  Future<void> advance(String bookingId, String status) => _action(
        bookingId,
        switch (status) {
          'confirmed' => 'startPreparing',
          'preparing' => 'markReady',
          'ready' => 'markCollected',
          _ => throw StateError('Booking cannot advance.'),
        },
      );

  Future<void> cancel(String bookingId) => _action(bookingId, 'cancel');

  Future<Uri> createTestCheckout(String bookingId) async {
    final result = await _functions
        .httpsCallable('createStripeCheckout',
            options:
                HttpsCallableOptions(timeout: const Duration(seconds: 120)))
        .call({'bookingId': bookingId});
    final uri = Uri.parse((result.data as Map)['checkoutUrl'] as String);
    if (uri.scheme != 'https' || uri.host != 'checkout.stripe.com') {
      throw StateError('Invalid checkout URL.');
    }
    return uri;
  }

  Future<void> refreshPayment(String bookingId) async {
    await _functions
        .httpsCallable('refreshStripePayment',
            options:
                HttpsCallableOptions(timeout: const Duration(seconds: 120)))
        .call({'bookingId': bookingId});
  }

  Future<void> markViewed(String bookingId) async {
    await _functions.httpsCallable('markBookingViewed').call({
      'bookingId': bookingId,
    });
  }

  Future<void> _action(String bookingId, String action) async {
    await _functions.httpsCallable('updateBooking').call({
      'bookingId': bookingId,
      'action': action,
    });
  }
}
````

## File: lib/core/services/place_search_service.dart
````dart
import 'package:flutter/foundation.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    hide LatLng;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSelection {
  const LocationSelection({
    required this.coordinates,
    required this.label,
  });

  final LatLng coordinates;
  final String label;
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
    this.coordinates,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;
  final LatLng? coordinates;
}

class PlaceSearchService {
  PlaceSearchService({FlutterGooglePlacesSdk? places})
      : _places = places ??
            FlutterGooglePlacesSdk(
              'AIzaSyDV0UDXXVwuXQw3dVAb8RHmcql3bTlysNE',
              useNewApi: true,
            );

  final FlutterGooglePlacesSdk _places;

  void dispose() {}

  Future<List<PlaceSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final response = await _places.findAutocompletePredictions(
        trimmed,
        countries: ['my'],
      ).timeout(const Duration(seconds: 12));

      return response.predictions.map((prediction) {
        return PlaceSuggestion(
          placeId: prediction.placeId,
          primaryText: prediction.primaryText,
          secondaryText: prediction.secondaryText,
          fullText: prediction.fullText,
        );
      }).toList();
    } catch (error, stackTrace) {
      debugPrint('Google Places search failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<LatLng?> getCoordinates(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      final response = await _places.fetchPlace(
        placeId,
        fields: [PlaceField.Location],
      ).timeout(const Duration(seconds: 12));

      final coordinates = response.place?.latLng;

      if (coordinates == null) return null;

      return LatLng(coordinates.lat, coordinates.lng);
    } catch (error, stackTrace) {
      debugPrint('Google Places details failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
````

## File: lib/core/widgets/app_pill_navigation.dart
````dart
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Floating iOS-style tab bar shared by customer and vendor screens.
class AppPillNavigation extends StatelessWidget {
  const AppPillNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Container(
                key: const Key('pill-navigation'),
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 16,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(36),
                  clipBehavior: Clip.antiAlias,
                  child: Row(children: [
                    for (var index = 0; index < destinations.length; index++)
                      Expanded(
                        child: InkWell(
                          onTap: () => onDestinationSelected(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconTheme(
                                  data: IconThemeData(
                                    size: 25,
                                    color: index == selectedIndex
                                        ? AppColors.primary
                                        : AppColors.textDark,
                                  ),
                                  child: index == selectedIndex
                                      ? (destinations[index].selectedIcon ??
                                          destinations[index].icon)
                                      : destinations[index].icon,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destinations[index].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.1,
                                    color: index == selectedIndex
                                        ? AppColors.primary
                                        : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/auth/screens/change_email_screen.dart
````dart
import '../../../core/widgets/app_page_app_bar.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _linkSent = false;
  bool _isBusy = false;
  Timer? _cooldownTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _linkSent && !_isBusy) {
      _checkNewEmail(quiet: true);
    }
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate() || _isBusy || _resendSeconds > 0) {
      return;
    }
    setState(() => _isBusy = true);
    final error = await _authService.sendEmailChangeLink(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (error == null) {
        _linkSent = true;
        _resendSeconds = 60;
      }
    });
    if (error == null) _startCooldown();
    _showMessage(
      error ?? 'Verification link sent to ${_emailController.text.trim()}.',
      error: error != null,
    );
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _checkNewEmail({bool quiet = false}) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final error = await _authService.refreshEmailChange(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (error == null) {
      _showMessage('Email changed and verified successfully.');
      Navigator.pop(context, true);
    } else if (!quiet) {
      _showMessage(error, error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppPageAppBar(title: const Text('Change Email')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_linkSent
                      ? 'Open the verification link sent to your new email, then return here and confirm.'
                      : 'Firebase will send a verification link to your new email. Your address changes only after you open that link.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    readOnly: _linkSent,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                        labelText: 'New email', border: OutlineInputBorder()),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)
                          ? null
                          : 'Enter a valid email address';
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_linkSent) ...[
                    FilledButton.icon(
                      onPressed: _isBusy ? null : () => _checkNewEmail(),
                      icon: _isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh),
                      label: Text(_isBusy
                          ? 'Checking…'
                          : 'I Have Verified My New Email'),
                    ),
                    TextButton(
                      onPressed:
                          _isBusy || _resendSeconds > 0 ? null : _sendLink,
                      child: Text(_resendSeconds > 0
                          ? 'Resend in ${_resendSeconds}s'
                          : 'Resend verification email'),
                    ),
                  ] else
                    FilledButton(
                      onPressed: _isBusy ? null : _sendLink,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Send Verification Link'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/customer/following/followed_dishes_list.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_grouped.dart';
import '../../../core/models/dish_follow_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/dish_follow_service.dart';
import '../../../core/services/vendor_service.dart';
import '../vendor_details/vendor_details_screen.dart';

class FollowedDishesList extends StatefulWidget {
  const FollowedDishesList({super.key, required this.uid});
  final String uid;

  @override
  State<FollowedDishesList> createState() => _FollowedDishesListState();
}

class _FollowedDishesListState extends State<FollowedDishesList> {
  final _service = DishFollowService();
  Stream<List<DishFollowModel>>? _stream;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(FollowedDishesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) _listen();
  }

  void _listen() {
    final user = FirebaseAuth.instance.currentUser;
    _stream = user?.uid == widget.uid && user?.emailVerified == true
        ? _service.watch(widget.uid)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Verify your email to follow dishes and get restock alerts.',
              textAlign: TextAlign.center));
    }
    return StreamBuilder<List<DishFollowModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Text('Could not load followed dishes.',
                    textAlign: TextAlign.center),
                TextButton(
                    onPressed: () => setState(_listen),
                    child: const Text('Retry')),
              ]));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()));
        }
        final follows = [...?snapshot.data]..sort((a, b) =>
            (b.followedAt ?? DateTime(1970))
                .compareTo(a.followedAt ?? DateTime(1970)));
        if (follows.isEmpty) {
          return const Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                Text('No followed dishes yet',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text(
                    'Open a stall’s menu and tap Follow dish. Your dishes will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8E8E93))),
              ]));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Alerts arrive when a sold-out dish is restocked.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)))),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text('FOLLOWED DISHES · ${follows.length}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
          AppGroupedCard(children: [
            for (var index = 0; index < follows.length; index++) ...[
              _FollowedDishRow(
                  key: ValueKey(follows[index].id),
                  uid: widget.uid,
                  follow: follows[index]),
            ],
          ]),
        ]);
      },
    );
  }
}

class _FollowedDishRow extends StatefulWidget {
  const _FollowedDishRow({super.key, required this.uid, required this.follow});
  final String uid;
  final DishFollowModel follow;
  @override
  State<_FollowedDishRow> createState() => _FollowedDishRowState();
}

class _FollowedDishRowState extends State<_FollowedDishRow> {
  final _service = DishFollowService();
  final _vendors = VendorService();
  late Stream<MenuItemModel?> _dish;
  late Stream<VendorModel?> _vendor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dish = _service.watchDish(widget.follow.vendorId, widget.follow.itemId);
    _vendor = _vendors.watchVendorProfile(widget.follow.vendorId);
  }

  Future<void> _unfollow() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.unfollow(
          widget.uid, widget.follow.vendorId, widget.follow.itemId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not unfollow this dish. Please retry.')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<MenuItemModel?>(
        stream: _dish,
        builder: (context, dishSnapshot) => StreamBuilder<VendorModel?>(
            stream: _vendor,
            builder: (context, vendorSnapshot) {
              final dish = dishSnapshot.data;
              final vendor = vendorSnapshot.data;
              final loading =
                  dishSnapshot.connectionState == ConnectionState.waiting ||
                      vendorSnapshot.connectionState == ConnectionState.waiting;
              final error = dishSnapshot.hasError || vendorSnapshot.hasError;
              final available = dish != null && dish.status != 'out_of_stock';
              final status = loading
                  ? 'Loading…'
                  : error
                      ? 'Could not refresh this dish'
                      : dish == null || vendor == null
                          ? 'No longer available'
                          : dish.status == 'low_stock'
                              ? 'Low stock'
                              : available
                                  ? 'Available'
                                  : 'Sold out · waiting for restock';
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: AppIconTile(
                    icon: Icons.restaurant_rounded,
                    color: available
                        ? AppColors.primary
                        : const Color(0xFF949499)),
                title: Text(
                    dish?.name ??
                        (loading ? 'Loading dish…' : 'Unavailable dish'),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0)),
                subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vendor != null)
                            Text(vendor.stallName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8E8E93),
                                    letterSpacing: 0)),
                          const SizedBox(height: 3),
                          Text(
                              dish != null && !error && !loading
                                  ? '$status · RM ${dish.price.toStringAsFixed(2)}'
                                  : status,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: available && !error
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF8E8E93))),
                        ])),
                trailing: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        tooltip: 'Unfollow dish',
                        onPressed: _unfollow,
                        icon: const Icon(Icons.notifications_active_outlined,
                            color: AppColors.primary)),
                onTap: vendor == null || loading || error
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VendorDetailsScreen(
                                vendor: vendor,
                                initialDishId: widget.follow.itemId))),
              );
            }),
      );
}
````

## File: lib/features/customer/home/open_at_picker.dart
````dart
import 'package:flutter/material.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_grouped.dart';

class OpeningTimeFilter {
  const OpeningTimeFilter(this.start, this.label, {this.end});
  final DateTime start;
  final DateTime? end;
  final String label;
}

Future<OpeningTimeFilter?> showOpeningTimePicker(BuildContext context) async {
  final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('When would you like to visit?',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  'Based on vendor schedules in Malaysia time (MYT). Actual opening may change.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 22),
                AppGroupedCard(children: [
                  ListTile(
                      leading: const AppIconTile(
                          icon: Icons.nightlight_outlined,
                          color: AppColors.primary),
                      title: const Text('After 10 PM tonight'),
                      subtitle: const Text('10 PM to 6 AM'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, 'tonight')),
                  ListTile(
                      leading: const AppIconTile(
                          icon: Icons.wb_sunny_outlined,
                          color: AppColors.primaryLight),
                      title: const Text('Tomorrow morning'),
                      subtitle: const Text('6 AM to 12 PM'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, 'morning')),
                  ListTile(
                      leading: const AppIconTile(
                          icon: Icons.calendar_month, color: AppColors.primary),
                      title: const Text('Choose date and time'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, 'custom')),
                ]),
              ])),
            ),
          ));
  if (choice == null || !context.mounted) return null;
  final now = DateTime.now();
  final local = malaysiaTime(now);
  final today = DateTime(local.year, local.month, local.day);
  final tomorrow = today.add(const Duration(days: 1));
  if (choice == 'tonight') {
    final ten = malaysiaInstant(today.year, today.month, today.day, 22, 0);
    return OpeningTimeFilter(
        ten.isBefore(now) ? now : ten, 'After 10 PM tonight',
        end:
            malaysiaInstant(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0));
  }
  if (choice == 'morning') {
    return OpeningTimeFilter(
        malaysiaInstant(tomorrow.year, tomorrow.month, tomorrow.day, 6, 0),
        'Tomorrow morning',
        end: malaysiaInstant(
            tomorrow.year, tomorrow.month, tomorrow.day, 12, 0));
  }
  final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)));
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
      helpText: 'Visit time (MYT)');
  if (time == null || !context.mounted) return null;
  final instant =
      malaysiaInstant(date.year, date.month, date.day, time.hour, time.minute);
  if (instant.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future date and time.')));
    return null;
  }
  return OpeningTimeFilter(instant,
      '${date.day}/${date.month}/${date.year} · ${formatStallTime(time.hour * 60 + time.minute)} MYT');
}
````

## File: lib/features/shared/booking_payment_card.dart
````dart
import 'package:flutter/material.dart';

import '../../core/models/demo_order.dart';

String bookingPaymentLabel(DemoOrder booking) {
  if (booking.paymentStatus == 'paid' && booking.paymentRefundedCents > 0) {
    return 'Partially refunded';
  }
  return switch (booking.paymentStatus) {
    'paid' => 'Paid',
    'refund_pending' => 'Refund pending',
    'refund_failed' => 'Refund needs attention',
    'refunded' => 'Refunded',
    'failed' => 'Payment failed',
    'expired' => 'Payment window ended',
    'cancelled' => 'Payment cancelled',
    'unpaid' => booking.status == 'requested'
        ? 'Available after acceptance'
        : 'Awaiting payment',
    _ => 'Awaiting payment',
  };
}

class BookingPaymentCard extends StatelessWidget {
  const BookingPaymentCard(
      {super.key,
      required this.booking,
      required this.isVendor,
      this.busy = false,
      this.busyLabel = 'Processing…',
      this.onPay,
      this.onRefresh});

  final DemoOrder booking;
  final bool isVendor;
  final bool busy;
  final String busyLabel;
  final VoidCallback? onPay;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final paid = booking.paymentStatus == 'paid';
    final problem = {'failed', 'refund_failed'}.contains(booking.paymentStatus);
    final color = paid
        ? const Color(0xFF137547)
        : problem
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF9A5B13);
    final remaining = booking.paymentExpiresAt?.difference(DateTime.now());
    final seconds = remaining?.inSeconds.clamp(0, 600) ?? 0;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.credit_card_outlined),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('Payment',
                        style: Theme.of(context).textTheme.titleMedium)),
              ]),
              const SizedBox(height: 8),
              Text('RM ${(booking.totalCents / 100).toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(
                    paid
                        ? Icons.check_circle
                        : problem
                            ? Icons.error_outline
                            : Icons.schedule,
                    size: 19,
                    color: color),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(bookingPaymentLabel(booking),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 10),
              if (booking.status == 'requested')
                const Text('Payment opens when the stall accepts this booking.')
              else if (booking.awaitingPayment)
                Text(seconds > 0
                    ? isVendor
                        ? 'Waiting for the customer to pay. Preparation unlocks after confirmation.'
                        : 'Pay within ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}.'
                    : 'The payment window has ended. Check payment to confirm the final status.'),
              if (booking.paymentStatus == 'refund_pending')
                const Text(
                    'This booking was cancelled. The full refund to the original payment method is pending.')
              else if (booking.paymentStatus == 'refund_failed')
                const Text(
                    'The refund did not complete. Contact support for help.'),
              if (booking.paymentReference != null) ...[
                const SizedBox(height: 10),
                Text('Payment reference',
                    style: Theme.of(context).textTheme.labelSmall),
                SelectableText(booking.paymentReference!,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if (booking.paymentRefundedCents > 0)
                Text(
                    'Refunded: RM ${(booking.paymentRefundedCents / 100).toStringAsFixed(2)}'),
              if (!isVendor && booking.canPay) ...[
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: busy ? null : onPay,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: Text(busy
                            ? busyLabel
                            : 'Pay RM ${(booking.totalCents / 100).toStringAsFixed(2)}'))),
                const SizedBox(height: 8),
                const Text('Complete your payment securely with Stripe.',
                    style: TextStyle(fontSize: 12)),
              ],
              if (booking.paymentStatus != 'unpaid' &&
                  booking.paymentStatus != 'refunded')
                TextButton.icon(
                    onPressed: busy ? null : onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(busy ? 'Checking…' : 'Check payment')),
            ])));
  }
}
````

## File: lib/features/shared/delete_account_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _auth = AuthService();
  final _confirmation = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  bool get _usesPassword =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((provider) => provider.providerId == 'password') ??
      false;

  Future<void> _delete() async {
    if (_busy) return;
    if (_confirmation.text.trim().toUpperCase() != 'DELETE') {
      setState(() => _error = 'Type DELETE to confirm.');
      return;
    }
    if (_usesPassword && _password.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _auth.deleteAccount(
      currentPassword: _usesPassword ? _password.text : null,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  void dispose() {
    _confirmation.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AccountLayout(
        title: 'Delete Account',
        busy: _busy,
        children: [
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.delete_solid,
                color: AppColors.closedRed,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Delete your account?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your StallSeeker account and its data will be permanently removed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 32),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What will be removed',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Text(
                    'Your profile, followed stalls and dishes, notification history, and any vendor stall data.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This cannot be undone.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.closedRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 10),
            child: Text(
              'CONFIRM DELETION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextField(
            controller: _confirmation,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            textInputAction:
                _usesPassword ? TextInputAction.next : TextInputAction.done,
            onSubmitted: _usesPassword ? null : (_) => _delete(),
            decoration: accountField('Type DELETE to confirm'),
          ),
          if (_usesPassword) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _delete(),
              decoration: accountField(
                'Current password',
                suffix: IconButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 9, 16, 0),
            child: Text(
              'Type DELETE exactly to confirm this permanent action.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 22),
          AccountError(_error),
          AccountButton(
            label: 'Delete Account',
            busy: _busy,
            color: AppColors.closedRed,
            onPressed: _delete,
          ),
        ],
      );
}
````

## File: lib/features/shared/edit_profile_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/vendor_phone.dart';
import 'account_ui.dart';
import 'profile_header.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.editPhone = false,
  });

  final String name;
  final String email;
  final String? phoneNumber;
  final bool editPhone;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _auth = AuthService();
  late final TextEditingController _name =
      TextEditingController(text: widget.name);
  late final TextEditingController _phone =
      TextEditingController(text: widget.phoneNumber ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      setState(() => _error = 'Please sign in to edit your profile.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _auth.updateFullName(
      user.uid,
      _name.text.trim(),
      customerPhone: widget.editPhone ? _phone.text : null,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Form(
              key: _form,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  SizedBox(
                    height: 116,
                    child: Stack(alignment: Alignment.topCenter, children: [
                      Positioned(
                        top: 12,
                        child: ProfileAvatar(
                          name: widget.name,
                          photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
                          size: 100,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: ProfileTopAction(
                          label: 'Cancel',
                          onTap: _busy ? null : () => Navigator.pop(context),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: ProfileTopAction(
                          label: _busy ? 'Saving…' : 'Done',
                          onTap: _busy ? null : _save,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 46),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'Full name',
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 19),
                        ),
                        style: const TextStyle(fontSize: 17),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter your name.'
                            : null,
                        onFieldSubmitted: (_) => _save(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'This name appears on your StallSeeker account.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email address',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textMuted)),
                          const SizedBox(height: 5),
                          Text(widget.email,
                              style: const TextStyle(fontSize: 17)),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Your sign-in email cannot be changed here.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.editPhone) ...[
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextFormField(
                          controller: _phone,
                          enabled: !_busy,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: const InputDecoration(
                            labelText: 'Phone number (optional)',
                            hintText: 'Example: 0123456789',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 19),
                          ),
                          validator: (value) {
                            final input = (value ?? '').trim();
                            if (input.isEmpty) return null;
                            return normalizeVendorPhone(input) == null
                                ? 'Enter a valid Malaysian phone number.'
                                : null;
                          },
                          onFieldSubmitted: (_) => _save(),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        'Leave this blank to remove your phone number.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  AccountError(_error),
                ],
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/shared/pin_location_screen.dart
````dart
import '../../core/widgets/app_page_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'manual_location_dialog.dart';

class PinLocationScreen extends StatefulWidget {
  const PinLocationScreen({super.key, required this.initialLocation});
  final LatLng initialLocation;

  @override
  State<PinLocationScreen> createState() => _PinLocationScreenState();
}

class _PinLocationScreenState extends State<PinLocationScreen> {
  GoogleMapController? _controller;
  late LatLng _position = widget.initialLocation;
  String? _address;
  bool _saving = false;
  bool _mapReady = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final location = await showManualLocationDialog(context,
        initialLocation: _position, title: 'Find a place to pin');
    if (!mounted || location == null) return;
    setState(() {
      _position = location.coordinates;
      _address = location.label;
    });
    await _controller
        ?.animateCamera(CameraUpdate.newLatLngZoom(location.coordinates, 17));
  }

  Future<void> _usePin() async {
    setState(() => _saving = true);
    final position = _position;
    var label = _address;
    if (label == null) {
      try {
        label = await describeLocation(position);
      } catch (_) {
        label = '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      }
    }
    if (mounted) {
      Navigator.pop(
          context, LocationSelection(coordinates: position, label: label));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppPageAppBar(title: const Text('Pin a location')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                  onPressed: _saving ? null : _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Search for a place'))),
          Expanded(
              child: Stack(alignment: Alignment.center, children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _position, zoom: 16),
              onMapCreated: (controller) {
                _controller = controller;
                if (mounted) setState(() => _mapReady = true);
              },
              onCameraMove: (camera) {
                if (_saving) return;
                if ((_position.latitude - camera.target.latitude).abs() >
                        .00001 ||
                    (_position.longitude - camera.target.longitude).abs() >
                        .00001) {
                  _address = null;
                }
                _position = camera.target;
              },
              scrollGesturesEnabled: !_saving,
              zoomGesturesEnabled: !_saving,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
            const IgnorePointer(
                child: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.location_pin,
                        size: 48, color: AppColors.primary))),
            const Positioned(
                top: 12,
                left: 20,
                right: 20,
                child: IgnorePointer(
                    child: Card(
                        child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                                'Move the map to place the pin at the exact location.',
                                textAlign: TextAlign.center))))),
          ])),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: _saving || !_mapReady ? null : _usePin,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Use this pin'))))),
        ]),
      );
}
````

## File: lib/features/vendor/dashboard/vendor_dashboard_view.dart
````dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/demo_order.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/utils/vendor_phone.dart';
import '../../shared/booking_payment_card.dart';
import 'vendor_demo_sales.dart';

/// Presentation only; the screen owns subscriptions and business actions.
class VendorDashboardView extends StatelessWidget {
  const VendorDashboardView({
    super.key,
    required this.vendor,
    required this.bookings,
    required this.bookingsLoading,
    required this.bookingsError,
    required this.saving,
    required this.locationSharing,
    required this.locationError,
    required this.busyBookings,
    required this.onRefresh,
    required this.onToggleOpen,
    required this.onToggleSelfCollect,
    required this.onResumeLocation,
    required this.onPreview,
    required this.onEditStall,
    required this.onMenu,
    required this.onStock,
    required this.onBookings,
    required this.onPaymentHistory,
    required this.onOpenBooking,
    required this.onAdvanceBooking,
    this.now,
    this.reviewsCard,
  });

  final VendorModel? vendor;
  final List<DemoOrder> bookings;
  final bool bookingsLoading;
  final bool bookingsError;
  final bool saving;
  final bool locationSharing;
  final String? locationError;
  final Set<String> busyBookings;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onToggleOpen;
  final ValueChanged<bool> onToggleSelfCollect;
  final VoidCallback onResumeLocation;
  final VoidCallback onPreview;
  final VoidCallback onEditStall;
  final VoidCallback onMenu;
  final VoidCallback onStock;
  final VoidCallback onBookings;
  final VoidCallback onPaymentHistory;
  final ValueChanged<DemoOrder> onOpenBooking;
  final ValueChanged<DemoOrder> onAdvanceBooking;
  final DateTime? now;
  final Widget? reviewsCard;

  @override
  Widget build(BuildContext context) {
    final active = bookings.where((booking) => booking.isActive).toList()
      ..sort((a, b) {
        final attention = _priority(a).compareTo(_priority(b));
        if (attention != 0) return attention;
        return (a.createdAt ?? DateTime(1970))
            .compareTo(b.createdAt ?? DateTime(1970));
      });
    final attention = active.where(_needsAction).length;
    final summary = DemoSalesSummary.fromOrders(bookings,
        vendorId: vendor?.vendorId ?? '', now: now ?? DateTime.now());
    final today = _malaysia(now ?? DateTime.now());
    final todaysBookings = bookings.where((booking) {
      if (booking.createdAt == null) return false;
      final created = _malaysia(booking.createdAt!);
      return created.year == today.year &&
          created.month == today.month &&
          created.day == today.day;
    }).length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: const PageStorageKey('vendor-dashboard-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverToBoxAdapter(
                child: Center(
                    child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: LayoutBuilder(builder: (context, constraints) {
                // Follow the window width, including split-screen, and allow
                // extra room when the user enlarges their text.
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
                final wide = constraints.maxWidth >=
                    860 + (textScale - 1).clamp(0, 2) * 240;
                final bookingsSection =
                    _bookingsSection(context, active, attention);
                final quickActions = _quickActions(context, active, wide: wide);
                final overview = _overview(context, summary, todaysBookings);
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(context),
                      const SizedBox(height: 20),
                      _statusCard(context),
                      if (vendor == null ||
                          vendor!.stallName.trim().isEmpty ||
                          normalizeVendorPhone(vendor!.phoneNumber) ==
                              null) ...[
                        const SizedBox(height: 12),
                        _DashboardCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Finish setting up your stall',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text(
                                  'Add your stall name and business phone number before opening.'),
                              TextButton.icon(
                                  onPressed: onEditStall,
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Set up my stall')),
                            ])),
                      ],
                      const SizedBox(height: 20),
                      if (wide)
                        Row(
                            key: const Key('dashboard-two-columns'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: bookingsSection),
                              const SizedBox(width: 20),
                              Expanded(
                                  flex: 4,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        quickActions,
                                        const SizedBox(height: 20),
                                        overview,
                                        if (reviewsCard != null) ...[
                                          const SizedBox(height: 20),
                                          reviewsCard!,
                                        ],
                                      ])),
                            ])
                      else
                        Column(
                            key: const Key('dashboard-single-column'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              quickActions,
                              const SizedBox(height: 20),
                              bookingsSection,
                              const SizedBox(height: 20),
                              overview,
                              if (reviewsCard != null) ...[
                                const SizedBox(height: 20),
                                reviewsCard!,
                              ],
                            ]),
                    ]);
              }),
            ))),
          )
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context, List<DemoOrder> active,
      {required bool wide}) {
    final menu = _QuickAction(
        label: 'Menu', icon: Icons.restaurant_menu_rounded, onTap: onMenu);
    final stock = _QuickAction(
        label: 'Stock', icon: Icons.inventory_2_outlined, onTap: onStock);
    final bookingsAction = _QuickAction(
        label: 'Bookings',
        icon: Icons.receipt_long_outlined,
        count: bookingsError || bookingsLoading
            ? 0
            : active.where((b) => b.vendorNeedsAttention).length,
        onTap: onBookings,
        horizontal: wide);
    return _DashboardCard(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(context, 'Quick actions'),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: menu),
        const SizedBox(width: 10),
        Expanded(child: stock),
        if (!wide) ...[
          const SizedBox(width: 10),
          Expanded(child: bookingsAction)
        ],
      ]),
      if (wide) ...[const SizedBox(height: 10), bookingsAction],
    ]));
  }

  Widget _bookingsSection(
          BuildContext context, List<DemoOrder> active, int attention) =>
      _DashboardCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _heading(context, 'Active bookings'),
                if (!bookingsLoading && !bookingsError && attention > 0) ...[
                  const SizedBox(height: 8),
                  _StatusBadge(
                      label: attention == 1
                          ? '1 needs action'
                          : '$attention need action',
                      color: AppColors.primary),
                ],
              ])),
          TextButton(onPressed: onBookings, child: const Text('View all')),
        ]),
        const SizedBox(height: 14),
        if (bookingsLoading)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(children: [
                LinearProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading bookings…'),
              ]))
        else if (bookingsError)
          Column(children: [
            const Icon(Icons.wifi_off_outlined, color: AppColors.textMuted),
            const SizedBox(height: 8),
            const Text('Could not load bookings.', textAlign: TextAlign.center),
            TextButton(onPressed: onRefresh, child: const Text('Retry')),
          ])
        else if (active.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Column(children: [
                Icon(Icons.receipt_long_outlined,
                    size: 36, color: AppColors.primary),
                SizedBox(height: 12),
                Text('No active bookings',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('New bookings will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted)),
              ]))
        else ...[
          for (final booking in active.take(3))
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _bookingCard(context, booking)),
          if (active.length > 3)
            TextButton(
                onPressed: onBookings,
                child: Text('View ${active.length - 3} more active bookings')),
        ],
      ]));

  static DateTime _malaysia(DateTime time) =>
      time.toUtc().add(const Duration(hours: 8));

  static bool _needsAction(DemoOrder booking) =>
      booking.effectiveStatus == 'requested' ||
      booking.canPrepare ||
      booking.vendorNeedsAttention;

  static int _priority(DemoOrder booking) => _needsAction(booking)
      ? 0
      : booking.effectiveStatus == 'ready'
          ? 1
          : 2;

  Widget _heading(BuildContext context, String title) => Text(title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.w700));

  Widget _header(BuildContext context) {
    final identity = Row(children: [
      Tooltip(
        message: 'Change stall photo',
        child: Semantics(
          label: 'Change stall photo',
          button: true,
          child: InkWell(
            onTap: onEditStall,
            customBorder: const CircleBorder(),
            child: Stack(children: [
              ClipOval(
                  child: SizedBox(
                width: 54,
                height: 54,
                child: vendor?.imageUrl.isNotEmpty == true
                    ? Image.network(vendor!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _stallPlaceholder())
                    : _stallPlaceholder(),
              )),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined,
                      size: 12, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('StallSeeker',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
            vendor?.stallName.trim().isNotEmpty == true
                ? vendor!.stallName
                : 'Your stall',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    ]);
    final actions = Wrap(spacing: 10, runSpacing: 10, children: [
      _headerAction('Preview', Icons.visibility_outlined,
          vendor == null ? null : onPreview),
      _headerAction('Edit stall', Icons.edit_outlined, onEditStall),
    ]);
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 700 ||
          MediaQuery.textScalerOf(context).scale(14) > 19) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          identity,
          const SizedBox(height: 16),
          actions,
        ]);
      }
      return Row(children: [
        Expanded(child: identity),
        const SizedBox(width: 24),
        actions
      ]);
    });
  }

  Widget _headerAction(String label, IconData icon, VoidCallback? onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(48, 46),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _stallPlaceholder() => Container(
      color: AppColors.mint,
      child: const Icon(Icons.storefront_rounded,
          size: 30, color: AppColors.primary));

  Widget _statusCard(BuildContext context) {
    final closedTemporarily = vendor?.isTemporarilyClosed ?? false;
    final open = vendor?.isOpenNow ?? false;
    final statusColor = closedTemporarily
        ? const Color(0xFF946000)
        : open
            ? AppColors.openGreen
            : AppColors.textMuted;
    final locationLabel = !open
        ? 'Location sharing off'
        : locationError ??
            (locationSharing
                ? 'Live location active'
                : 'Location sharing paused');
    final openControl = Row(children: [
      Icon(Icons.circle, color: statusColor, size: 13),
      const SizedBox(width: 10),
      Expanded(
          child: Text(
              closedTemporarily
                  ? 'Temporarily closed'
                  : open
                      ? 'Stall open'
                      : 'Stall closed',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700))),
      const SizedBox(width: 6),
      Semantics(
          label: 'Open stall',
          child: Switch.adaptive(
              activeTrackColor: AppColors.openGreen,
              value: open,
              onChanged: saving || closedTemporarily ? null : onToggleOpen)),
    ]);
    final location =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(
          open && locationError != null
              ? Icons.location_off_outlined
              : Icons.location_on_outlined,
          size: 24,
          color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(locationLabel,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
            !open
                ? 'Open your stall to share its location'
                : locationSharing && locationError == null
                    ? 'Customers can find your stall'
                    : 'Check your location to stay visible',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        if (open && (!locationSharing || locationError != null))
          TextButton.icon(
              onPressed: saving ? null : onResumeLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label:
                  Text(locationSharing ? 'Retry location' : 'Resume sharing')),
      ])),
    ]);
    final collectControl = Row(children: [
      const Icon(Icons.shopping_bag_outlined,
          size: 24, color: AppColors.primary),
      const SizedBox(width: 10),
      const Expanded(
          child: Text('Self-collect bookings',
              style: TextStyle(fontWeight: FontWeight.w600))),
      const SizedBox(width: 6),
      Semantics(
          label: 'Self-collect bookings',
          child: Switch.adaptive(
              activeTrackColor: AppColors.openGreen,
              value: vendor?.selfCollectEnabled ?? false,
              onChanged: saving ? null : onToggleSelfCollect)),
    ]);
    return _DashboardCard(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 820 &&
            MediaQuery.textScalerOf(context).scale(14) <= 19) {
          return IntrinsicHeight(
              child: Row(children: [
            Expanded(child: openControl),
            const VerticalDivider(width: 32),
            Expanded(child: location),
            const VerticalDivider(width: 32),
            Expanded(child: collectControl),
          ]));
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              openControl,
              const SizedBox(height: 10),
              location,
              const Divider(height: 28),
              collectControl,
            ]);
      }),
      if (closedTemporarily)
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                onPressed: onEditStall,
                child: const Text('Manage temporary closure'))),
      if (saving) ...[
        const SizedBox(height: 8),
        const LinearProgressIndicator()
      ],
    ]));
  }

  Widget _bookingCard(BuildContext context, DemoOrder booking) {
    final status = booking.effectiveStatus;
    final review = status == 'requested';
    final canAdvance = booking.canPrepare || status == 'preparing';
    final busy = busyBookings.contains(booking.id);
    final color = status == 'ready'
        ? AppColors.openGreen
        : status == 'preparing'
            ? const Color(0xFF946000)
            : AppColors.primary;
    final label = review
        ? 'Review booking'
        : booking.canPrepare
            ? 'Start preparing'
            : status == 'preparing'
                ? 'Mark ready'
                : 'View booking';
    final action = busy
        ? null
        : () => canAdvance ? onAdvanceBooking(booking) : onOpenBooking(booking);
    final time =
        booking.createdAt == null ? null : _malaysia(booking.createdAt!);
    final timeLabel = time == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(time),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    final button = review || booking.canPrepare
        ? FilledButton(
            onPressed: action,
            style: _bookingButtonStyle(),
            child: Text(busy ? 'Updating…' : label))
        : OutlinedButton(
            onPressed: action,
            style: _bookingButtonStyle(),
            child: Text(busy ? 'Updating…' : label));
    final details =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(booking.customerName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            _StatusBadge(
                label: review ? 'New' : bookingStatusLabel(booking),
                color: color),
          ]),
      const SizedBox(height: 8),
      Text(
          booking.items
              .map((item) => '${item.quantity} × ${item.name}')
              .join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
      if (timeLabel != null) ...[
        const SizedBox(height: 6),
        Text('Booked ${time!.day}/${time.month} at $timeLabel · MYT',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
      if (booking.hasTestPayment) ...[
        const SizedBox(height: 4),
        Text(bookingPaymentLabel(booking),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    ]);
    final amount = Text('RM ${(booking.totalCents / 100).toStringAsFixed(2)}',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
    final avatar = CircleAvatar(
        radius: 22,
        backgroundColor: color.withValues(alpha: .12),
        foregroundColor: color,
        child: Text(
            booking.customerName.trim().isEmpty
                ? '?'
                : booking.customerName.trim().characters.first.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w700)));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 500 &&
            MediaQuery.textScalerOf(context).scale(14) <= 19) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(child: details),
            const SizedBox(width: 14),
            SizedBox(
                width: 166,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.centerRight, child: amount),
                      const SizedBox(height: 12),
                      button,
                    ])),
          ]);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(child: details)
              ]),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: amount),
              const SizedBox(height: 10),
              button,
            ]);
      }),
    );
  }

  ButtonStyle _bookingButtonStyle() => TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));

  Widget _overview(
      BuildContext context, DemoSalesSummary summary, int todaysBookings) {
    return _DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading(context, 'Today’s overview'),
        const SizedBox(height: 4),
        const Text('Malaysia time',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        if (bookingsLoading)
          const LinearProgressIndicator()
        else if (bookingsError)
          const Text('Today’s overview is unavailable. Retry loading bookings.')
        else
          LayoutBuilder(builder: (context, constraints) {
            final sales = _metric(context, 'Sales',
                'RM ${(summary.todayCents / 100).toStringAsFixed(2)}');
            final count = _metric(context, 'Bookings', '$todaysBookings');
            if (constraints.maxWidth < 260 ||
                MediaQuery.textScalerOf(context).scale(14) > 19) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [sales, const SizedBox(height: 16), count]);
            }
            return IntrinsicHeight(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: sales),
                const VerticalDivider(width: 28),
                Expanded(flex: 2, child: count),
              ]),
            );
          }),
        const SizedBox(height: 8),
        const Divider(height: 20),
        TextButton.icon(
            onPressed: onPaymentHistory,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Payment history')),
      ]),
    );
  }

  Widget _metric(BuildContext context, String title, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border.withValues(alpha: .65)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x05000000), blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        child: child,
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.count = 0,
      this.horizontal = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int count;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
        child: Icon(icon, color: AppColors.primary, size: 27));
    final text = Text(label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600));
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontal ? 14 : 6, vertical: 18),
            child: horizontal
                ? Row(children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft, child: text)),
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.primary)
                  ])
                : Column(
                    children: [iconWidget, const SizedBox(height: 12), text]),
          )),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}
````

## File: lib/features/vendor/dashboard/vendor_demo_sales.dart
````dart
import '../../../core/widgets/app_page_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/demo_order.dart';
import '../../../core/services/demo_order_service.dart';
import '../../shared/booking_detail_screen.dart';
import '../../shared/booking_payment_card.dart';

class DemoSalesSummary {
  const DemoSalesSummary(
      {required this.todayCents,
      required this.totalCents,
      required this.paidOrders});
  final int todayCents;
  final int totalCents;
  final int paidOrders;

  factory DemoSalesSummary.fromOrders(List<DemoOrder> orders,
      {required String vendorId, required DateTime now}) {
    DateTime malaysia(DateTime value) =>
        value.toUtc().add(const Duration(hours: 8));
    final today = malaysia(now);
    var daily = 0;
    var total = 0;
    var count = 0;
    for (final order in orders) {
      if (order.vendorId != vendorId ||
          order.demoSalesCents <= 0 ||
          order.paymentPaidAt == null) {
        continue;
      }
      total += order.demoSalesCents;
      count++;
      final paid = malaysia(order.paymentPaidAt!);
      if (paid.year == today.year &&
          paid.month == today.month &&
          paid.day == today.day) {
        daily += order.demoSalesCents;
      }
    }
    return DemoSalesSummary(
        todayCents: daily, totalCents: total, paidOrders: count);
  }
}

class VendorDemoSales extends StatefulWidget {
  const VendorDemoSales({super.key});
  @override
  State<VendorDemoSales> createState() => _VendorDemoSalesState();
}

class _VendorDemoSalesState extends State<VendorDemoSales> {
  late final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final _orders = DemoOrderService().watchVendorOrders(_uid);

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: StreamBuilder<List<DemoOrder>>(
            stream: _orders,
            builder: (context, snapshot) {
              final summary = DemoSalesSummary.fromOrders(snapshot.data ?? [],
                  vendorId: _uid, now: DateTime.now());
              return DemoSalesCard(
                  summary: summary,
                  loading: !snapshot.hasData,
                  hasError: snapshot.hasError,
                  onHistory: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VendorPaymentHistoryScreen())));
            }));
  }
}

class DemoSalesCard extends StatelessWidget {
  const DemoSalesCard(
      {super.key,
      required this.summary,
      required this.onHistory,
      this.loading = false,
      this.hasError = false});
  final DemoSalesSummary summary;
  final VoidCallback onHistory;
  final bool loading;
  final bool hasError;

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.payments_outlined),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Sales',
                      style: Theme.of(context).textTheme.titleLarge)),
            ]),
            const SizedBox(height: 12),
            if (hasError)
              const Text('Sales could not load. Check your connection.')
            else if (loading)
              const LinearProgressIndicator()
            else ...[
              const Text('Today · Malaysia time'),
              const SizedBox(height: 4),
              Text('RM ${(summary.todayCents / 100).toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  '${summary.paidOrders} paid orders · RM ${(summary.totalCents / 100).toStringAsFixed(2)} total'),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View payment history')),
          ])));
}

class VendorPaymentHistoryScreen extends StatefulWidget {
  const VendorPaymentHistoryScreen({super.key});
  @override
  State<VendorPaymentHistoryScreen> createState() =>
      _VendorPaymentHistoryScreenState();
}

class _VendorPaymentHistoryScreenState
    extends State<VendorPaymentHistoryScreen> {
  late final _orders = DemoOrderService()
      .watchVendorOrders(FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppPageAppBar(title: const Text('Payment history')),
      body: StreamBuilder<List<DemoOrder>>(
          stream: _orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Payments could not load. Please retry.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = snapshot.data!
                .where((order) =>
                    order.hasTestPayment && order.paymentStatus != 'unpaid')
                .toList();
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (orders.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'No payments yet. Paid bookings will appear here.')),
              for (final order in orders)
                Card(
                    child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(order.customerName),
                        subtitle: Text(bookingPaymentLabel(order)),
                        trailing: Text(
                            'RM ${(order.totalCents / 100).toStringAsFixed(2)}'),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookingDetailScreen(
                                    bookingId: order.id, isVendor: true))))),
            ]);
          }));
}
````

## File: lib/features/vendor/profile/stall_schedule_editor.dart
````dart
import 'package:flutter/material.dart';
import '../../../core/models/stall_schedule.dart';

class StallScheduleEditor extends StatelessWidget {
  const StallScheduleEditor(
      {super.key,
      required this.hours,
      required this.closures,
      required this.onChanged,
      this.showHours = true,
      this.showClosures = true,
      this.showSectionTitles = true});

  final Map<int, List<StallHoursInterval>> hours;
  final List<TemporaryClosure> closures;
  final bool showHours;
  final bool showClosures;
  final bool showSectionTitles;
  final void Function(
      Map<int, List<StallHoursInterval>>, List<TemporaryClosure>) onChanged;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Map<int, List<StallHoursInterval>> _copyHours() => {
        for (var day = 1; day <= 7; day++) day: [...?hours[day]],
      };

  Future<void> _pickTime(BuildContext context, int day, int index,
      {required bool opening}) async {
    final interval = hours[day]![index];
    final current = opening ? interval.openMinute : interval.closeMinute;
    final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60));
    if (picked == null || !context.mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    if (minutes == (opening ? interval.closeMinute : interval.openMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Opening and closing times must be different.')));
      return;
    }
    final next = _copyHours();
    next[day]![index] = StallHoursInterval(
      opening ? minutes : interval.openMinute,
      opening ? interval.closeMinute : minutes,
    );
    onChanged(next, closures);
  }

  Future<DateTime?> _pickDateTime(
      BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 730)));
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    // The stall operates in Malaysia time, independently of device timezone.
    return DateTime.utc(
        date.year, date.month, date.day, time.hour - 8, time.minute);
  }

  Future<void> _addClosure(BuildContext context) async {
    if (closures.length >= 20) return;
    final nowMy = DateTime.now().toUtc().add(const Duration(hours: 8));
    final start = await _pickDateTime(context, nowMy);
    if (start == null || !context.mounted) return;
    final end = await _pickDateTime(
        context, start.toUtc().add(const Duration(hours: 18)));
    if (end == null || !context.mounted) return;
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Closure end must be after its start.')));
      return;
    }
    onChanged(
        hours,
        [...closures, TemporaryClosure(start, end)]
          ..sort((a, b) => a.start.compareTo(b.start)));
  }

  String _formatClosure(DateTime value) {
    final my = value.toUtc().add(const Duration(hours: 8));
    return '${my.day}/${my.month}/${my.year} ${formatStallTime(my.hour * 60 + my.minute)}';
  }

  Widget _timeInterval(BuildContext context, int day, int index) {
    final interval = hours[day]![index];
    final opens = OutlinedButton(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
        onPressed: () => _pickTime(context, day, index, opening: true),
        child: Text('Opens ${formatStallTime(interval.openMinute)}',
            textAlign: TextAlign.center));
    final closes = OutlinedButton(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
        onPressed: () => _pickTime(context, day, index, opening: false),
        child: Text('Closes ${formatStallTime(interval.closeMinute)}',
            textAlign: TextAlign.center));
    final remove = IconButton(
        tooltip: 'Remove time',
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: const Icon(Icons.close),
        onPressed: () {
          final next = _copyHours();
          next[day]!.removeAt(index);
          onChanged(next, closures);
        });
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 400 ||
              MediaQuery.textScalerOf(context).scale(14) > 19) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  opens,
                  const SizedBox(height: 8),
                  closes,
                  Align(alignment: Alignment.centerRight, child: remove),
                ]);
          }
          return Row(children: [
            Expanded(child: opens),
            const SizedBox(width: 8),
            Expanded(child: closes),
            remove
          ]);
        }));
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHours) ...[
            if (showSectionTitles) ...[
              Text('Weekly opening hours',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
            ],
            const Text(
                'Planned hours · Malaysia time. Manage your live Open / Closed status from the dashboard.'),
            const SizedBox(height: 12),
            for (var day = 1; day <= 7; day++) ...[
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_days[day - 1]),
                  subtitle:
                      Text((hours[day] ?? []).isEmpty ? 'Closed' : 'Scheduled'),
                  value: (hours[day] ?? []).isNotEmpty,
                  onChanged: (enabled) {
                    final next = _copyHours();
                    next[day] = enabled
                        ? [const StallHoursInterval(9 * 60, 17 * 60)]
                        : [];
                    onChanged(next, closures);
                  }),
              for (var index = 0; index < (hours[day] ?? []).length; index++)
                _timeInterval(context, day, index),
              if ((hours[day] ?? []).isNotEmpty && hours[day]!.length < 3)
                Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                        style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48)),
                        onPressed: () {
                          final next = _copyHours();
                          next[day]!
                              .add(const StallHoursInterval(18 * 60, 22 * 60));
                          onChanged(next, closures);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add time'))),
              if (day < 7) const Divider(height: 16),
            ],
          ],
          if (showHours && showClosures) const SizedBox(height: 20),
          if (showClosures) ...[
            if (showSectionTitles) ...[
              Text('Temporary closures',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
            ],
            const Text(
                'Plan breaks or days off. Your stall closes during these dates. Reopen it from the dashboard afterward.'),
            const SizedBox(height: 12),
            if (closures.isEmpty)
              const Text('No temporary closures scheduled.'),
            for (var index = 0; index < closures.length; index++)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${_formatClosure(closures[index].start)} –'),
                  subtitle: Text(_formatClosure(closures[index].end)),
                  trailing: IconButton(
                      tooltip: 'Remove closure',
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        final next = [...closures]..removeAt(index);
                        onChanged(hours, next);
                      })),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed:
                    closures.length >= 20 ? null : () => _addClosure(context),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add closure')),
          ],
        ],
      );
}
````

## File: lib/core/models/menu_item_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String itemId;
  final String name;
  final double price;
  final String
      status; // 'available' (Green), 'low_stock' (Yellow), 'out_of_stock' (Red)
  final String imageUrl;
  final String section;
  final DateTime? statusUpdatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String description;
  final String portionSize;
  final List<String> ingredients;

  MenuItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    this.status = 'available',
    this.imageUrl = '',
    this.section = 'Main menu',
    this.statusUpdatedAt,
    this.createdAt,
    this.updatedAt,
    this.description = '',
    this.portionSize = '',
    this.ingredients = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'status': status,
      'imageUrl': imageUrl,
      'section': section,
      'description': description,
      'portionSize': portionSize,
      'ingredients': ingredients,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'statusUpdatedAt': statusUpdatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(statusUpdatedAt!),
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuItemModel(
      itemId: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'available',
      imageUrl: map['imageUrl'] ?? '',
      section: (map['section'] as String?)?.trim().isNotEmpty == true
          ? map['section'] as String
          : 'Main menu',
      statusUpdatedAt: (map['statusUpdatedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      description: map['description'] as String? ?? '',
      portionSize: map['portionSize'] as String? ?? '',
      ingredients: map['ingredients'] is List
          ? (map['ingredients'] as List).whereType<String>().toList()
          : const [],
    );
  }
}
````

## File: lib/core/services/storage_service.dart
````dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Opens the gallery picker. Returns null if the vendor backed out
  // without choosing anything.
  Future<File?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null) {
      return null;
    }
    return File(picked.path);
  }

  // Uploads a stall's cover photo. Always uses the same file name per
  // vendor, so re-uploading overwrites the old photo instead of leaving
  // unused files in Storage.
  Future<String> uploadStallImage(String vendorId, File imageFile) async {
    final ref = _storage.ref().child('stall_images/$vendorId.jpg');
    final upload = await ref.putFile(imageFile);
    final url = Uri.parse(await ref.getDownloadURL());
    // Reusing the storage object must still refresh Image.network caches.
    return url.replace(queryParameters: {
      ...url.queryParameters,
      'v': upload.metadata?.generation ??
          DateTime.now().microsecondsSinceEpoch.toString(),
    }).toString();
  }

  // Uploads a photo for one menu item. Named by itemId so each dish has
  // its own file, and re-uploading a photo for the same dish overwrites it.
  Future<String> uploadMenuItemImage(
    String vendorId,
    String itemId,
    File imageFile,
  ) async {
    final ref = _storage.ref().child('menu_images/$vendorId/$itemId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<List<File>> pickReviewImages(int remaining) async {
    final picked =
        await _picker.pickMultiImage(maxWidth: 1080, imageQuality: 75);
    return picked
        .take(remaining.clamp(0, 5))
        .map((image) => File(image.path))
        .toList();
  }

  Future<String> uploadReviewImage(String vendorId, String customerId,
      String imageId, File imageFile) async {
    final ref = _storage
        .ref()
        .child('review_images/$vendorId/$customerId/$imageId.jpg');
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }

  Future<void> deleteReviewImageUrl(
      String vendorId, String customerId, String url) async {
    final ref = _storage.refFromURL(url);
    if (!ref.fullPath.startsWith('review_images/$vendorId/$customerId/')) {
      throw ArgumentError('Review photo does not belong to this customer.');
    }
    await ref.delete();
  }
}
````

## File: lib/features/customer/home/price_range_picker.dart
````dart
import '../../../core/widgets/app_sheet_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import 'discovery_search_filters.dart';

Future<MenuPriceRange?> showPriceRangePicker(
  BuildContext context, {
  MenuPriceRange? initialRange,
}) =>
    showModalBottomSheet<MenuPriceRange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _PriceRangePicker(initialRange: initialRange),
    );

class _PriceRangePicker extends StatefulWidget {
  const _PriceRangePicker({this.initialRange});

  final MenuPriceRange? initialRange;

  @override
  State<_PriceRangePicker> createState() => _PriceRangePickerState();
}

class _PriceRangePickerState extends State<_PriceRangePicker> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;

  @override
  void initState() {
    super.initState();
    _minimum = TextEditingController(
        text: widget.initialRange?.minimum?.toStringAsFixed(2) ?? '');
    _maximum = TextEditingController(
        text: widget.initialRange?.maximum?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  String? _validateAmount(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final amount = double.tryParse(text);
    if (amount == null || !amount.isFinite || amount < 0) {
      return 'Enter a valid price';
    }
    return null;
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      MenuPriceRange(
        minimum: double.tryParse(_minimum.text),
        maximum: double.tryParse(_maximum.text),
      ),
    );
  }

  Widget _amountField(TextEditingController controller,
          {required bool isMax}) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: isMax ? TextInputAction.done : TextInputAction.next,
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) =>
              RegExp(r'^\d*(\.\d{0,2})?$').hasMatch(newValue.text)
                  ? newValue
                  : oldValue),
        ],
        decoration: InputDecoration(
          labelText: isMax ? 'Maximum' : 'Minimum',
          hintText: 'Any',
          prefixText: 'RM ',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          final error = _validateAmount(value);
          if (error != null || !isMax) return error;
          final min = double.tryParse(_minimum.text);
          final max = double.tryParse(value ?? '');
          if (min != null && max != null && max < min) {
            return 'Must be at least the minimum';
          }
          return null;
        },
        onFieldSubmitted: isMax ? (_) => _apply() : null,
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSheetHeader(
                      title: Text('Dish price range'),
                      padding: EdgeInsets.zero),
                  const SizedBox(height: 8),
                  const Text(
                    'Find stalls with a dish in your budget. Leave a price blank for any amount.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _amountField(_minimum, isMax: false)),
                    const SizedBox(width: 12),
                    Expanded(child: _amountField(_maximum, isMax: true)),
                  ]),
                  const SizedBox(height: 24),
                  Row(children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, const MenuPriceRange()),
                      child: const Text('Reset'),
                    ),
                    const Spacer(),
                    Flexible(
                        child: FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply price range'),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/shared/about_screen.dart
````dart
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'info_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.65,
              color: Color(0xFF52525A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoPage(
      title: 'About StallSeeker',
      children: [
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/app_logo.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
                semanticLabel: 'StallSeeker logo',
              ),
              const SizedBox(height: 16),
              const Text(
                'StallSeeker',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Version 1.0.3',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _section(
          'Why StallSeeker exists',
          'Food stalls do not always operate from one fixed location or '
              'keep the same menu throughout the day. A stall may close early, '
              'move to another spot, or sell out of a dish. StallSeeker helps '
              'customers check vendor-provided details before making the trip.',
        ),
        _section(
          'Finding a stall',
          'Customers can explore stalls on a map, search for dishes, and '
              'filter results by location, category, distance, price, and '
              'opening status. Stall pages show information such as the menu, '
              'availability, reviews, and directions. Customers can also '
              'follow stalls or dishes for updates and request self-collect '
              'bookings where available.',
        ),
        _section(
          'Managing a stall',
          'Vendors can update their stall details, business hours, and '
              'temporary closures. They can add menu items, change prices, '
              'upload images, and mark items as out of stock. When their stall '
              'is open, they can share its current location and manage '
              'booking requests from customers.',
        ),
        _section(
          'Guest and account access',
          'Visitors can browse as guests without creating an account. '
              'Signing in allows the app to keep account-based information, '
              'such as followed stalls and dishes and booking activity, '
              'connected to the same user.',
        ),
        _section(
          'Checking the latest details',
          'Stall information is managed by vendors and can change during '
              'service. Opening status, location, prices, and availability '
              'should be checked again before travelling for a particular '
              'stall or dish.',
        ),
        const Divider(
          height: 1,
          color: Color(0xFFEEEEEE),
        ),
        const SizedBox(height: 20),
        const Text(
          'Find your next favourite stall with StallSeeker.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
````

## File: lib/features/shared/demo_orders_screen.dart
````dart
import '../../core/widgets/app_page_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import 'booking_detail_screen.dart';

class DemoOrdersScreen extends StatefulWidget {
  const DemoOrdersScreen(
      {super.key, required this.isVendor, this.accountId, this.liveBookings});
  final bool isVendor;
  final String? accountId;
  final Stream<List<DemoOrder>>? liveBookings;

  @override
  State<DemoOrdersScreen> createState() => _DemoOrdersScreenState();
}

class _DemoOrdersScreenState extends State<DemoOrdersScreen> {
  late final _service = DemoOrderService();
  late final String _uid =
      widget.accountId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<DemoOrder>> _live = widget.liveBookings ??
      (widget.isVendor
          ? _service.watchVendorOrders(_uid)
          : _service.watchCustomerOrders(_uid));

  Widget _list(List<DemoOrder> bookings) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings in this section yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingSummaryCard(
          booking: booking,
          isVendor: widget.isVendor,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(
                      bookingId: booking.id, isVendor: widget.isVendor))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppPageAppBar(
            title: Text(widget.isVendor ? 'Stall bookings' : 'My bookings'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E2E7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.textDark,
                    unselectedLabelColor: AppColors.textMuted,
                    tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
                  ),
                ),
              ),
            ),
          ),
          body: StreamBuilder<List<DemoOrder>>(
            stream: _live,
            builder: (context, snapshot) {
              final active =
                  snapshot.data?.where((item) => item.isActive).toList() ??
                      const <DemoOrder>[];
              final history =
                  snapshot.data?.where((item) => !item.isActive).toList() ??
                      const <DemoOrder>[];
              final unavailable = snapshot.hasError
                  ? const Center(
                      child: Text(
                          'Could not load bookings. Check your connection and try again.'))
                  : const Center(child: CircularProgressIndicator());
              return TabBarView(children: [
                snapshot.hasData ? _list(active) : unavailable,
                snapshot.hasData ? _list(history) : unavailable,
              ]);
            },
          ),
        ),
      );
}
````

## File: lib/features/shared/notification_settings_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import 'account_ui.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _enabled = true;
  bool _busy = true;
  AuthorizationStatus _systemStatus = AuthorizationStatus.notDetermined;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Sign in to manage notifications.';
        });
      }
      return;
    }
    try {
      final values = await Future.wait([
        NotificationService.instance.isEnabledForCurrentUser(),
        FirebaseMessaging.instance.getNotificationSettings(),
      ]);
      if (mounted) {
        setState(() {
          _enabled = values[0] as bool;
          _systemStatus =
              (values[1] as NotificationSettings).authorizationStatus;
          _busy = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not load notification settings.';
        });
      }
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error =
        await NotificationService.instance.setEnabledForCurrentUser(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        _enabled = value;
      } else {
        _error = error;
      }
    });
    if (error == null) {
      await _load();
    }
  }

  String get _permissionText {
    if (_systemStatus == AuthorizationStatus.authorized) {
      return 'Allowed by this device';
    }
    if (_systemStatus == AuthorizationStatus.provisional) {
      return 'Quiet notifications allowed';
    }
    if (_systemStatus == AuthorizationStatus.denied) {
      return 'Blocked in phone settings';
    }
    return 'Permission not requested';
  }

  @override
  Widget build(BuildContext context) => AccountLayout(
        title: 'Notifications',
        busy: _busy,
        background: AppColors.background,
        children: [
          Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(26)),
              child: SwitchListTile.adaptive(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                activeThumbColor: AppColors.primary,
                value: _enabled,
                onChanged: _busy ? null : _toggle,
                secondary: const Icon(Icons.notifications_active_outlined,
                    color: AppColors.primary),
                title: const Text('Stall & dish notifications',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                        'Get an alert when a followed stall opens or a followed dish is restocked.')),
              )),
          const SizedBox(height: 22),
          Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(26)),
              child: Row(children: [
                const Icon(Icons.phone_android_rounded,
                    color: Color(0xFF8E8E93)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Device permission',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(_permissionText,
                          style: const TextStyle(color: Color(0xFF707078))),
                    ])),
              ])),
          if (_systemStatus == AuthorizationStatus.denied) ...[
            const SizedBox(height: 12),
            const Text(
                'Allow notifications in your phone settings, then return to StallSeeker.',
                style: TextStyle(color: Color(0xFF707078), height: 1.4)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            AccountError(_error),
          ],
          const SizedBox(height: 18),
          const Text(
              'Notification history stays in the app even when alerts are turned off.',
              style: TextStyle(
                  fontSize: 13, height: 1.45, color: Color(0xFF8E8E93))),
        ],
      );
}
````

## File: lib/features/splash/splash_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_logo.png', width: 104, height: 104),
            const SizedBox(height: 20),
            const Text(
              'StallSeeker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find nearby food stalls, live.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/core/models/user_model.dart
````dart
class UserModel { // represent 1 registered user
  final String uid;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role; // 'customer' or 'vendor'
  final DateTime createdAt;
  final double? customerLatitude; // ni yang save custtomer location
  final double? customerLongitude; // ni jugak
  final String? customerLocationLabel; // dan ini
  final bool customerLocationIsManual;  //ini kalau manual / xletak apa2 (nu;ll)

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.customerLatitude,
    this.customerLongitude,
    this.customerLocationLabel,
    this.customerLocationIsManual = false,
  });

  bool get hasCustomerLocation => // check cust location valid or tak
      customerLatitude != null &&
      customerLongitude != null &&
      customerLatitude!.isFinite &&
      customerLongitude!.isFinite &&
      customerLatitude! >= -90 &&
      customerLatitude! <= 90 &&
      customerLongitude! >= -180 &&
      customerLongitude! <= 180;

  // Convert Firestore Document to UserModel Object
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final customerLocation = map['customerLocation'];
    return UserModel(
      uid: docId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] as String?,
      role: map['role'] ?? 'customer',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      customerLatitude: customerLocation is Map
          ? (customerLocation['latitude'] as num?)?.toDouble()
          : null,
      customerLongitude: customerLocation is Map
          ? (customerLocation['longitude'] as num?)?.toDouble()
          : null,
      customerLocationLabel:
          customerLocation is Map ? customerLocation['label'] as String? : null,
      customerLocationIsManual: customerLocation is Map
          ? customerLocation['isManual'] == true
          : false,
    );
  }

  // Convert UserModel Object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'fullName': fullName,
      if (phoneNumber != null && phoneNumber!.isNotEmpty)
        'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': createdAt,
      if (hasCustomerLocation)
        'customerLocation': {
          'latitude': customerLatitude,
          'longitude': customerLongitude,
          'label': customerLocationLabel ?? 'Selected location',
          'isManual': customerLocationIsManual,
        },
    };
  }
}
````

## File: lib/features/shared/account_ui.dart
````dart
import '../../core/widgets/app_page_app_bar.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared spacing, fields and actions for account pages.
class AccountLayout extends StatelessWidget {
  const AccountLayout(
      {super.key,
      required this.title,
      required this.children,
      this.busy = false,
      this.background = AppColors.background});
  final String title;
  final List<Widget> children;
  final bool busy;
  final Color background;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !busy,
        child: Scaffold(
          backgroundColor: background,
          appBar: AppPageAppBar(
            title: Text(title),
            centerTitle: true,
            backgroundColor: background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                letterSpacing: 0),
            showBackButton: true,
            backEnabled: !busy,
          ),
          body: SafeArea(
              top: false,
              child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: children)))),
        ),
      );
}

class AccountIntro extends StatelessWidget {
  const AccountIntro(
      {super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: AppColors.mint, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 30)),
        const SizedBox(height: 24),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.3)),
        const SizedBox(height: 10),
        Text(body,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, height: 1.5, color: Color(0xFF707078))),
        const SizedBox(height: 32),
      ]);
}

InputDecoration accountField(String label, {Widget? suffix, String? helper}) =>
    InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
      errorMaxLines: 3,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF707078), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: AppColors.primary)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: Color(0xFFB3261E))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5)),
    );

class AccountButton extends StatelessWidget {
  const AccountButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.busy = false,
      this.color = AppColors.primary});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              minimumSize: const Size(48, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28))),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600))));
}

class AccountError extends StatelessWidget {
  const AccountError(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Semantics(
              liveRegion: true,
              child: Text(message!,
                  style:
                      const TextStyle(color: Color(0xFFB3261E), height: 1.4))));
}
````

## File: lib/features/shared/manual_location_dialog.dart
````dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/place_search_service.dart';
import '../../core/widgets/ios_grouped.dart';

export '../../core/services/place_search_service.dart'
    show LocationSelection, PlaceSuggestion;

Future<LocationSelection?> showManualLocationDialog(
  BuildContext context, {
  LatLng? initialLocation,
  String title = 'Enter Location Manually',
  PlaceSearchService? placeSearch,
}) {
  return showDialog<LocationSelection>(
    context: context,
    builder: (_) => _ManualLocationDialog(
      title: title,
      initialLocation: initialLocation,
      placeSearch: placeSearch,
    ),
  );
}

Future<String> describeLocation(LatLng coordinates) async {
  final placemarks = await Geocoding()
      .placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      )
      .timeout(const Duration(seconds: 8));

  if (placemarks.isEmpty) return 'Selected location';

  return _formatPlacemark(placemarks.first);
}

String _formatPlacemark(Placemark placemark) {
  final candidates = <String?>[
    placemark.name,
    placemark.subLocality,
    placemark.locality,
    placemark.subAdministrativeArea,
    placemark.administrativeArea,
    placemark.postalCode,
    placemark.country,
  ];

  final parts = <String>[];
  final seen = <String>{};

  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';

    if (value.isNotEmpty && seen.add(value.toLowerCase())) {
      parts.add(value);
    }
  }

  return parts.isEmpty ? 'Selected location' : parts.join(', ');
}

class _ManualLocationDialog extends StatefulWidget {
  const _ManualLocationDialog({
    required this.title,
    required this.initialLocation,
    this.placeSearch,
  });

  final String title;
  final LatLng? initialLocation;
  final PlaceSearchService? placeSearch;

  @override
  State<_ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<_ManualLocationDialog> {
  final _placeController = TextEditingController();

  late final _placeSearch = widget.placeSearch ?? PlaceSearchService();

  Timer? _debounce;

  List<PlaceSuggestion> _suggestions = const [];
  LocationSelection? _selection;

  String? _errorText;
  String? _fallbackMessage;

  bool _isSearching = false;
  bool _isFetchingCoords = false;
  bool _usingDeviceFallback = false;

  int _requestId = 0;

  bool _isCurrent(int requestId) => mounted && requestId == _requestId;

  @override
  void dispose() {
    _requestId++;
    _debounce?.cancel();
    _placeController.dispose();

    if (widget.placeSearch == null) {
      _placeSearch.dispose();
    }

    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _requestId++;

    setState(() {
      _selection = null;
      _suggestions = const [];
      _errorText = null;
      _fallbackMessage = null;
      _usingDeviceFallback = false;
      _isSearching = false;
      _isFetchingCoords = false;
    });

    final query = value.trim();
    if (query.length < 2) return;

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _findSuggestions(query),
    );
  }

  Future<void> _findSuggestions(String value) async {
    _debounce?.cancel();

    final query = value.trim();
    if (!mounted || query.length < 2) return;

    final requestId = ++_requestId;

    setState(() {
      _isSearching = true;
      _isFetchingCoords = false;
      _selection = null;
      _suggestions = const [];
      _errorText = null;
      _fallbackMessage = null;
      _usingDeviceFallback = false;
    });

    var googleFailed = false;
    List<PlaceSuggestion> results = const [];

    try {
      results = await _placeSearch.search(query);
    } catch (_) {
      // The service logs the actual Google Places error.
      googleFailed = true;
    }

    if (!_isCurrent(requestId)) return;

    if (results.isNotEmpty) {
      setState(() {
        _suggestions = results.take(5).toList();
        _isSearching = false;
      });
      return;
    }

    final fallbackResults = await _findDeviceSuggestions(query, requestId);

    if (!_isCurrent(requestId)) return;

    setState(() {
      _isSearching = false;
      _usingDeviceFallback = true;
      _suggestions = fallbackResults;

      if (fallbackResults.isNotEmpty) {
        _fallbackMessage = googleFailed
            ? 'Google search is unavailable. These are limited device '
                'results; check the address before selecting.'
            : 'No Google suggestions found. Showing limited device results.';
      } else {
        _errorText = googleFailed
            ? 'Location search is unavailable. Try again or check '
                'your connection.'
            : 'No matching places found. Try a more specific name, '
                'such as Bukit Bintang, Kuala Lumpur.';
      }
    });
  }

  Future<List<PlaceSuggestion>> _findDeviceSuggestions(
    String query,
    int requestId,
  ) async {
    try {
      final searchQuery =
          query.toLowerCase().contains('malaysia') ? query : '$query, Malaysia';

      final locations = await Geocoding()
          .locationFromAddress(searchQuery)
          .timeout(const Duration(seconds: 8));

      if (!_isCurrent(requestId)) return [];

      final ordered = List<Location>.from(locations);
      final origin = widget.initialLocation;

      if (origin != null) {
        ordered.sort(
          (a, b) => _distanceSquared(a, origin)
              .compareTo(_distanceSquared(b, origin)),
        );
      }

      final suggestions = <PlaceSuggestion>[];
      final seen = <String>{};

      for (final location in ordered.take(3)) {
        if (!_isCurrent(requestId)) return [];

        final coordinates = LatLng(
          location.latitude,
          location.longitude,
        );

        String label;

        try {
          label = await describeLocation(coordinates);
        } catch (_) {
          label = '$query '
              '(${coordinates.latitude.toStringAsFixed(5)}, '
              '${coordinates.longitude.toStringAsFixed(5)})';
        }

        if (!_isCurrent(requestId)) return [];

        if (seen.add(label.toLowerCase())) {
          suggestions.add(
            PlaceSuggestion(
              placeId: '',
              primaryText: label,
              secondaryText: 'Device result',
              fullText: label,
              coordinates: coordinates,
            ),
          );
        }
      }

      return suggestions;
    } catch (error) {
      debugPrint('Device location search failed: $error');
      return [];
    }
  }

  double _distanceSquared(Location location, LatLng origin) {
    final latitude = location.latitude - origin.latitude;
    final longitude = location.longitude - origin.longitude;

    return latitude * latitude + longitude * longitude;
  }

  Future<void> _handleSuggestionTap(
    PlaceSuggestion suggestion,
  ) async {
    _debounce?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();

    final requestId = ++_requestId;

    if (suggestion.coordinates != null) {
      _selectSuggestion(
        LocationSelection(
          coordinates: suggestion.coordinates!,
          label: suggestion.fullText,
        ),
      );
      return;
    }

    setState(() {
      _selection = null;
      _isSearching = false;
      _isFetchingCoords = true;
      _errorText = null;
    });

    try {
      final coordinates = await _placeSearch.getCoordinates(suggestion.placeId);

      if (!_isCurrent(requestId)) return;

      if (coordinates == null) {
        setState(() {
          _isFetchingCoords = false;
          _errorText =
              'Could not load this place. Please select another result.';
        });
        return;
      }

      _selectSuggestion(
        LocationSelection(
          coordinates: coordinates,
          label: suggestion.fullText,
        ),
      );
    } catch (_) {
      if (!_isCurrent(requestId)) return;

      setState(() {
        _isFetchingCoords = false;
        _errorText = 'Could not load location details. Please try again.';
      });
    }
  }

  void _selectSuggestion(LocationSelection selection) {
    if (!mounted) return;

    setState(() {
      _selection = selection;
      _isSearching = false;
      _isFetchingCoords = false;
      _errorText = null;
    });
  }

  void _submit() {
    final selection = _selection;
    if (selection == null) return;

    _requestId++;
    _debounce?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.pop(context, selection);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSearching || _isFetchingCoords;

    return AlertDialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      scrollable: true,
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search for a place in Malaysia, then select its address.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _placeController,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: _findSuggestions,
              decoration: InputDecoration(
                labelText: 'Search location',
                hintText: 'Bukit Bintang, Kuala Lumpur',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: busy
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppGroupedCard(
                dividerIndent: 56,
                children: [
                  for (final suggestion in _suggestions)
                    _suggestionTile(suggestion),
                ],
              ),
            ],
            if (_isFetchingCoords)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Getting location details…',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            if (_fallbackMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _fallbackMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.closedRed,
                ),
              ),
            ],
            if (_usingDeviceFallback && !busy)
              TextButton(
                onPressed: () => _findSuggestions(_placeController.text),
                child: const Text('Retry Google search'),
              ),
            if (_selection != null) ...[
              const SizedBox(height: 12),
              Text(
                'Selected: ${_selection!.label}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
            if (!_usingDeviceFallback && _suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Powered by Google Places',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () {
            _requestId++;
            _debounce?.cancel();
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy || _selection == null ? null : _submit,
          child: const Text('Use location'),
        ),
      ],
    );
  }

  Widget _suggestionTile(PlaceSuggestion suggestion) {
    final selected = _selection?.label == suggestion.fullText;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      selected: selected,
      leading: const AppIconTile(
        icon: Icons.location_on_outlined,
        color: AppColors.primary,
      ),
      title: Text(
        suggestion.primaryText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: suggestion.secondaryText.isEmpty
          ? null
          : Text(
              suggestion.secondaryText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
      trailing: selected
          ? const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
            )
          : null,
      onTap: _isSearching || _isFetchingCoords
          ? null
          : () => _handleSuggestionTap(suggestion),
    );
  }
}
````

## File: lib/features/shared/personal_information_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'profile_header.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.isVendor,
    this.phoneNumber,
  });

  final String name;
  final String email;
  final bool isVendor;
  final String? phoneNumber;

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late String _name = widget.name;
  late String? _phoneNumber = widget.phoneNumber;

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          name: _name,
          email: widget.email,
          phoneNumber: _phoneNumber,
          editPhone: !widget.isVendor,
        ),
      ),
    );
    if (changed != true || !mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = await AuthService().getUserData(uid);
    if (mounted) {
      setState(() {
        _name = data?.fullName ??
            FirebaseAuth.instance.currentUser?.displayName ??
            _name;
        if (data != null) {
          _phoneNumber = data.phoneNumber;
        }
      });
    }
  }

  Widget _detail(String label, String value, {bool accent = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textDark)),
            const SizedBox(height: 3),
            SelectableText(
              value.isEmpty ? 'Not available' : value,
              style: TextStyle(
                fontSize: 17,
                color: accent ? AppColors.primary : AppColors.textDark,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final providers =
        user?.providerData.map((p) => p.providerId).toSet() ?? <String>{};
    final methods = providers
        .map((p) => p == 'google.com'
            ? 'Google'
            : p == 'password'
                ? 'Email and password'
                : p)
        .join(', ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SizedBox(
              height: 116,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 12,
                    child: ProfileAvatar(
                        name: _name, photoUrl: user?.photoURL, size: 100),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: ProfileTopAction(
                      label: 'Back',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: ProfileTopAction(label: 'Edit', onTap: _edit),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 28,
                height: 1.1,
                letterSpacing: -.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isVendor ? 'Vendor account' : 'Customer account',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
            const SizedBox(height: 46),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _detail('name', _name),
                  const Divider(indent: 16, endIndent: 16, height: .5),
                  _detail('email', widget.email, accent: true),
                  if (!widget.isVendor) ...[
                    const Divider(indent: 16, endIndent: 16, height: .5),
                    _detail(
                      'phone number',
                      _phoneNumber?.trim().isNotEmpty == true
                          ? _phoneNumber!
                          : 'Not added',
                    ),
                  ],
                  const Divider(indent: 16, endIndent: 16, height: .5),
                  _detail(
                      'account type', widget.isVendor ? 'Vendor' : 'Customer'),
                  const Divider(indent: 16, endIndent: 16, height: .5),
                  _detail('sign-in method', methods),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/features/shared/saved_locations_sheet.dart
````dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/ios_grouped.dart';
import '../../core/models/saved_location.dart';
import '../../core/services/saved_location_service.dart';
import 'manual_location_dialog.dart';
import 'pin_location_screen.dart';
import '../../core/widgets/app_dropdown.dart';

Future<LocationSelection?> showSavedLocationsSheet(
  BuildContext context, {
  required LatLng initialLocation,
  String? initialType,
}) =>
    showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (_) => _SavedLocationsSheet(
          initialLocation: initialLocation, initialType: initialType),
    );

class _SavedLocationsSheet extends StatefulWidget {
  const _SavedLocationsSheet({required this.initialLocation, this.initialType});
  final LatLng initialLocation;
  final String? initialType;

  @override
  State<_SavedLocationsSheet> createState() => _SavedLocationsSheetState();
}

class _SavedLocationsSheetState extends State<_SavedLocationsSheet> {
  final _service = SavedLocationService();
  List<SavedLocation> _locations = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final locations = await _service.load();
      if (mounted) {
        setState(() {
          _locations = locations;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Could not load saved places. Check your connection and retry.';
        });
      }
    }
  }

  Future<void> _edit({required bool home, SavedLocation? existing}) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search address'),
            onTap: () => Navigator.pop(context, 'search')),
        ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Pin on map'),
            subtitle: const Text('Choose the exact spot'),
            onTap: () => Navigator.pop(context, 'pin')),
        ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Use current search location'),
            onTap: () => Navigator.pop(context, 'current')),
      ])),
    );
    if (!mounted || method == null) return;
    final initial = existing?.coordinates ?? widget.initialLocation;
    LocationSelection? selection;
    if (method == 'search') {
      selection = await showManualLocationDialog(context,
          initialLocation: initial,
          title: home ? 'Set Home location' : 'Set custom location');
    } else if (method == 'pin') {
      selection = await Navigator.push<LocationSelection>(
          context,
          MaterialPageRoute(
              builder: (_) => PinLocationScreen(initialLocation: initial)));
    } else {
      var label = '${widget.initialLocation.latitude.toStringAsFixed(5)}, '
          '${widget.initialLocation.longitude.toStringAsFixed(5)}';
      try {
        label = await describeLocation(widget.initialLocation);
      } catch (_) {
        // Coordinates still identify the exact search location offline.
      }
      selection =
          LocationSelection(coordinates: widget.initialLocation, label: label);
    }
    if (!mounted || selection == null) return;
    final name = home ? 'Home' : await _name(existing?.name ?? '');
    if (!mounted || name == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.save(
          name: name,
          address: selection.label,
          coordinates: selection.coordinates,
          isHome: home,
          id: existing?.id);
      await _load();
    } catch (error, stackTrace) {
      debugPrint('Saved place failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = 'Could not save this place:\n$error';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<String?> _name(String initial) async {
    final controller = TextEditingController(text: initial);
    final key = GlobalKey<FormState>();
    final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Name this place'),
              content: Form(
                  key: key,
                  child: TextFormField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Work, campus, favourite area'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a name for this place.'
                        : null,
                  )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (key.currentState!.validate()) {
                        Navigator.pop(context, controller.text.trim());
                      }
                    },
                    child: const Text('Save place')),
              ],
            ));
    // Dispose after the closing route has finished using the text field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    return name;
  }

  Future<void> _delete(SavedLocation location) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.delete(location.id);
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not remove this place. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _pin(SavedLocation location) => ListTile(
        leading: AppIconTile(
            icon: location.isHome ? Icons.home_rounded : Icons.place_rounded,
            color:
                location.isHome ? AppColors.primary : const Color(0xFFAD55E8)),
        title: Text(location.name),
        subtitle: Text(location.address,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap:
            _saving ? null : () => Navigator.pop(context, location.selection),
        trailing: AppDropdown<String>(
          iconOnly: true,
          icon: Icons.more_vert,
          hint: 'Manage ${location.name}',
          options: const {
            'edit': 'Edit place',
            'delete': 'Remove place',
          },
          onChanged: _saving
              ? null
              : (value) {
                  if (value == 'edit') {
                    _edit(
                      home: location.isHome,
                      existing: location,
                    );
                  } else {
                    _delete(location);
                  }
                },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final homes = _locations.where((location) => location.isHome).toList();
    final custom = _locations.where((location) => !location.isHome).toList();
    return SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text(
                    widget.initialType == 'home'
                        ? 'Home location'
                        : widget.initialType == 'custom'
                            ? 'Custom locations'
                            : 'Saved places',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Choose a place to search for nearby stalls.',
                    style: TextStyle(color: Color(0xFF8E8E93))),
                const SizedBox(height: 24),
                if (_loading || _saving) const LinearProgressIndicator(),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(children: [
                        Expanded(child: Text(_error!)),
                        TextButton(onPressed: _load, child: const Text('Retry'))
                      ])),
                if (!_loading) ...[
                  _group('HOME', [
                    if (homes.isNotEmpty)
                      _pin(homes.first)
                    else
                      ListTile(
                          leading: const Icon(Icons.home_outlined),
                          title: const Text('Save Home location'),
                          subtitle: const Text(
                              'Keep your home pin for quick searches'),
                          onTap: _saving ? null : () => _edit(home: true)),
                  ]),
                  const SizedBox(height: 24),
                  _group('CUSTOM PLACES', [
                    ...custom.map(_pin),
                    ListTile(
                        leading: const Icon(Icons.add_location_alt_outlined),
                        title: const Text('Add custom location'),
                        onTap: _saving ? null : () => _edit(home: false)),
                  ]),
                ],
              ],
            )));
  }

  Widget _group(String label, List<Widget> rows) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        const SizedBox(height: 10),
        Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i != 0)
                  const Divider(
                      height: .5, thickness: .5, indent: 60, endIndent: 16),
                rows[i],
              ],
            ])),
      ]);
}
````

## File: lib/core/services/notification_service.dart
````dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/vendor_model.dart';
import 'vendor_service.dart';
import '../../features/customer/vendor_details/vendor_details_screen.dart';
import '../../features/shared/booking_detail_screen.dart';

// Runs in its own isolate when a push arrives while the app is backgrounded
// or fully closed. Android shows the system notification on its own from
// the message's payload -- this only needs to exist so FCM has something
// to call.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final VendorService _vendorService = VendorService();

  static const _channel = AndroidNotificationChannel(
    'stallseeker_channel',
    'StallSeeker Notifications',
    description: 'Stall, dish, and self-collect booking alerts.',
    importance: Importance.high,
  );

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;
  String? _syncedUid;
  String? _configuredUid;
  String? _configuredRole;
  String? _pendingVendorId;
  String? _pendingItemId;
  String? _pendingBookingId;
  String? _pendingBookingRecipient;
  bool _pendingBookingVendor = false;
  bool _navigationReady = false;
  Future<void> _tokenWork = Future<void>.value();

  Future<void> _queueTokenSave(String uid, String token) {
    _tokenWork = _tokenWork.catchError((Object _) {}).then((_) async {
      if (_syncedUid == uid && FirebaseAuth.instance.currentUser?.uid == uid) {
        await _saveToken(uid, token);
      }
    });
    return _tokenWork;
  }

  void setNavigationReady(bool ready) {
    _navigationReady = ready;
    if (ready && _pendingBookingId != null) {
      final id = _pendingBookingId!;
      final recipient = _pendingBookingRecipient;
      final isVendor = _pendingBookingVendor;
      _pendingBookingId = null;
      _pendingBookingRecipient = null;
      unawaited(_openBooking(id, recipientId: recipient, isVendor: isVendor));
    }
    if (ready && _pendingVendorId != null) {
      final id = _pendingVendorId!;
      final itemId = _pendingItemId;
      _pendingVendorId = null;
      _pendingItemId = null;
      unawaited(_openVendorDetails(id, itemId: itemId));
    }
  }

  // One-time setup: creates the notification channel and wires up listeners
  // for taps in every app state. Permission is requested only after the
  // signed-in account is confirmed.
  // (foreground, background, terminated). Safe to call more than once.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) {
      return;
    }

    _navigatorKey = navigatorKey;

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _openPayload(payload);
        }
      },
    );

    _initialized = true;

    // FCM does not show a system notification by itself while the app is
    // in the foreground, so display one manually using the same channel.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final vendorId = message.data['vendorId'];
      final bookingId = message.data['bookingId'];
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: bookingId is String
              ? jsonEncode({
                  'bookingId': bookingId,
                  'recipientId': message.data['recipientId'],
                  'role': message.data['role'],
                })
              : vendorId == null
                  ? null
                  : jsonEncode({
                      'vendorId': vendorId,
                      if (message.data['itemId'] is String)
                        'itemId': message.data['itemId'],
                    }),
        );
      }
    });

    // App was backgrounded and the user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final bookingId = message.data['bookingId'];
      if (bookingId is String) {
        unawaited(_openBooking(bookingId,
            recipientId: message.data['recipientId'] as String?,
            isVendor: message.data['role'] == 'vendor'));
        return;
      }
      final vendorId = message.data['vendorId'];
      if (vendorId != null) {
        _openVendorDetails(vendorId,
            itemId: message.data['itemId'] is String
                ? message.data['itemId'] as String
                : null);
      }
    });

    // App was fully closed and got launched by tapping the notification.
    final initialMessage = await _messaging.getInitialMessage();
    final initialBookingId = initialMessage?.data['bookingId'];
    if (initialBookingId is String) {
      unawaited(_openBooking(initialBookingId,
          recipientId: initialMessage?.data['recipientId'] as String?,
          isVendor: initialMessage?.data['role'] == 'vendor'));
      return;
    }
    final vendorId = initialMessage?.data['vendorId'];
    if (vendorId != null) {
      _openVendorDetails(vendorId,
          itemId: initialMessage!.data['itemId'] is String
              ? initialMessage.data['itemId'] as String
              : null);
    }
  }

  Future<void> configureForRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }
    if (_configuredUid == user.uid && _configuredRole == role) {
      return;
    }
    _configuredUid = user.uid;
    _configuredRole = role;

    if (role != 'customer' && role != 'vendor') {
      _syncedUid = null;
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      await _tokenWork
          .timeout(const Duration(seconds: 5))
          .catchError((Object _) {});
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': FieldValue.delete()}, SetOptions(merge: true));
        await _messaging.deleteToken().timeout(const Duration(seconds: 5));
        await _localNotifications.cancelAll();
      } catch (_) {
        debugPrint('Could not disable notifications.');
        _configuredUid = null;
        _configuredRole = null;
      }
      return;
    }

    try {
      if (!await isEnabledForCurrentUser()) {
        await _removeCurrentDeviceToken(user);
        return;
      }
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await _removeCurrentDeviceToken(user);
        return;
      }
      _syncedUid = null;
      await syncTokenForCurrentUser(skipPreferenceCheck: true);
    } catch (_) {
      debugPrint('Could not configure notifications.');
      _configuredUid = null;
      _configuredRole = null;
    }
  }

  // Fetches this device's FCM token and saves it on the signed-in account,
  // and keeps it updated if it ever rotates.
  Future<void> syncTokenForCurrentUser(
      {bool skipPreferenceCheck = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || _syncedUid == user.uid) {
      return;
    }
    if (_configuredRole != null &&
        _configuredRole != 'customer' &&
        _configuredRole != 'vendor') {
      return;
    }
    if (!skipPreferenceCheck && !await isEnabledForCurrentUser()) {
      await _removeCurrentDeviceToken(user);
      return;
    }
    _syncedUid = user.uid;
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      final uid = _syncedUid;
      if (uid != null) {
        unawaited(_queueTokenSave(uid, token).catchError((Object e) {
          debugPrint('Could not refresh notification registration.');
        }));
      }
    });
    try {
      final token =
          await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        await _queueTokenSave(user.uid, token);
      }
    } catch (_) {
      _syncedUid = null;
      debugPrint('Notification registration unavailable.');
    }
  }

  Future<bool> isEnabledForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return false;
    }
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return profile.data()?['notificationsEnabled'] != false;
  }

  Future<String?> setEnabledForCurrentUser(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return 'Sign in to manage notifications.';
    }
    if (_configuredRole != 'customer' && _configuredRole != 'vendor') {
      return 'Sign in to manage notifications.';
    }
    try {
      if (enabled) {
        final settings = await _messaging.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          return 'Notifications are blocked in your phone settings.';
        }
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'notificationsEnabled': enabled,
        if (!enabled) 'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      if (enabled) {
        _syncedUid = null;
        await syncTokenForCurrentUser(skipPreferenceCheck: true);
      } else {
        await _removeCurrentDeviceToken(user);
        await _localNotifications.cancelAll();
      }
      return null;
    } catch (_) {
      return 'Could not update notification settings. Please try again.';
    }
  }

  Future<void> _removeCurrentDeviceToken(User user) async {
    _syncedUid = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    await _tokenWork
        .timeout(const Duration(seconds: 5))
        .catchError((Object _) {});
    try {
      final token =
          await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        final ref =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final doc = await tx.get(ref);
          if (doc.data()?['fcmToken'] == token) {
            tx.update(ref, {'fcmToken': FieldValue.delete()});
          }
        }).timeout(const Duration(seconds: 5));
      }
    } finally {
      await _messaging
          .deleteToken()
          .timeout(const Duration(seconds: 5))
          .catchError((Object _) {});
    }
  }

  Future<void> clearCurrentDevice() async {
    _navigationReady = false;
    _pendingVendorId = null;
    _pendingItemId = null;
    _pendingBookingId = null;
    _pendingBookingRecipient = null;
    _configuredUid = null;
    _configuredRole = null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }
    try {
      await _removeCurrentDeviceToken(user);
    } catch (_) {
      debugPrint('Could not remove notification registration.');
    } finally {
      await _localNotifications.cancelAll();
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true)).timeout(const Duration(seconds: 5));
  }

  void _openPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['bookingId'] is String) {
        unawaited(_openBooking(data['bookingId'] as String,
            recipientId: data['recipientId'] as String?,
            isVendor: data['role'] == 'vendor'));
        return;
      }
      if (data is Map && data['vendorId'] is String) {
        unawaited(_openVendorDetails(data['vendorId'] as String,
            itemId:
                data['itemId'] is String ? data['itemId'] as String : null));
        return;
      }
    } on FormatException {
      // Existing notifications used the plain vendor ID as their payload.
    }
    unawaited(_openVendorDetails(payload));
  }

  Future<void> _openVendorDetails(String vendorId, {String? itemId}) async {
    final navState = _navigatorKey?.currentState;
    if (!_navigationReady || navState == null) {
      _pendingVendorId = vendorId;
      _pendingItemId = itemId;
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final VendorModel? vendor = await _vendorService.getVendorProfile(vendorId);
    if (vendor == null ||
        !_navigationReady ||
        FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }

    navState.push(
      MaterialPageRoute(
          builder: (_) =>
              VendorDetailsScreen(vendor: vendor, initialDishId: itemId)),
    );
  }

  Future<void> _openBooking(String bookingId,
      {String? recipientId, required bool isVendor}) async {
    final navState = _navigatorKey?.currentState;
    if (!_navigationReady || navState == null) {
      _pendingBookingId = bookingId;
      _pendingBookingRecipient = recipientId;
      _pendingBookingVendor = isVendor;
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || (recipientId != null && uid != recipientId)) return;
    navState.push(MaterialPageRoute(
        builder: (_) =>
            BookingDetailScreen(bookingId: bookingId, isVendor: isVendor)));
  }
}
````

## File: lib/features/customer/notifications/customer_notifications_screen.dart
````dart
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_grouped.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_history_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});
  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
  final _history = NotificationHistoryService();
  final _vendors = VendorService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  late Stream<List<NotificationModel>> _stream;
  final Set<String> _opening = {};
  final Set<String> _removedIds = {};
  int _limit = 50;
  bool _marking = false;
  bool _onlyUnread = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    final uid = _uid;
    _stream =
        uid == null || FirebaseAuth.instance.currentUser?.isAnonymous == true
            ? Stream.value(<NotificationModel>[])
            : _history.watch(uid, limit: _limit);
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _open(NotificationModel item) async {
    final uid = _uid;
    if (uid == null || _opening.contains(item.id)) {
      return;
    }
    setState(() => _opening.add(item.id));
    try {
      if (!item.isRead) {
        try {
          await _history.markRead(uid, item.id);
        } catch (_) {
          _message('Could not mark this alert as read.');
        }
      }
      if (item.vendorId.isEmpty) {
        _message('This alert has no stall link.');
        return;
      }
      final vendor = await _vendors
          .getVendorProfile(item.vendorId)
          .timeout(const Duration(seconds: 10));
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }
      if (vendor == null) {
        _message('This stall is unavailable or could not be loaded.');
        return;
      }
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VendorDetailsScreen(
                  vendor: vendor, initialDishId: item.itemId)));
    } catch (_) {
      _message('Could not open the stall. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _opening.remove(item.id));
      }
    }
  }

  Future<void> _markRead(List<NotificationModel> items) async {
    final uid = _uid;
    if (uid == null || _marking) {
      return;
    }
    setState(() => _marking = true);
    try {
      await _history.markDisplayedRead(uid, items);
    } catch (_) {
      _message('Could not mark alerts as read. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _marking = false);
      }
    }
  }

  Future<void> _remove(NotificationModel item) async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _removedIds.add(item.id));
    try {
      await _history.remove(uid, item.id);
    } catch (_) {
      if (mounted) {
        setState(() => _removedIds.remove(item.id));
        _message('Could not remove this notification. Please retry.');
      }
    }
  }

  String _date(DateTime? value) {
    if (value == null) {
      return 'Date unavailable';
    }
    final local = value.toLocal();
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '${local.day}/${local.month}/${local.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final horizontalInset =
        math.max(16.0, (MediaQuery.sizeOf(context).width - 960) / 2);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return _empty('Your stall updates, in one place',
          'Sign in and follow stalls or dishes to keep their updates here.',
          action: TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign in')));
    }
    return ColoredBox(
        color: AppColors.background,
        child: StreamBuilder<List<NotificationModel>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _errorState(snapshot.error!);
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = (snapshot.data ?? [])
                .where((item) => !_removedIds.contains(item.id))
                .toList();
            final visible =
                _onlyUnread ? all.where((item) => !item.isRead).toList() : all;
            return RefreshIndicator(
                onRefresh: () async {
                  setState(_listen);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      horizontalInset, 20, horizontalInset, 112),
                  children: [
                    Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          CupertinoSlidingSegmentedControl<bool>(
                            backgroundColor: const Color(0xFFE2E2E7),
                            thumbColor: Colors.white,
                            groupValue: _onlyUnread,
                            children: const {
                              false: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 18),
                                  child: Text('All')),
                              true: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 18),
                                  child: Text('Unread')),
                            },
                            onValueChanged: (value) {
                              if (value != null) {
                                setState(() => _onlyUnread = value);
                              }
                            },
                          ),
                          TextButton(
                              onPressed:
                                  _marking || !all.any((item) => !item.isRead)
                                      ? null
                                      : () => _markRead(all),
                              child: Text(_marking
                                  ? 'Updating…'
                                  : 'Mark shown as read')),
                        ]),
                    const Padding(
                        padding: EdgeInsets.fromLTRB(8, 16, 8, 12),
                        child: Text('STALL UPDATES',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF8E8E93)))),
                    if (visible.isEmpty)
                      Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(children: [
                            const Icon(Icons.notifications_none_rounded,
                                size: 42, color: Color(0xFF8E8E93)),
                            const SizedBox(height: 12),
                            Text(
                                _onlyUnread
                                    ? 'No unread updates in this list'
                                    : 'No notifications yet',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text(
                                'Updates appear here when a followed stall opens or a followed dish is restocked.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF8E8E93))),
                          ]))
                    else
                      for (final item in visible) ...[
                        Dismissible(
                          key: ValueKey('notification-${item.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: AppColors.closedRed,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    color: Colors.white),
                                SizedBox(width: 6),
                                Text('Remove',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          onDismissed: (_) => _remove(item),
                          child: _tile(item),
                        ),
                        const SizedBox(height: 12),
                      ],
                    if (all.length >= _limit)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton(
                              onPressed: () => setState(() {
                                    _limit += 50;
                                    _listen();
                                  }),
                              child: const Text('Load older updates'))),
                  ],
                ));
          },
        ));
  }

  Widget _tile(NotificationModel item) => Material(
        color: item.isRead ? Colors.white : const Color(0xFFFFF5EC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: item.isRead
                ? AppColors.border
                : AppColors.primary.withValues(alpha: .18),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          leading: AppIconTile(
              icon: item.type == 'dish_available'
                  ? Icons.restaurant_rounded
                  : Icons.storefront_rounded,
              color: item.isRead ? const Color(0xFF949499) : AppColors.primary),
          title: Text(item.title,
              style: TextStyle(
                  fontSize: 17,
                  letterSpacing: 0,
                  fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w500)),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.body.isNotEmpty)
                      Text(item.body,
                          style:
                              const TextStyle(fontSize: 14, letterSpacing: 0)),
                    const SizedBox(height: 5),
                    Text(_date(item.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8E8E93))),
                  ])),
          trailing: _opening.contains(item.id)
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(item.isRead ? Icons.chevron_right : Icons.circle,
                  size: item.isRead ? 20 : 8,
                  color: item.isRead
                      ? const Color(0xFFAEAEB2)
                      : AppColors.primary),
          onTap: () => _open(item),
        ),
      );

  Widget _errorState(Object error) {
    final code = error is FirebaseException ? error.code : 'unknown';
    // Preserve the real error in the debug console instead of blaming Wi-Fi.
    debugPrint('Notification history [$code]: $error');
    String title;
    String body;
    switch (code) {
      case 'permission-denied':
        title = 'Notification access is blocked';
        body =
            'Your account cannot read notification history yet. Please contact support.';
        break;
      case 'unauthenticated':
        title = 'Please sign in again';
        body =
            'Your session has expired. Sign out and sign in to load your updates.';
        break;
      case 'unavailable':
      case 'deadline-exceeded':
        title = 'Cannot reach notifications';
        body = 'Check your connection, then try again.';
        break;
      case 'failed-precondition':
        title = 'Notifications are not ready';
        body =
            'Notification history needs a service update. Please contact support.';
        break;
      default:
        title = 'Could not load notifications';
        body =
            'Try again. If this continues, share the error code with support.';
    }
    return _empty(title, body,
        action: Column(mainAxisSize: MainAxisSize.min, children: [
          TextButton(
              onPressed: () => setState(_listen), child: const Text('Retry')),
          SelectableText('Error: $code',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        ]));
  }

  Widget _empty(String title, String body, {Widget? action}) => Center(
          child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.notifications_none_rounded,
              size: 44, color: Color(0xFF8E8E93)),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
          if (action != null) action,
        ]),
      ));
}
````

## File: lib/features/customer/orders/demo_order_cart_screen.dart
````dart
import '../../../core/widgets/app_page_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/demo_order.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/demo_order_service.dart';
import '../../../core/services/menu_service.dart';
import '../../shared/booking_detail_screen.dart';

class DemoOrderCartScreen extends StatefulWidget {
  const DemoOrderCartScreen({super.key, required this.vendor});
  final VendorModel vendor;

  @override
  State<DemoOrderCartScreen> createState() => _DemoOrderCartScreenState();
}

class _DemoOrderCartScreenState extends State<DemoOrderCartScreen> {
  final _quantities = <String, int>{};
  final _specialInstructions = TextEditingController();
  final _service = DemoOrderService();
  final _menuService = MenuService();
  late final Stream<List<MenuItemModel>> _menu;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _menu = _menuService.getMenuItems(widget.vendor.vendorId);
  }

  @override
  void dispose() {
    _specialInstructions.dispose();
    super.dispose();
  }

  Future<void> _submit(List<MenuItemModel> items) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sign in with a verified customer account to book.')));
      return;
    }
    final selected = <DemoOrderItem>[];
    for (final item in items) {
      final quantity = _quantities[item.itemId] ?? 0;
      if (quantity > 0 && item.status != 'out_of_stock') {
        selected.add(DemoOrderItem(
            itemId: item.itemId,
            name: item.name,
            unitPriceCents: (item.price * 100).round(),
            quantity: quantity));
      }
    }
    if (selected.isEmpty) return;
    setState(() => _sending = true);
    try {
      final bookingId = await _service.requestOrder(widget.vendor, selected,
          specialInstructions: _specialInstructions.text);
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                  bookingId: bookingId,
                  isVendor: false,
                  openCheckoutOnStart: true)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                error is FirebaseFunctionsException && error.message != null
                    ? error.message!
                    : 'Could not save this booking. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppPageAppBar(title: const Text('Your order')),
        body: StreamBuilder<List<MenuItemModel>>(
          stream: _menu,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load the menu.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return BookingCartView(
              stallName: widget.vendor.stallName,
              items: snapshot.data!,
              quantities: _quantities,
              sending: _sending,
              specialInstructionsController: _specialInstructions,
              onQuantityChanged: (item, quantity) => setState(() {
                _quantities[item.itemId] = quantity;
              }),
              onSubmit: () => _submit(snapshot.data!),
            );
          },
        ),
      );
}

class BookingCartView extends StatelessWidget {
  const BookingCartView({
    super.key,
    required this.stallName,
    required this.items,
    required this.quantities,
    required this.sending,
    required this.onQuantityChanged,
    required this.onSubmit,
    this.specialInstructionsController,
  });

  final String stallName;
  final List<MenuItemModel> items;
  final Map<String, int> quantities;
  final bool sending;
  final void Function(MenuItemModel, int) onQuantityChanged;
  final VoidCallback onSubmit;
  final TextEditingController? specialInstructionsController;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item.status == 'out_of_stock' ? 0 : (quantities[item.itemId] ?? 0)) *
              (item.price * 100).round(),
    );
    final itemCount = items.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item.status == 'out_of_stock' ? 0 : (quantities[item.itemId] ?? 0)),
    );
    final canContinue = total >= 200 && !sending;

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELF-COLLECT',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(stallName,
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.15)),
                    const SizedBox(height: 8),
                    const Text('Choose your food for pickup.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14)),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 21, color: AppColors.openGreen),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pay to confirm',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                                SizedBox(height: 3),
                                Text(
                                    'The stall gets your booking after payment.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Text('Secure payment with Stripe',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                    const SizedBox(height: 30),
                    Row(children: [
                      const Text('Menu',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      const Spacer(),
                      Text(
                          '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ]),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child:
                            Center(child: Text('No dishes on the menu yet.')),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                    height: 1, indent: 16, endIndent: 16),
                              _MenuItemRow(
                                item: items[i],
                                quantity: items[i].status == 'out_of_stock'
                                    ? 0
                                    : (quantities[items[i].itemId] ?? 0),
                                onChanged: (quantity) =>
                                    onQuantityChanged(items[i], quantity),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      TextField(
                        controller: specialInstructionsController,
                        enabled: !sending,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Special instructions (optional)',
                          hintText: 'E.g. Less spicy, please',
                          helperText:
                              'Requests are subject to vendor acceptance.',
                          helperMaxLines: 2,
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.cardColor,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                            itemCount == 0
                                ? 'Order total'
                                : '$itemCount ${itemCount == 1 ? 'item' : 'items'} · Total',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textMuted)),
                      ),
                      const SizedBox(width: 8),
                      Text('RM ${(total / 100).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ]),
                    if (itemCount > 0 && total < 200) ...[
                      const SizedBox(height: 5),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Minimum order RM2.00',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: canContinue ? onSubmit : null,
                        child: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      itemCount == 0
                                          ? 'Choose an item'
                                          : 'Continue to payment',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (itemCount > 0) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 18),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.item,
    required this.quantity,
    required this.onChanged,
  });

  final MenuItemModel item;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final available = item.status != 'out_of_stock';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: available
                          ? AppColors.textDark
                          : AppColors.textMuted)),
              const SizedBox(height: 5),
              Text(
                  available
                      ? 'RM ${item.price.toStringAsFixed(2)}'
                      : 'Out of stock',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: available ? FontWeight.w500 : FontWeight.w400,
                      color:
                          available ? AppColors.primary : AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              tooltip: 'Remove ${item.name}',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              iconSize: 20,
              onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 24,
              child: Text('$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Add ${item.name}',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              iconSize: 20,
              onPressed: available && quantity < 20
                  ? () => onChanged(quantity + 1)
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ]),
        ),
      ]),
    );
  }
}
````

## File: lib/features/shared/booking_detail_screen.dart
````dart
import '../../core/widgets/app_page_app_bar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import 'booking_payment_card.dart';

enum _PaymentTransition { openingCheckout, checkingPayment }

class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard(
      {super.key,
      required this.booking,
      required this.isVendor,
      required this.onTap,
      this.compact = false});

  final DemoOrder booking;
  final bool isVendor;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final unseen =
        isVendor ? booking.vendorUnseenRequest : booking.customerUnseenReady;
    final color = booking.status == 'ready'
        ? const Color(0xFF137547)
        : booking.status == 'requested'
            ? const Color(0xFFB65A16)
            : Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (unseen) ...[
                const CircleAvatar(
                    radius: 4, backgroundColor: Color(0xFFE84E36)),
                const SizedBox(width: 8),
              ],
              Expanded(
                  child: Text(
                      isVendor ? booking.customerName : booking.stallName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16))),
              Text('RM ${(booking.totalCents / 100).toStringAsFixed(2)}'),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ]),
            const SizedBox(height: 8),
            Text(bookingStatusLabel(booking),
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            if (booking.hasTestPayment) ...[
              const SizedBox(height: 4),
              Text(bookingPaymentLabel(booking),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                  booking.items
                      .map((item) => '${item.quantity}× ${item.name}')
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (booking.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(_dateTime(booking.createdAt!),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (booking.specialInstructions.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Special instructions: ${booking.specialInstructions}',
                  maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      ),
    );
  }
}

String _dateTime(DateTime date) => '${date.day}/${date.month}/${date.year} '
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen(
      {super.key,
      required this.bookingId,
      required this.isVendor,
      this.openCheckoutOnStart = false});
  final String bookingId;
  final bool isVendor;
  final bool openCheckoutOnStart;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen>
    with WidgetsBindingObserver {
  final _service = DemoOrderService();
  late final Stream<DemoOrder?> _booking =
      _service.watchBooking(widget.bookingId);
  bool _busy = false;
  bool _viewing = false;
  bool _initialPaymentCheck = false;
  bool _hasTestPayment = false;
  bool _checkoutLaunched = false;
  bool _refreshOnResume = false;
  bool _refreshWithTransition = false;
  _PaymentTransition? _paymentTransition;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.openCheckoutOnStart && !widget.isVendor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
              _runPaymentTransition(_pay, _PaymentTransition.openingCheckout));
        }
      });
    }
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _hasTestPayment) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasTestPayment) {
      final showTransition = _checkoutLaunched && !widget.isVendor;
      _checkoutLaunched = false;
      if (_busy) {
        _refreshOnResume = true;
        _refreshWithTransition |= showTransition;
      } else {
        unawaited(showTransition
            ? _checkPayment()
            : _act(() => _service.refreshPayment(widget.bookingId)));
      }
    }
  }

  Future<void> _checkPayment() => _runPaymentTransition(
        () => _service.refreshPayment(widget.bookingId),
        _PaymentTransition.checkingPayment,
      );

  Future<void> _runPaymentTransition(
      Future<void> Function() action, _PaymentTransition transition) async {
    if (!mounted || _busy) return;
    setState(() => _paymentTransition = transition);
    try {
      await _act(action);
    } finally {
      if (mounted) setState(() => _paymentTransition = null);
    }
  }

  Future<void> _pay() async {
    final uri = await _service.createTestCheckout(widget.bookingId);
    await _launchCheckout(uri);
  }

  Future<void> _launchCheckout(Uri uri) async {
    bool opened;
    _checkoutLaunched = true;
    try {
      opened = await launchUrl(uri,
          mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    } catch (_) {
      opened = false;
    }
    if (!opened) _checkoutLaunched = false;
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not open Stripe checkout.'),
          action: SnackBarAction(
              label: 'Try again',
              onPressed: () {
                unawaited(_runPaymentTransition(() => _launchCheckout(uri),
                    _PaymentTransition.openingCheckout));
              })));
    }
  }

  void _viewIfNeeded(DemoOrder booking) {
    final unseen = widget.isVendor
        ? booking.vendorUnseenRequest
        : booking.customerUnseenReady;
    if (!unseen || _viewing) return;
    _viewing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _service.markViewed(widget.bookingId);
      } catch (_) {
        // The booking remains unread and can be retried when reopened.
      } finally {
        _viewing = false;
      }
    });
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                error is FirebaseFunctionsException && error.message != null
                    ? error.message!
                    : 'Could not update this booking. Please try again.')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_refreshOnResume) {
          final showTransition = _refreshWithTransition;
          _refreshOnResume = false;
          _refreshWithTransition = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              unawaited(showTransition
                  ? _checkPayment()
                  : _act(() => _service.refreshPayment(widget.bookingId)));
            }
          });
        }
      }
    }
  }

  Widget _paymentTransitionView() {
    final opening = _paymentTransition == _PaymentTransition.openingCheckout;
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 38, color: AppColors.primary),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  opening
                      ? 'Opening secure checkout'
                      : 'Checking payment status',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  opening
                      ? 'Please wait while we open Stripe.'
                      : 'Confirming your payment with Stripe.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Secure payment with Stripe',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(String label, Future<void> Function() action,
      {bool primary = true}) {
    return primary
        ? FilledButton(
            onPressed: _busy ? null : () => _act(action), child: Text(label))
        : OutlinedButton(
            onPressed: _busy ? null : () => _act(action), child: Text(label));
  }

  Future<void> _confirmCancellation(DemoOrder booking) async {
    final paid = booking.paymentStatus == 'paid';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(paid
            ? 'The full payment will be refunded to the original payment method. Refund status may take time to update.'
            : 'The booking will be cancelled. Any open checkout will close.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(paid ? 'Cancel and refund' : 'Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _service.cancel(booking.id);
  }

  List<Widget> _actions(DemoOrder booking) {
    final status = booking.effectiveStatus;
    if (!widget.isVendor) {
      return booking.canCustomerCancel
          ? [
              _action(
                  booking.paymentStatus == 'paid'
                      ? 'Cancel and refund'
                      : 'Cancel booking',
                  () => _confirmCancellation(booking),
                  primary: false)
            ]
          : [];
    }
    return switch (status) {
      'requested' => [
          _action('Accept', () => _service.respond(booking.id, accept: true)),
          _action('Reject', () => _service.respond(booking.id, accept: false),
              primary: false),
        ],
      'confirmed' => [
          if (booking.canPrepare)
            _action(
                'Start preparing', () => _service.advance(booking.id, status)),
          _action(
              booking.paymentStatus == 'paid'
                  ? 'Cancel and refund'
                  : 'Cancel booking',
              () => _confirmCancellation(booking),
              primary: false),
        ],
      'preparing' => [
          _action('Mark ready', () => _service.advance(booking.id, status)),
          _action(
              booking.paymentStatus == 'paid'
                  ? 'Cancel and refund'
                  : 'Cancel booking',
              () => _confirmCancellation(booking),
              primary: false),
        ],
      'ready' => [
          _action('Mark collected', () => _service.advance(booking.id, status)),
          _action(
              booking.paymentStatus == 'paid'
                  ? 'Cancel and refund'
                  : 'Cancel booking',
              () => _confirmCancellation(booking),
              primary: false),
        ],
      _ => [],
    };
  }

  Widget _progress(DemoOrder booking) {
    final steps = [
      if (booking.checkoutFirst)
        'checkout_started'
      else ...[
        'requested',
        'confirmed',
      ],
      if (booking.hasTestPayment) 'payment_confirmed',
      'preparing',
      'ready',
      'collected'
    ];
    var position = steps.indexOf(booking.effectiveStatus);
    if (booking.checkoutFirst && booking.status == 'confirmed') {
      position = steps.indexOf(booking.paymentStatus == 'paid'
          ? 'payment_confirmed'
          : 'checkout_started');
    } else if (booking.hasTestPayment &&
        booking.status == 'confirmed' &&
        booking.paymentStatus == 'paid') {
      position = steps.indexOf('payment_confirmed');
    }
    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(i <= position ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: i <= position ? const Color(0xFF137547) : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    steps[i] == 'payment_confirmed'
                        ? 'Payment confirmed'
                        : steps[i] == 'checkout_started'
                            ? 'Checkout started'
                            : demoOrderStatusLabel(steps[i]),
                    style: TextStyle(
                        fontWeight: i == position ? FontWeight.bold : null))),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            appBar: AppPageAppBar(title: const Text('Booking details')),
            body: StreamBuilder<DemoOrder?>(
              stream: _booking,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text(
                          'Could not load this booking. Check your connection.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final booking = snapshot.data;
                if (booking == null) {
                  return const Center(child: Text('Booking not found.'));
                }
                _viewIfNeeded(booking);
                _hasTestPayment = booking.hasTestPayment;
                if (!_initialPaymentCheck &&
                    booking.hasTestPayment &&
                    booking.paymentStatus != 'unpaid') {
                  _initialPaymentCheck = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_busy) {
                      unawaited(
                          _act(() => _service.refreshPayment(booking.id)));
                    }
                  });
                }
                return ListView(padding: const EdgeInsets.all(18), children: [
                  Text(
                      widget.isVendor
                          ? booking.customerName
                          : booking.stallName,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  if (booking.createdAt != null)
                    Text(
                        '${booking.checkoutFirst ? 'Started' : 'Requested'} ${_dateTime(booking.createdAt!)}'),
                  const SizedBox(height: 18),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Progress',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 10),
                                if (booking.isActive ||
                                    booking.status == 'collected')
                                  _progress(booking)
                                else
                                  Text(
                                      demoOrderStatusLabel(
                                          booking.effectiveStatus),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                if (booking.effectiveStatus == 'requested' &&
                                    booking.expiresAt != null)
                                  Text(
                                      'Vendor reply due by ${_dateTime(booking.expiresAt!)}'),
                              ]))),
                  const SizedBox(height: 12),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Items',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                for (final item in booking.items)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3),
                                      child: Row(children: [
                                        Expanded(
                                            child: Text(
                                                '${item.quantity}× ${item.name}')),
                                        Text(
                                            'RM ${(item.subtotalCents / 100).toStringAsFixed(2)}'),
                                      ])),
                                const Divider(),
                                Row(children: [
                                  const Expanded(child: Text('Total')),
                                  Text(
                                      'RM ${(booking.totalCents / 100).toStringAsFixed(2)}')
                                ]),
                              ]))),
                  if (booking.specialInstructions.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    BookingSpecialInstructionsCard(
                        instructions: booking.specialInstructions),
                  ],
                  if (booking.hasTestPayment) ...[
                    const SizedBox(height: 12),
                    BookingPaymentCard(
                        booking: booking,
                        isVendor: widget.isVendor,
                        busy: _busy,
                        busyLabel: switch (_paymentTransition) {
                          _PaymentTransition.openingCheckout =>
                            'Opening checkout…',
                          _PaymentTransition.checkingPayment =>
                            'Checking payment…',
                          null => 'Processing…',
                        },
                        onPay: () => _runPaymentTransition(
                            _pay, _PaymentTransition.openingCheckout),
                        onRefresh: () => _checkPayment()),
                  ],
                  if (booking.pickupLatitude != null &&
                      booking.pickupLongitude != null)
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${booking.pickupLatitude},${booking.pickupLongitude}')),
                      icon: const Icon(Icons.place_outlined),
                      label: const Text('Self-collect location'),
                    ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 4, children: _actions(booking)),
                  const SizedBox(height: 8),
                  if (!booking.hasTestPayment)
                    const Text(
                        'This earlier booking uses payment arranged directly with the stall.'),
                ]);
              },
            ),
          ),
          if (_paymentTransition != null)
            Positioned.fill(
              child: AbsorbPointer(
                child: Material(
                  color: AppColors.background,
                  child: SafeArea(child: _paymentTransitionView()),
                ),
              ),
            ),
        ],
      );
}

class BookingSpecialInstructionsCard extends StatelessWidget {
  const BookingSpecialInstructionsCard({super.key, required this.instructions});

  final String instructions;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Special instructions',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(instructions),
              const SizedBox(height: 8),
              Text('Requests are subject to vendor acceptance.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}
````

## File: lib/core/constants/app_colors.dart
````dart
import 'package:flutter/material.dart';

class AppColors {
  // Colors sampled from the StallSeeker logo.
  static const Color logoOrange = Color(0xFFFB8D24);
  static const Color logoRedOrange = Color(0xFFFA3A1E);

  // A darker orange for readable text and selected navigation icons.
  static const Color primary = Color(0xFFB83D11);
  static const Color primaryLight = logoOrange;

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [logoOrange, logoRedOrange],
  );

  static const Color background = Color(0xFFFFF8F2);
  static const Color cardColor = Colors.white;

  // Keep this name because existing screens already use AppColors.mint.
  static const Color mint = Color(0xFFFFF0E5);

  static const Color border = Color(0xFFF0E1D6);
  static const Color textDark = Color(0xFF241E1B);
  static const Color textMuted = Color(0xFF7D706B);

  // Status colors retain their meanings.
  static const Color openGreen = Color(0xFF2E7D32);
  static const Color closedRed = Color(0xFFC62828);
  static const Color limitedYellow = Color(0xFFF57F17);
}
````

## File: lib/core/services/menu_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// customer tengok menu vendor
  Stream<List<MenuItemModel>> getMenuItems(String vendorId) {
    return _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
            .toList());
  }

// create id baru bila add menu baru
  String newMenuItemId(String vendorId) {
    return _db.collection('vendors').doc(vendorId).collection('menu').doc().id;
  }

// validate dan save menu
  Future<void> addMenuItem(
    String vendorId,
    String name,
    double price, {
    String? itemId,
    String? imageUrl,
    String section = 'Main menu',
    String description = '',
    String portionSize = '',
    List<String> ingredients = const [],
  }) async {
    if (name.trim().isEmpty || !price.isFinite || price <= 0) {
      throw ArgumentError('Invalid dish');
    }
    final docRef = itemId != null
        ? _db.collection('vendors').doc(vendorId).collection('menu').doc(itemId)
        : _db.collection('vendors').doc(vendorId).collection('menu').doc();

    final newItem = MenuItemModel(
      itemId: docRef.id,
      name: name,
      price: price,
      status: 'available',
      imageUrl: imageUrl ?? '',
      section: section.trim(),
      description: description.trim(),
      portionSize: portionSize.trim(),
      ingredients: ingredients
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
    );

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      transaction.set(docRef, {
        ...newItem.toMap(),
        'createdAt':
            existing.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }).timeout(const Duration(seconds: 15));
  }

// update menu item (name, price, image)
  Future<void> updateMenuItem(
    String vendorId,
    String itemId,
    String name,
    double price, {
    String? imageUrl,
    String section = 'Main menu',
    String description = '',
    String portionSize = '',
    List<String> ingredients = const [],
  }) async {
    if (name.trim().isEmpty || !price.isFinite || price <= 0) {
      throw ArgumentError('Invalid dish');
    }
    final data = <String, dynamic>{
      'name': name,
      'price': price,
      'section': section.trim(),
      'description': description.trim(),
      'portionSize': portionSize.trim(),
      'ingredients': ingredients
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }

    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update(data)
        .timeout(const Duration(seconds: 15));
  }

// change menu aiavlaibility
  Future<void> updateItemStatus(
      String vendorId, String itemId, String newStatus) async {
    if (!{'available', 'low_stock', 'out_of_stock'}.contains(newStatus)) {
      throw ArgumentError('Invalid status');
    }
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update({
      'status': newStatus,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp()
    }).timeout(const Duration(seconds: 15));
  }

  // Delete item
  Future<void> deleteMenuItem(String vendorId, String itemId) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .delete()
        .timeout(const Duration(seconds: 15));
  }
}
````

## File: lib/core/services/vendor_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/vendor_model.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _vendorsRef => _firestore.collection('vendors');

// read store id
  Future<VendorModel?> getVendorProfile(String vendorId) async {
    try {
      DocumentSnapshot doc = await _vendorsRef.doc(vendorId).get();
      if (doc.exists && doc.data() != null) {
        return VendorModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching vendor profile: $e');
      return null;
    }
  }

// update stall infroamtion
  Future<void> saveVendorProfile(VendorModel vendor) async {
    try {
      final ref = _vendorsRef.doc(vendor.vendorId);
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(ref);
        final data = existing.data() as Map<String, dynamic>?;
        final firstProfile = !existing.exists ||
            (data?['stallName'] as String? ?? '').trim().isEmpty;
        transaction.set(
            ref,
            {
              ...vendor.toProfileMap(),
              'updatedAt': FieldValue.serverTimestamp(),
              if (firstProfile && data?['createdAt'] == null)
                'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Error saving vendor profile: $e');
      rethrow;
    }
  }

// open/closed
  Future<void> toggleStallStatus(String vendorId, bool isOpen) async {
    try {
      await _vendorsRef.doc(vendorId).set({
        'vendorId': vendorId,
        'isOpen': isOpen,
        if (!isOpen) 'locationSharingActive': false,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error toggling stall status: $e');
      rethrow;
    }
  }

// update location
  Future<void> updateVendorLocation(
      String vendorId, double latitude, double longitude,
      {bool sharingActive = true}) async {
    try {
      await _vendorsRef.doc(vendorId).set({
        'vendorId': vendorId,
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'locationSharingActive': sharingActive,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating vendor location: $e');
      rethrow;
    }
  }

  Stream<VendorModel?> watchVendorProfile(String vendorId) {
    return _vendorsRef.doc(vendorId).snapshots().map((doc) =>
        doc.exists && doc.data() != null
            ? VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
            : null);
  }

  Future<void> setSelfCollectEnabled(String vendorId, bool enabled) =>
      _vendorsRef.doc(vendorId).update({'selfCollectEnabled': enabled});

  Stream<List<VendorModel>> getOpenVendors() {
    return _vendorsRef.where('isOpen', isEqualTo: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<VendorModel>> getAllVendors() {
    return _vendorsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }
}
````

## File: lib/features/shared/legal_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'info_page.dart';

enum LegalPage { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.page});
  final LegalPage page;

  @override
  Widget build(BuildContext context) {
    final privacy = page == LegalPage.privacy;
    final sections = privacy ? _privacySections : _termSections;

    return InfoPage(
      title: privacy ? 'Privacy Policy' : 'Terms of Use',
      children: [
        const Text(
          'Last updated: 20 October 2026',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
        for (final section in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.value,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: Color(0xFF52525A),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static const _privacySections = <MapEntry<String, String>>[
    MapEntry('Information we collect',
        'We store your name, email address, account type, followed stalls, search history, saved searches, notification history, self-collect bookings and device notification token. Bookings are shared between the customer and vendor through Firebase. Older bookings stored locally remain on that device only. Guest search history stays on the guest’s device until it is merged into a customer account after sign-in. Vendors may share their stall details and live location while using the service. Bookings use Stripe checkout. We store payment references, amounts and payment status; card details are entered on Stripe and are not stored by StallSeeker.'),
    MapEntry('How we use it',
        'We use this information to run your account, show nearby stalls and dishes, provide search suggestions, save favourites, send stall updates and keep the service secure.'),
    MapEntry('Location',
        'Customer location is used to show nearby stalls. Vendor location may be shown to customers when the stall is active. StallSeeker does not need location when these features are not being used.'),
    MapEntry('Sharing and storage',
        'Account and app data are stored using Firebase services. We do not sell personal information. Data may be processed by service providers needed to operate the app.'),
    MapEntry('Your choices',
        'You can turn off alerts in Notification settings, remove phone permissions in device settings, or delete your StallSeeker account from the Profile page.'),
    MapEntry('Data deletion',
        'Deleting your account removes your account and related StallSeeker data. Some security or legal records may be kept only when required by law.'),
    MapEntry('Contact',
        'For privacy questions, contact the StallSeeker team at support@stallseeker.my.'),
  ];

  static const _termSections = <MapEntry<String, String>>[
    MapEntry('Service purpose',
        'StallSeeker helps customers find food stalls and helps vendors share their status, menu and location.'),
    MapEntry('Account responsibility',
        'Use correct information, protect your password and do not use another person’s account. You are responsible for activity under your account.'),
    MapEntry('Vendor information',
        'Vendors are responsible for keeping their location, opening status, menu, prices and stock information accurate.'),
    MapEntry('Payments and refunds',
        'Payments and refunds are processed through Stripe. Payment must be confirmed before preparation. Cancelled paid bookings request a refund to the original payment method; refund status is shown in the booking.'),
    MapEntry('Acceptable use',
        'Do not misuse the service, post harmful or false content, interfere with the app, scrape private data or break applicable laws.'),
    MapEntry('Availability',
        'Stall locations, stock and opening status can change. StallSeeker cannot guarantee that every listing or live update is always correct or available.'),
    MapEntry('Account action',
        'We may limit or remove accounts that abuse the service or put other users at risk. You may delete your account from the Profile page.'),
    MapEntry('Changes and contact',
        'These terms may change as the service develops. For questions, contact support@stallseeker.my.'),
  ];
}
````

## File: lib/features/shared/logout_helper.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

Future<void> confirmAndLogout(
  BuildContext context,
  AuthService authService,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final signedOut = await showCupertinoModalPopup<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.black45,
    builder: (_) => _LogoutSheet(authService: authService),
  );
  if (signedOut == true && navigator.mounted) {
    navigator.popUntil((route) => route.isFirst);
  }
}

class _LogoutSheet extends StatefulWidget {
  const _LogoutSheet({required this.authService});

  final AuthService authService;

  @override
  State<_LogoutSheet> createState() => _LogoutSheetState();
}

class _LogoutSheetState extends State<_LogoutSheet> {
  bool _busy = false;
  String? _error;
  late final bool _guest =
      FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

  Future<void> _logout() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authService.signOut();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not finish logging out. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: CupertinoTheme(
          data: const CupertinoThemeData(primaryColor: AppColors.primary),
          child: CupertinoActionSheet(
            title: Text(_guest ? 'Leave Guest Mode?' : 'Log Out?'),
            message: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_guest
                    ? 'You can continue browsing or sign in at any time.'
                    : 'Are you sure you want to log out of StallSeeker?'),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(color: CupertinoColors.systemRed)),
                ],
              ],
            ),
            actions: [
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: _busy ? () {} : _logout,
                child: _busy
                    ? const CupertinoActivityIndicator()
                    : Text(_guest ? 'Leave Guest Mode' : 'Log Out'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: _busy ? () {} : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ),
        ),
      );
}
````

## File: lib/core/models/vendor_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stall_schedule.dart';

class VendorModel {
  // file ni represent 1 stall
  final String vendorId;
  final String stallName;
  final String description;
  final String category;
  final List<String> categories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<String> get allCategories => categories.isNotEmpty
      ? categories
      : (category.trim().isEmpty ? const [] : [category]);
  String get categoryLabel => allCategories.join(' · ');
  bool hasCategory(String value) => allCategories.contains(value);
  final String openingHours;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String phoneNumber;
  final Map<int, List<StallHoursInterval>> weeklyHours;
  final List<TemporaryClosure> temporaryClosures;
  final DateTime? locationUpdatedAt;
  final bool locationSharingActive;
  final bool selfCollectEnabled;

  bool get isTemporarilyClosed =>
      temporaryClosures.any((c) => c.contains(DateTime.now()));
  bool get isOpenNow => isOpen && !isTemporarilyClosed;
  bool isScheduledOpenAt(DateTime instant) =>
      isWithinStallSchedule(instant, weeklyHours, temporaryClosures);

  String get hoursToday {
    final day = malaysiaTime(DateTime.now()).weekday;
    if (weeklyHours.isEmpty) return openingHours;
    final intervals = weeklyHours[day] ?? [];
    if (intervals.isEmpty) return 'Closed today';
    return intervals
        .map((i) => '${formatStallTime(i.openMinute)} – '
            '${formatStallTime(i.closeMinute)}${i.closeMinute < i.openMinute ? ' (next day)' : ''}')
        .join(', ');
  }

  bool get hasValidLocation =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  bool get hasFreshLocation {
    // check kalau stall ada usable coordinates
    final updated = locationUpdatedAt;
    if (!locationSharingActive || updated == null) {
      return false;
    }
    final age = DateTime.now().difference(updated);
    return !age.isNegative && age < const Duration(minutes: 2);
  }

  // location update setiap 15sec, tapi kalau vendor punya gps fail/phone off lebih dua minit stall tutup

  VendorModel({
    required this.vendorId,
    required this.stallName,
    required this.description,
    required this.category,
    required this.openingHours,
    this.categories = const [],
    this.createdAt,
    this.updatedAt,
    this.isOpen = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.imageUrl = '',
    this.phoneNumber = '',
    this.weeklyHours = const {},
    this.temporaryClosures = const [],
    this.locationUpdatedAt,
    this.locationSharingActive = false,
    this.selfCollectEnabled = false,
  });

  /// Editable information only. Operational state belongs to the selling session.
  Map<String, dynamic> toProfileMap() => {
        'vendorId': vendorId,
        'stallName': stallName,
        'description': description,
        'category': allCategories.isEmpty ? '' : allCategories.first,
        'categories': allCategories,
        'openingHours': openingHours,
        'imageUrl': imageUrl,
        'phoneNumber': phoneNumber,
        'weeklyHours': serializeWeeklyHours(weeklyHours),
        'temporaryClosures': temporaryClosures.map((c) => c.toMap()).toList(),
      };

  // Convert VendorModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'stallName': stallName,
      'description': description,
      'category': allCategories.isEmpty ? '' : allCategories.first,
      'categories': allCategories,
      'openingHours': openingHours,
      'isOpen': isOpen,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'weeklyHours': serializeWeeklyHours(weeklyHours),
      'temporaryClosures': temporaryClosures.map((c) => c.toMap()).toList(),
      'selfCollectEnabled': selfCollectEnabled,
    };
  }

  // Create VendorModel from Firestore Document Snapshot
  factory VendorModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VendorModel(
      vendorId: documentId,
      stallName: map['stallName'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      categories: map['categories'] is List
          ? (map['categories'] as List)
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
          : const [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      openingHours: map['openingHours'] ?? '',
      isOpen: map['isOpen'] ?? false,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      weeklyHours: parseWeeklyHours(map['weeklyHours']),
      temporaryClosures: (map['temporaryClosures'] is List
              ? map['temporaryClosures'] as List
              : const [])
          .map(TemporaryClosure.fromMap)
          .whereType<TemporaryClosure>()
          .toList(),
      locationUpdatedAt: (map['locationUpdatedAt'] as Timestamp?)?.toDate(),
      locationSharingActive: map['locationSharingActive'] == true,
      selfCollectEnabled: map['selfCollectEnabled'] == true,
    );
  }

  // CopyWith method for easy state updates
  VendorModel copyWith({
    String? stallName,
    String? description,
    String? category,
    List<String>? categories,
    String? openingHours,
    bool? isOpen,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? phoneNumber,
    Map<int, List<StallHoursInterval>>? weeklyHours,
    List<TemporaryClosure>? temporaryClosures,
    bool? selfCollectEnabled,
  }) {
    return VendorModel(
      vendorId: vendorId,
      stallName: stallName ?? this.stallName,
      description: description ?? this.description,
      category: category ?? this.category,
      categories:
          categories ?? (category == null ? this.categories : [category]),
      createdAt: createdAt,
      updatedAt: updatedAt,
      openingHours: openingHours ?? this.openingHours,
      isOpen: isOpen ?? this.isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      temporaryClosures: temporaryClosures ?? this.temporaryClosures,
      locationUpdatedAt: locationUpdatedAt,
      locationSharingActive: locationSharingActive,
      selfCollectEnabled: selfCollectEnabled ?? this.selfCollectEnabled,
    );
  }
}
````

## File: lib/features/auth/screens/welcome_screen.dart
````dart
import '../../../core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onGuestAccessGranted});

  final VoidCallback? onGuestAccessGranted;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _auth = AuthService();
  bool _busy = false;
  bool _loginOpen = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    final error = await _auth.signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null && error != 'cancelled') {
      _showError(error);
    }
  }

  Future<void> _guest() async {
    if (_busy) {
      return;
    }

    if (_auth.currentUser?.isAnonymous == true) {
      widget.onGuestAccessGranted?.call();
      return;
    }

    setState(() => _busy = true);
    final error = await _auth.signInAsGuest();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null) {
      _showError(error);
      return;
    }

    widget.onGuestAccessGranted?.call();
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), backgroundColor: const Color(0xFFB3261E)));

  Future<void> _openLogin() async {
    setState(() => _loginOpen = true);
    await showLoginSheet(context);
    if (mounted) {
      setState(() => _loginOpen = false);
    }
  }

  Widget _button(
          {required Widget icon,
          required String label,
          required Color color,
          required Color textColor,
          required VoidCallback? onPressed}) =>
      SizedBox(
        height: 58,
        child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: textColor,
                disabledBackgroundColor: color.withValues(alpha: .65),
                disabledForegroundColor: textColor.withValues(alpha: .88),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              icon,
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ])),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF18181A),
        body: Stack(children: [
          Positioned.fill(
              child: ColoredBox(
                  color: Colors.white,
                  child: SafeArea(
                      bottom: false,
                      child: Stack(children: [
                        if (!_loginOpen)
                          Positioned(
                              top: 12,
                              left: 18,
                              child: AppBackButton(
                                  label: 'Continue as guest',
                                  enabled: !_busy,
                                  onPressed: _guest)),
                        Center(
                            child: Transform.translate(
                                offset: const Offset(0, -20),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset('assets/app_logo.png',
                                          width: 112, height: 112),
                                      const SizedBox(height: 18),
                                      const Text('StallSeeker',
                                          style: TextStyle(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
                                              letterSpacing: -1.1)),
                                      const SizedBox(height: 12),
                                      const Text(
                                          'Find nearby food stalls, live.',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF77777E))),
                                    ]))),
                      ])))),
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  padding: EdgeInsets.fromLTRB(
                      24, 28, 24, MediaQuery.paddingOf(context).bottom + 20),
                  decoration: const BoxDecoration(
                      color: Color(0xFF18181A),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(40))),
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            _button(
                                icon: Image.asset('assets/google_logo.png',
                                    width: 21, height: 21),
                                label: 'Continue with Google',
                                color: Colors.white,
                                textColor: Colors.black,
                                onPressed: _busy ? null : _google),
                            const SizedBox(height: 12),
                            _button(
                                icon: const Icon(Icons.mail_outline_rounded,
                                    size: 22),
                                label: 'Log in or sign up',
                                color: const Color(0xFF2D2D30),
                                textColor: Colors.white,
                                onPressed: _busy ? null : _openLogin),
                            if (_busy) ...[
                              const SizedBox(height: 16),
                              const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary)),
                            ],
                          ]))))),
        ]),
      );
}
````

## File: lib/features/shared/faq_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'account_ui.dart';
import 'info_page.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, required this.isVendor});
  final bool isVendor;
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqEntry {
  const _FaqEntry(this.group, this.question, this.answer);
  final String group;
  final String question;
  final String answer;
}

class _FaqScreenState extends State<FaqScreen> {
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const _customer = [
    _FaqEntry(
        'FINDING STALLS',
        'How do I find stalls or a specific dish near me?',
        'Open Home to see the map. Allow location access to find your area, or choose a saved place. Search by dish, stall name or food category. Suggestions appear as you type. Dish results show the price, stock, stall, distance and stall status.'),
    _FaqEntry('FINDING STALLS', 'Can I filter by price?',
        'On Home, tap Price and enter a minimum, maximum, or both in RM. Stalls must have a matching dish within that range. Tap the price chip to change the range or clear it.'),
    _FaqEntry('FINDING STALLS', 'How do I save Home or a custom map pin?',
        'Open Settings, then Home location or Custom pins. Search an address, pin the exact spot on the map, or use your current search location. Name custom places and select a saved place to find nearby stalls. Guest places stay on that device.'),
    _FaqEntry('FINDING STALLS', 'Does search remember what I looked for?',
        'Yes. Recent searches appear when you tap the search box. Guest history stays on that device and is merged into a customer account after sign-in. You can remove one search or clear them all.'),
    _FaqEntry('FINDING STALLS', 'Why can’t I see a stall on the map?',
        'The stall may be closed, outside the area shown, or hidden by a filter. Clear your filters and zoom out. Vendors need to share a valid location.'),
    _FaqEntry('FINDING STALLS', 'Where can I see the menu and stock?',
        'Open a stall’s details to see its menu and available stock. Stock is updated by the vendor, so check with them if you need to be certain.'),
    _FaqEntry('FOLLOWING & UPDATES', 'How do I follow or unfollow a stall?',
        'Sign in and open the stall’s details. Tap the follow or heart button. Your saved stalls appear in Following. Tap the button again to unfollow.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Can I get alerts for one dish?',
        'Sign in with a verified customer account, open the stall’s menu, and tap Follow dish. See your saved dishes in Following. An alert is created when a sold-out dish becomes available or low stock again. You can unfollow at any time.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Where are my past notifications?',
        'Open Notifications for saved stall-opening and dish-restock updates. Use All or Unread to filter the list. Tap a dish alert to open its menu. Older pushes sent before history was enabled are not added automatically.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Why am I not getting alerts?',
        'Check that you follow the stall or dish, are signed in, and have enabled alerts in Settings and your phone settings. Stall alerts arrive when it changes from closed to open. Dish alerts arrive when a sold-out dish is restocked. Your phone or network may delay delivery.'),
  ];
  static const _vendor = [
    _FaqEntry('YOUR STALL', 'How do I mark my stall as open?',
        'Use the stall status switch on your Dashboard. Allow location access and turn on your phone’s location services so customers can find you.'),
    _FaqEntry('YOUR STALL', 'Why is my stall missing from the map?',
        'Check that your stall is open and its location has updated. Customers may also need to clear filters or move the map to your area.'),
    _FaqEntry('MENU & STOCK', 'How do I update my menu and stock?',
        'Open Manage Menu & Stock from the Dashboard. Edit a dish’s details or change its stock status. Keep this updated when items sell out.'),
    _FaqEntry('MENU & STOCK', 'How do I change my stall photo?',
        'Open Settings, then My stall to edit your stall details and photo. Menu item photos can be changed in Manage Menu & Stock.'),
    _FaqEntry('STALL UPDATES', 'When are followers notified?',
        'An opening update is created when your stall changes from closed to open. Dish followers are alerted when you change a sold-out dish to available or low stock. Changing prices or moving your location alone does not send an alert. Push delivery depends on customer settings and connectivity.'),
  ];
  static const _account = [
    _FaqEntry('ACCOUNT', 'How do I change my name?',
        'Open Settings and tap Edit Profile. Enter your full name and save. Your avatar uses your account photo when available, or the first word of your name.'),
    _FaqEntry('ACCOUNT', 'I forgot my password. What should I do?',
        'Tap Forgot Password on Sign In and enter your account email. Follow the link in the email to set a new password. If you signed up with Google, use Continue with Google.'),
    _FaqEntry('ACCOUNT', 'Why is the reset email missing?',
        'Check the email address and look in Spam or Junk. If you requested the email and recognise the sender, mark it as not spam. Wait for the resend countdown before requesting another link.'),
    _FaqEntry('ACCOUNT', 'Will logging out delete my account?',
        'No. Logging out ends your session on this device. Your account and saved follows stay available when you sign in again.'),
  ];

  @override
  Widget build(BuildContext context) {
    final all = [...(widget.isVendor ? _vendor : _customer), ..._account];
    final entries = all
        .where(
            (e) => '${e.question} ${e.answer}'.toLowerCase().contains(_query))
        .toList();
    final groups = entries.map((e) => e.group).toSet();
    return InfoPage(title: 'Help & FAQ', children: [
      const Text('How can we help?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Find quick answers about your account and stalls.',
          style:
              TextStyle(fontSize: 14, color: Color(0xFF707078), height: 1.5)),
      const SizedBox(height: 20),
      TextField(
          controller: _search,
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: accountField('Search questions',
              suffix: _query.isEmpty
                  ? const Icon(Icons.search_rounded)
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded)))),
      const SizedBox(height: 28),
      if (entries.isEmpty)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text('No matching answers. Try a different word.',
                textAlign: TextAlign.center)),
      for (final group in groups) ...[
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(group,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF707078)))),
        _group(entries.where((e) => e.group == group).toList()),
        const SizedBox(height: 26),
      ],
    ]);
  }

  Widget _group(List<_FaqEntry> entries) => Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0)
            const Divider(
                height: .5,
                thickness: .5,
                indent: 18,
                endIndent: 18,
                color: AppColors.border),
          ExpansionTile(
              key: PageStorageKey(entries[i].question),
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              shape: const Border(),
              collapsedShape: const Border(),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              iconColor: AppColors.primary,
              collapsedIconColor: const Color(0xFF8E8E93),
              title: Text(entries[i].question,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF222222),
                      height: 1.4)),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(entries[i].answer,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF707078))))
              ]),
        ],
      ]));
}
````

## File: lib/core/theme/app_theme.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily:
          defaultTargetPlatform == TargetPlatform.iOS ? '.SF Pro Text' : null,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.cardColor,
        surfaceContainerLow: AppColors.background,
        surfaceContainer: AppColors.mint,
        outline: AppColors.border,
        onSurface: AppColors.textDark,
        error: const Color(0xFFFF453A),
      ),
      // Use the platform sans-serif consistently, without per-page Poppins overrides.
      textTheme: Typography.material2021().black.apply(
            bodyColor: AppColors.textDark,
            displayColor: AppColors.textDark,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            letterSpacing: 0),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.border, thickness: .5),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      )),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardColor,
        selectedColor: AppColors.mint,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(color: AppColors.textDark, fontSize: 12),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      scaffoldBackgroundColor: AppColors.background,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardColor,
        indicatorColor: AppColors.mint,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textDark)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textDark,
            size: 25)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72.0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(26)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(26)),
        ),
      ),
    );
  }
}
````

## File: lib/features/customer/following/customer_following_screen.dart
````dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/ios_grouped.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/follow_service.dart';
import '../../auth/screens/login_screen.dart';
import '../vendor_details/vendor_details_screen.dart';
import 'followed_dishes_list.dart';

class CustomerFollowingScreen extends StatefulWidget {
  const CustomerFollowingScreen({super.key});
  @override
  State<CustomerFollowingScreen> createState() =>
      _CustomerFollowingScreenState();
}

class _CustomerFollowingScreenState extends State<CustomerFollowingScreen> {
  final _follows = FollowService();
  final _vendors = VendorService();
  final _profiles = <String, VendorModel>{};
  final _subscriptions = <String, StreamSubscription<VendorModel?>>{};
  final _pending = <String>{};
  final _failed = <String>{};
  StreamSubscription<List<String>>? _followSubscription;
  bool _loading = true;
  bool _loadFailed = false;
  bool _openOnly = false;
  bool _ascending = true;
  int _generation = 0;
  bool _restarting = false;
  bool _showDishes = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    ++_generation;
    _followSubscription?.cancel();
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _listen() async {
    if (_restarting) {
      return;
    }
    _restarting = true;
    try {
      final generation = ++_generation;
      await _followSubscription?.cancel();
      for (final sub in _subscriptions.values) {
        await sub.cancel();
      }
      _subscriptions.clear();
      _pending.clear();
      _failed.clear();
      _profiles.clear();
      if (!mounted || generation != _generation) {
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
      _followSubscription =
          _follows.getFollowedVendorIds(user.uid).listen((ids) {
        if (!mounted || generation != _generation) {
          return;
        }
        final active = ids.toSet();
        for (final id in _subscriptions.keys.toList()) {
          if (!active.contains(id)) {
            _subscriptions.remove(id)?.cancel();
            _profiles.remove(id);
            _pending.remove(id);
            _failed.remove(id);
          }
        }
        setState(() {
          _loading = false;
          _loadFailed = false;
        });
        for (final id in active) {
          if (_subscriptions.containsKey(id)) {
            continue;
          }
          _pending.add(id);
          _subscriptions[id] = _vendors.watchVendorProfile(id).listen((vendor) {
            if (!mounted ||
                generation != _generation ||
                !_subscriptions.containsKey(id)) {
              return;
            }
            setState(() {
              _pending.remove(id);
              _failed.remove(id);
              if (vendor == null) {
                _profiles.remove(id);
              } else {
                _profiles[id] = vendor;
              }
            });
          }, onError: (Object error) {
            if (!mounted ||
                generation != _generation ||
                !_subscriptions.containsKey(id)) {
              return;
            }
            setState(() {
              _pending.remove(id);
              _failed.add(id);
              _profiles.remove(id);
            });
          });
        }
      }, onError: (Object error) {
        if (mounted && generation == _generation) {
          setState(() {
            _loading = false;
            _loadFailed = true;
          });
        }
      });
    } finally {
      _restarting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final guest = user == null || user.isAnonymous;
    final sorted = _profiles.values.toList()
      ..sort((a, b) {
        final comparison =
            a.stallName.toLowerCase().compareTo(b.stallName.toLowerCase());
        return _ascending ? comparison : -comparison;
      });
    final open = sorted.where((vendor) => vendor.isOpenNow).toList();
    final closed = sorted.where((vendor) => !vendor.isOpenNow).toList();
    return ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
              onRefresh: _listen,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 112),
                children: [
                  Center(
                      child: CupertinoSlidingSegmentedControl<bool>(
                    backgroundColor: const Color(0xFFE2E2E7),
                    thumbColor: Colors.white,
                    groupValue: _showDishes,
                    children: const {
                      false: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
                          child: Text('Stalls')),
                      true: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
                          child: Text('Dishes')),
                    },
                    onValueChanged: (value) {
                      if (value != null) setState(() => _showDishes = value);
                    },
                  )),
                  const SizedBox(height: 20),
                  if (!_showDishes)
                    Row(children: [
                      IconButton(
                          tooltip: _ascending ? 'Sort Z to A' : 'Sort A to Z',
                          onPressed: () =>
                              setState(() => _ascending = !_ascending),
                          icon: const Icon(Icons.sort_by_alpha_rounded,
                              color: AppColors.primary)),
                      Expanded(
                          child: Center(
                              child: CupertinoSlidingSegmentedControl<bool>(
                        backgroundColor: const Color(0xFFE2E2E7),
                        thumbColor: Colors.white,
                        groupValue: _openOnly,
                        children: const {
                          false: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text('All stalls')),
                          true: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text('Open now')),
                        },
                        onValueChanged: (value) {
                          if (value != null) {
                            setState(() => _openOnly = value);
                          }
                        },
                      ))),
                      IconButton(
                          tooltip: 'Refresh followed stalls',
                          onPressed: _listen,
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.primary)),
                    ]),
                  if (!_showDishes) const SizedBox(height: 24),
                  if (guest)
                    _notice('Keep your favourites here',
                        'Sign in, then follow a stall or a dish on its menu.',
                        action: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen())),
                            child: const Text('Sign in')))
                  else if (_showDishes)
                    FollowedDishesList(key: ValueKey(user.uid), uid: user.uid)
                  else if (_loading || (_pending.isNotEmpty && sorted.isEmpty))
                    const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()))
                  else if (_loadFailed)
                    _notice('Could not load followed stalls',
                        'Check your connection and retry.',
                        action: TextButton(
                            onPressed: _listen, child: const Text('Retry')))
                  else ...[
                    if (_failed.isNotEmpty)
                      _notice(
                          'Some stalls could not load', 'Pull down to retry.'),
                    if (open.isNotEmpty) _group('OPEN NOW', open),
                    if (!_openOnly && closed.isNotEmpty)
                      _group('CLOSED', closed),
                    if (_openOnly && open.isEmpty)
                      _notice('No followed stalls are open',
                          'Check again later, or switch to All stalls.'),
                    if (!_openOnly && sorted.isEmpty && _failed.isEmpty)
                      _notice('No followed stalls yet',
                          'Find a stall on the map and tap Follow to save it here.'),
                  ],
                ],
              )),
        ));
  }

  Widget _group(String label, List<VendorModel> vendors) => Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text('$label · ${vendors.length}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
          AppGroupedCard(children: [
            for (var index = 0; index < vendors.length; index++) ...[
              _stallRow(vendors[index]),
            ],
          ]),
        ]),
      );

  Widget _stallRow(VendorModel vendor) => ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: AppIconTile(
            icon: Icons.storefront_rounded,
            color:
                vendor.isOpenNow ? AppColors.primary : const Color(0xFF949499)),
        title: Text(
            vendor.stallName.isEmpty ? 'Unnamed stall' : vendor.stallName,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(vendor.categoryLabel,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF8E8E93), letterSpacing: 0))),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(vendor.isOpenNow ? 'Open' : 'Closed',
              style: TextStyle(
                  fontSize: 12,
                  color: vendor.isOpenNow
                      ? const Color(0xFF15803D)
                      : const Color(0xFF8E8E93))),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2), size: 20),
        ]),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VendorDetailsScreen(vendor: vendor))),
      );

  Widget _notice(String title, String body, {Widget? action}) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8E8E93))),
          if (action != null) action,
        ]),
      );
}
````

## File: lib/features/shared/profile_page.dart
````dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

/// iOS-style grouped settings, with StallSeeker's existing account actions.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    required this.isVendor,
    required this.isGuest,
    required this.canChangePassword,
    required this.location,
    required this.isLoadingLocation,
    required this.onRefresh,
    required this.onLocation,
    required this.onEdit,
    required this.onPassword,
    required this.onFaq,
    required this.onAbout,
    required this.onLogout,
    required this.onSignIn,
    this.onNotificationSettings,
    required this.onPrivacyPolicy,
    required this.onTerms,
    required this.onDeleteAccount,
    this.onEditStall,
    this.onOrders,
    this.bookingSection,
    this.onPersonalInformation,
    this.onHomeLocation,
    this.onCustomLocation,
    this.homeLocation = 'Choose or save your home pin',
    this.customLocation = 'Manage your saved places',
  });

  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isVendor;
  final bool isGuest;
  final bool canChangePassword;
  final String location;
  final bool isLoadingLocation;
  final Future<void> Function() onRefresh;
  final VoidCallback onLocation;
  final VoidCallback onEdit;
  final VoidCallback onPassword;
  final VoidCallback onFaq;
  final VoidCallback onAbout;
  final VoidCallback onLogout;
  final VoidCallback onSignIn;
  final VoidCallback? onNotificationSettings;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTerms;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onEditStall;
  final VoidCallback? onOrders;
  final Widget? bookingSection;
  final VoidCallback? onPersonalInformation;
  final VoidCallback? onHomeLocation;
  final VoidCallback? onCustomLocation;
  final String homeLocation;
  final String customLocation;

  static const background = AppColors.background;
  static const accent = AppColors.primary;
  static const muted = Color(0xFF8E8E93);
  static const divider = Color(0xFFE5E5E8);

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  Widget _avatar() => ClipOval(
        child: SizedBox(
          width: 100,
          height: 100,
          child: photoUrl == null || photoUrl!.trim().isEmpty
              ? const ColoredBox(
                  color: Color(0xFFF3DED1),
                  child:
                      Icon(CupertinoIcons.person_fill, size: 60, color: accent),
                )
              : Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(_initial,
                        style: const TextStyle(fontSize: 45, color: accent)),
                  ),
                ),
        ),
      );

  Widget _header() {
    final contact = [
      if (phoneNumber?.trim().isNotEmpty == true) phoneNumber!.trim(),
      if (email.trim().isNotEmpty) email.trim(),
    ].join(' · ');
    return Column(children: [
      SizedBox(
        height: 116,
        child: Stack(alignment: Alignment.topCenter, children: [
          Positioned(top: 12, child: _avatar()),
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.white,
              shape: const StadiumBorder(),
              elevation: 5,
              shadowColor: const Color(0x18000000),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: isGuest ? onSignIn : onEdit,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                  child: Text(isGuest ? 'Sign in' : 'Edit',
                      style:
                          const TextStyle(fontSize: 17, color: Colors.black)),
                ),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 9),
      Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.1,
          letterSpacing: -0.6,
          color: Colors.black,
        ),
      ),
      if (contact.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(
          contact,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, height: 1.2, color: muted),
        ),
      ],
    ]);
  }

  Widget _group(List<Widget> rows) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.only(left: 60, right: 16),
                child: Divider(height: .5, thickness: .5, color: divider),
              ),
            rows[index],
          ],
        ]),
      );

  Widget _row(
    IconData icon,
    Color iconColor,
    String label,
    VoidCallback onTap, {
    String? value,
    String? subtitle,
    Widget? trailing,
  }) =>
      InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: iconColor == AppColors.primary
                      ? AppColors.logoGradient
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(Colors.white, iconColor, .78)!,
                            iconColor,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17,
                          height: 1.2,
                          letterSpacing: -0.2,
                          color: Colors.black),
                    ),
                    if (subtitle != null)
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: muted)),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, color: muted)),
                ),
              ],
              const SizedBox(width: 8),
              trailing ??
                  const Icon(CupertinoIcons.chevron_right,
                      size: 17, color: Color(0xFFB6B6B8)),
            ]),
          ),
        ),
      );

  Widget _editAction() => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isGuest ? onSignIn : onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            child: Row(children: [
              const Icon(CupertinoIcons.camera_on_rectangle,
                  color: accent, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isGuest ? 'Sign in to edit profile' : 'Edit Profile',
                  style: const TextStyle(fontSize: 17, color: accent),
                ),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .28, .6],
              colors: [Colors.white, background, background],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 116),
                children: [
                  _header(),
                  const SizedBox(height: 45),
                  _editAction(),
                  const SizedBox(height: 24),
                  if (!isGuest) ...[
                    _group([
                      _row(
                          CupertinoIcons.person_crop_circle_fill,
                          const Color(0xFFFF5956),
                          'My Profile',
                          onPersonalInformation ?? onEdit),
                    ]),
                    const SizedBox(height: 24),
                  ],
                  if (bookingSection != null) ...[
                    bookingSection!,
                    const SizedBox(height: 24),
                  ],
                  _group([
                    _row(CupertinoIcons.location_solid, const Color(0xFF43CE72),
                        'Current Location', onLocation,
                        subtitle: location,
                        trailing: isLoadingLocation
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null),
                    if (onHomeLocation != null)
                      _row(CupertinoIcons.house_fill, AppColors.primary,
                          'Home location', onHomeLocation!),
                    if (onCustomLocation != null)
                      _row(CupertinoIcons.map_fill, AppColors.primaryLight,
                          'Custom pins', onCustomLocation!),
                    if (isVendor && onEditStall != null)
                      _row(CupertinoIcons.bag_fill, const Color(0xFFFFAE22),
                          'My Stall', onEditStall!),
                    if (onOrders != null)
                      _row(CupertinoIcons.square_list_fill,
                          const Color(0xFFFFAE22), 'My Bookings', onOrders!),
                  ]),
                  if (!isGuest) ...[
                    const SizedBox(height: 24),
                    _group([
                      if (!isVendor && onNotificationSettings != null)
                        _row(
                            CupertinoIcons.bell_fill,
                            const Color(0xFFFF5555),
                            'Notifications and Sounds',
                            onNotificationSettings!),
                      _row(CupertinoIcons.lock_fill, const Color(0xFF949499),
                          'Privacy Policy', onPrivacyPolicy),
                      _row(CupertinoIcons.doc_text_fill,
                          const Color(0xFF42C96D), 'Terms of Use', onTerms),
                      if (canChangePassword)
                        _row(
                            CupertinoIcons.padlock_solid,
                            AppColors.primaryLight,
                            'Change password',
                            onPassword),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  _group([
                    _row(CupertinoIcons.question_circle_fill,
                        const Color(0xFFAD55E8), 'Help & FAQ', onFaq),
                    _row(CupertinoIcons.info_circle_fill,
                        const Color(0xFF8288EF), 'About StallSeeker', onAbout),
                  ]),
                  if (!isGuest) ...[
                    const SizedBox(height: 24),
                    _group([
                      _row(CupertinoIcons.trash_fill, const Color(0xFFFF5956),
                          'Delete account', onDeleteAccount),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  _group([
                    _row(
                        CupertinoIcons.square_arrow_right,
                        const Color(0xFF949499),
                        isGuest ? 'Leave guest mode' : 'Logout',
                        onLogout),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/vendor/profile/vendor_profile_screen.dart
````dart
import 'edit_stall_screen.dart';
import '../../shared/profile_page.dart';
import '../../shared/edit_profile_screen.dart';
import '../../shared/personal_information_screen.dart';
import '../../shared/change_password_screen.dart';
import '../../shared/legal_screen.dart';
import '../../shared/delete_account_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../shared/faq_screen.dart';
import '../../shared/about_screen.dart';
import '../../shared/logout_helper.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _authService = AuthService();
  final _geocoding = Geocoding();

  UserModel? _userModel;
  String _phoneNumber = '';
  bool _isLoading = true;

  // Current Location section state -- shows the vendor's live GPS
  // position (turned into a readable address via reverse geocoding),
  // same pattern as the customer profile screen.
  String _locationText = 'Tap to find your current area';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      final vendor = await VendorService().getVendorProfile(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userData;
          _phoneNumber = vendor?.phoneNumber ?? '';
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocation() async {
    if (!mounted || _isLoadingLocation) {
      return;
    }
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) {
        return;
      }
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services are turned off.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) {
        return;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission not granted.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));

      final placemarks = await _geocoding
          .placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          )
          .timeout(const Duration(seconds: 8));
      final address =
          _formatPlacemark(placemarks.isNotEmpty ? placemarks.first : null);

      if (mounted) {
        setState(() {
          _locationText = address;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  String _formatPlacemark(Placemark? p) {
    if (p == null) {
      return 'Location unavailable';
    }
    final parts = [p.subLocality, p.locality, p.administrativeArea]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Location unavailable' : parts.join(', ');
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => EditProfileScreen(
                name: _userModel?.fullName ?? user?.displayName ?? '',
                email: _userModel?.email ?? user?.email ?? '')));
    if (saved == true && mounted) {
      await _loadUserData();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    }
  }

  Future<void> _personalInformation() async {
    final user = FirebaseAuth.instance.currentUser;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PersonalInformationScreen(
                name: _userModel?.fullName ?? user?.displayName ?? '',
                email: _userModel?.email ?? user?.email ?? '',
                isVendor: true)));
    if (mounted) {
      await _loadUserData();
    }
  }

  void _changePassword() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(
                email: _userModel?.email ??
                    FirebaseAuth.instance.currentUser?.email ??
                    '')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = FirebaseAuth.instance.currentUser;
    final guest = user?.isAnonymous ?? true;
    final name = guest
        ? 'Guest'
        : _userModel?.fullName.isNotEmpty == true
            ? _userModel!.fullName
            : user?.displayName ?? 'Your profile';
    return ProfilePage(
      name: name,
      email: guest ? '' : _userModel?.email ?? user?.email ?? '',
      photoUrl: guest ? null : user?.photoURL,
      phoneNumber: guest ? null : _phoneNumber,
      isVendor: true,
      isGuest: guest,
      canChangePassword: user?.providerData
              .any((provider) => provider.providerId == 'password') ??
          false,
      location: _locationText,
      isLoadingLocation: _isLoadingLocation,
      onRefresh: _loadUserData,
      onLocation: _loadLocation,
      onEdit: _editProfile,
      onPersonalInformation: _personalInformation,
      onPassword: _changePassword,
      onFaq: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: true))),
      onAbout: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onPrivacyPolicy: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const LegalScreen(page: LegalPage.privacy))),
      onTerms: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const LegalScreen(page: LegalPage.terms))),
      onDeleteAccount: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      onEditStall: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const EditStallScreen())),
    );
  }
}
````

## File: lib/features/vendor/vendor_main_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_pill_navigation.dart';
import '../../core/services/demo_order_service.dart';
import 'dashboard/vendor_dashboard_screen.dart';
import 'profile/vendor_profile_screen.dart';
import '../shared/profile_page.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  int _selectedIndex = 0;
  late final Stream<int> _newBookings = DemoOrderService().watchUnseenCount(
      FirebaseAuth.instance.currentUser?.uid ?? '',
      isVendor: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor:
          _selectedIndex == 1 ? ProfilePage.background : AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            const SafeArea(bottom: false, child: VendorDashboardScreen()),
            const VendorProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: AppPillNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: _dashboardIcon(false),
            selectedIcon: _dashboardIcon(true),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(CupertinoIcons.gear),
            selectedIcon: Icon(CupertinoIcons.gear_solid),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _dashboardIcon(bool selected) => StreamBuilder<int>(
      stream: _newBookings,
      builder: (context, snapshot) => Badge(
            isLabelVisible: (snapshot.data ?? 0) > 0,
            label: Text(
                (snapshot.data ?? 0) > 99 ? '99+' : '${snapshot.data ?? 0}'),
            child: Icon(
                selected
                    ? CupertinoIcons.square_grid_2x2_fill
                    : CupertinoIcons.square_grid_2x2,
                color: selected ? AppColors.textDark : AppColors.textMuted),
          ));
}
````

## File: lib/main.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app's background is light (white/cream), so the status bar's
  // time/battery/signal icons need to render dark to stay visible --
  // otherwise they default to light and blend into the light
  // background, becoming nearly invisible. Set globally here so it
  // applies even on screens that override AppBar styling directly.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    runApp(MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
            'StallSeeker could not start. Check your connection and retry.'),
        TextButton(onPressed: main, child: const Text('Retry')),
      ]),
    )))));
    return;
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const StallSeekerApp());
  unawaited(NotificationService.instance
      .initialize(navigatorKey)
      .catchError((Object error) {
    debugPrint('Notifications are currently unavailable.');
  }));
}

class StallSeekerApp extends StatelessWidget {
  const StallSeekerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'StallSeeker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
````

## File: lib/features/auth/screens/register_screen.dart
````dart
import '../../../core/widgets/app_back_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/vendor_phone.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  String _role = 'customer';
  bool _busy = false;
  bool _hidePassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await _auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
        role: _role,
        vendorPhone: _role == 'vendor' ? _phone.text : null,
        customerPhone: _role == 'customer' ? _phone.text : null);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error), backgroundColor: const Color(0xFFB3261E)));
    }
  }

  Future<void> _guest() async {
    if (_busy) return;
    if (FirebaseAuth.instance.currentUser?.isAnonymous == true) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _busy = true);
    final error = await _auth.signInAsGuest();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.maybePop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error), backgroundColor: const Color(0xFFB3261E)));
    }
  }

  InputDecoration _field(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: Color(0xFFB3261E))),
      );

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppBackButton(
                label: 'Continue as guest',
                enabled: !_busy,
                onPressed: _guest)),
        Expanded(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),
                        const Icon(Icons.storefront_rounded,
                            size: 46, color: AppColors.primary),
                        const SizedBox(height: 14),
                        const Text('Create your account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.4)),
                        const SizedBox(height: 7),
                        const Text(
                            'Save favourite stalls and receive live updates.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Color(0xFF707078))),
                        const SizedBox(height: 28),
                        TextFormField(
                            controller: _name,
                            textInputAction: TextInputAction.next,
                            decoration: _field('Full name'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter your name.'
                                : null),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _field('Email address'),
                            validator: (v) =>
                                v == null || !v.trim().contains('@')
                                    ? 'Enter a valid email address.'
                                    : null),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: _password,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.next,
                            decoration: _field('Password',
                                suffix: IconButton(
                                    onPressed: () => setState(
                                        () => _hidePassword = !_hidePassword),
                                    icon: Icon(_hidePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined))),
                            validator: (v) => v == null || v.length < 6
                                ? 'Use at least 6 characters.'
                                : null),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: _confirm,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            decoration: _field('Confirm password'),
                            validator: (v) => v != _password.text
                                ? 'Passwords do not match.'
                                : null),
                        const SizedBox(height: 18),
                        const Text('Account type',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF707078))),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                  value: 'customer',
                                  icon: Icon(Icons.person_outline),
                                  label: Text('Customer')),
                              ButtonSegment(
                                  value: 'vendor',
                                  icon: Icon(Icons.storefront_outlined),
                                  label: Text('Vendor')),
                            ],
                            selected: {
                              _role
                            },
                            onSelectionChanged: _busy
                                ? null
                                : (v) => setState(() => _role = v.first),
                            style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16))))),
                        ...[
                          const SizedBox(height: 12),
                          TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              decoration: _field(_role == 'vendor'
                                  ? 'Business phone number'
                                  : 'Phone number (optional)'),
                              validator: (value) {
                                final input = (value ?? '').trim();
                                if (_role == 'customer' && input.isEmpty) {
                                  return null;
                                }
                                return normalizeVendorPhone(input) == null
                                    ? 'Enter a valid Malaysian phone number.'
                                    : null;
                              }),
                          Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                  _role == 'vendor'
                                      ? 'Customers can see and call this number from your stall listing.'
                                      : 'You can leave this blank and add it later in your profile.',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF707078)))),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                            height: 56,
                            child: FilledButton(
                                onPressed: _busy ? null : _register,
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(28))),
                                child: _busy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Text('Create account',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)))),
                        const SizedBox(height: 18),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ',
                                  style: TextStyle(color: Color(0xFF707078))),
                              TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginScreen())),
                                  child: const Text('Sign in',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600))),
                            ]),
                      ]))),
        ))),
      ])));
}
````

## File: lib/features/vendor/profile/edit_stall_screen.dart
````dart
import 'unsaved_stall_changes_guard.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stall_categories.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/storage_service.dart';
import 'edit_stall_view.dart';
import 'stall_profile_draft.dart';
import '../../customer/vendor_details/vendor_details_screen.dart';

class EditStallScreen extends StatefulWidget {
  const EditStallScreen({super.key});

  @override
  State<EditStallScreen> createState() => _EditStallScreenState();
}

class _EditStallScreenState extends State<EditStallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();
  final _storageService = StorageService();
  final _auth = FirebaseAuth.instance;

  final _stallNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _phoneController = TextEditingController();

  final _selectedCategories = <String>{'Beverages'};
  String? _initialValues;
  final _exitGuard = GlobalKey<UnsavedStallChangesGuardState>();
  final List<String> _categories = stallCategories;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  VendorModel? _loadedVendor;
  String? _loadError;
  Map<int, List<StallHoursInterval>> _weeklyHours = {};
  List<TemporaryClosure> _temporaryClosures = [];

  // Existing photo URL loaded from Firestore, and a newly picked local
  // file (not yet uploaded) if the vendor chose a new photo this session.
  String _existingImageUrl = '';
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadExistingVendorData();
  }

  // Fetch vendor info from Firestore to pre-fill the form
  Future<void> _loadExistingVendorData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'Sign in again to edit your stall.';
      });
      return;
    }
    VendorModel? vendor = await _vendorService.getVendorProfile(user.uid);
    if (!mounted) return;
    _loadedVendor = vendor ??
        VendorModel(
            vendorId: user.uid,
            stallName: '',
            description: '',
            category: 'Beverages',
            openingHours: '');
    if (vendor != null) {
      _stallNameController.text = vendor.stallName;
      _descriptionController.text = vendor.description;
      _openingHoursController.text = vendor.openingHours;
      _weeklyHours = vendor.weeklyHours;
      _temporaryClosures = vendor.temporaryClosures;
      _phoneController.text = vendor.phoneNumber;
      _existingImageUrl = vendor.imageUrl;
      _selectedCategories
        ..clear()
        ..addAll(vendor.allCategories);
      if (_selectedCategories.isEmpty) _selectedCategories.add('Beverages');
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _initialValues = _currentValues();
    });
  }

  Future<void> _pickImage() async {
    if (_isSaving || _isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final file = await _storageService.pickImage();
      if (file != null && mounted) {
        setState(() => _pickedImage = file);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open your photos. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // Save updated stall profile to Firestore
  Future<void> _saveStallProfile() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose at least one food category.')));
      return;
    }
    if (_isLoading ||
        _isSaving ||
        _isPickingImage ||
        _formKey.currentState?.validate() != true) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Only upload if the vendor picked a new photo this session.
      // Otherwise keep whatever URL was already saved.
      String imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl =
            await _storageService.uploadStallImage(user.uid, _pickedImage!);
      }

      final vendor = _draftVendor(imageUrl: imageUrl);

      await _vendorService.saveVendorProfile(vendor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stall profile saved successfully!')),
        );
        _exitGuard.currentState?.close();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _stallNameController.dispose();
    _descriptionController.dispose();
    _openingHoursController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _currentValues() => jsonEncode({
        'name': _stallNameController.text,
        'description': _descriptionController.text,
        'phone': _phoneController.text,
        'hours': _openingHoursController.text,
        'categories': _selectedCategories.toList()..sort(),
        'weeklyHours': serializeWeeklyHours(_weeklyHours),
        'closures': _temporaryClosures
            .map((closure) => [
                  closure.start.toUtc().millisecondsSinceEpoch,
                  closure.end.toUtc().millisecondsSinceEpoch,
                ])
            .toList(),
      });

  bool get _hasUnsavedChanges =>
      !_isLoading &&
      _loadError == null &&
      _loadedVendor != null &&
      (_pickedImage != null || _currentValues() != _initialValues);

  void _requestLeave() => _exitGuard.currentState?.requestLeave();

  VendorModel _draftVendor({String? imageUrl}) => buildStallProfileDraft(
        original: _loadedVendor!,
        name: _stallNameController.text,
        description: _descriptionController.text,
        phone: _phoneController.text,
        legacyHours: _openingHoursController.text,
        categories: _selectedCategories,
        hours: _weeklyHours,
        closures: _temporaryClosures,
        imageUrl: imageUrl,
      );

  void _preview() {
    if (_isLoading || _isSaving || _isPickingImage || _loadedVendor == null) {
      return;
    }
    if (_auth.currentUser?.uid != _loadedVendor!.vendorId) return;
    FocusScope.of(context).unfocus();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => VendorDetailsScreen(
                vendor: _draftVendor(),
                previewOnly: true,
                draftPreview: true,
                draftPhoto: _pickedImage)));
  }

  Widget _buildImagePicker() {
    final placeholder = const Center(
        child: Icon(Icons.storefront_outlined,
            size: 52, color: AppColors.primary));
    final image = _pickedImage != null
        ? Image.file(_pickedImage!,
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
        : _existingImageUrl.isNotEmpty
            ? Image.network(_existingImageUrl,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
            : placeholder;
    return LayoutBuilder(
        builder: (context, constraints) => SizedBox(
              height:
                  (constraints.maxWidth * 9 / 16).clamp(160, 260).toDouble(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                    color: AppColors.mint,
                    child: InkWell(
                      onTap: _isSaving || _isPickingImage ? null : _pickImage,
                      child: Stack(fit: StackFit.expand, children: [
                        image,
                        Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Center(
                                child: FilledButton.icon(
                                    onPressed: _isSaving || _isPickingImage
                                        ? null
                                        : _pickImage,
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.primary,
                                        minimumSize: const Size(48, 48),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 12)),
                                    icon: const Icon(Icons.camera_alt_outlined,
                                        size: 20),
                                    label: Text(_isPickingImage
                                        ? 'Opening photos…'
                                        : 'Change photo')))),
                      ]),
                    )),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) => UnsavedStallChangesGuard(
        key: _exitGuard,
        hasChanges: _hasUnsavedChanges,
        saving: _isSaving,
        onSave: _saveStallProfile,
        child: EditStallView(
          formKey: _formKey,
          nameController: _stallNameController,
          descriptionController: _descriptionController,
          phoneController: _phoneController,
          image: _buildImagePicker(),
          categoryOptions: _categories,
          selectedCategories: _selectedCategories,
          legacyHours: _openingHoursController.text,
          hours: _weeklyHours,
          closures: _temporaryClosures,
          loading: _isLoading,
          saving: _isSaving,
          pickingImage: _isPickingImage,
          newPhoto: _pickedImage != null,
          error: _loadError,
          onRetry: _loadExistingVendorData,
          onFormChanged: () => setState(() {}),
          onCancel: _requestLeave,
          onSave: _saveStallProfile,
          onPreview: _preview,
          onCategoryChanged: (category, selected) => setState(() {
            if (selected) {
              _selectedCategories.add(category);
            } else {
              _selectedCategories.remove(category);
            }
          }),
          onScheduleChanged: (hours, closures) => setState(() {
            _weeklyHours = hours;
            _temporaryClosures = closures;
          }),
        ),
      );
}
````

## File: lib/features/vendor/menu/vendor_menu_screen.dart
````dart
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_dropdown.dart';

class VendorMenuScreen extends StatefulWidget {
  const VendorMenuScreen({super.key, this.stockOnly = false});
  final bool stockOnly;
  @override
  State<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends State<VendorMenuScreen> {
  final _menu = MenuService();
  final _storage = StorageService();
  final _busyItems = <String>{};
  late Stream<List<MenuItemModel>> _items;
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  static const _statuses = {
    'available': ('Available', Colors.green),
    'low_stock': ('Low stock', Colors.orange),
    'out_of_stock': ('Sold out', Colors.red),
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = _uid == null
        ? Stream.value(<MenuItemModel>[])
        : _menu.getMenuItems(_uid);
  }

  void _error(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _status(MenuItemModel item, String status) async {
    if (_uid == null ||
        _busyItems.contains(item.itemId) ||
        item.status == status) {
      return;
    }
    setState(() => _busyItems.add(item.itemId));
    try {
      await _menu.updateItemStatus(_uid, item.itemId, status);
    } catch (_) {
      _error('Could not update stock. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _busyItems.remove(item.itemId));
      }
    }
  }

  Future<void> _delete(MenuItemModel item) async {
    if (_uid == null || _busyItems.contains(item.itemId)) {
      return;
    }
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Delete dish?'),
              content: Text(
                  'Delete ${item.name} from your menu? This cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete')),
              ],
            ));
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busyItems.add(item.itemId));
    try {
      await _menu.deleteMenuItem(_uid, item.itemId);
    } catch (_) {
      _error('Could not delete this dish. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _busyItems.remove(item.itemId));
      }
    }
  }

  Future<void> _edit([MenuItemModel? item]) async {
    if (_uid == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) =>
          _MenuEditor(uid: _uid, item: item, menu: _menu, storage: _storage),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppPageAppBar(
            title: Text(widget.stockOnly ? 'Update stock' : 'Menu & stock')),
        floatingActionButton: _uid == null || widget.stockOnly
            ? null
            : FloatingActionButton.extended(
                onPressed: _edit,
                icon: const Icon(Icons.add),
                label: const Text('Add dish')),
        body: StreamBuilder<List<MenuItemModel>>(
            stream: _items,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Could not load your menu.'),
                  TextButton(
                      onPressed: () => setState(_reload),
                      child: const Text('Retry')),
                ]));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                    child: Text(
                        widget.stockOnly
                            ? 'No dishes to update.\nAdd dishes from Menu first.'
                            : 'Your menu is empty.\nTap Add dish to get started.',
                        textAlign: TextAlign.center));
              }
              return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final busy = _busyItems.contains(item.itemId);
                    return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: item.imageUrl.isEmpty
                                              ? const Icon(Icons.restaurant,
                                                  size: 32)
                                              : Image.network(item.imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                          Icons.restaurant,
                                                          size: 32)))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(item.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        Text(
                                            'RM ${item.price.toStringAsFixed(2)}'),
                                        Text(item.section,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ])),
                                  if (!widget.stockOnly)
                                    AppDropdown<String>(
                                      iconOnly: true,
                                      icon: Icons.more_vert,
                                      hint: 'Dish options',
                                      options: const {
                                        'edit': 'Edit dish',
                                        'delete': 'Delete dish',
                                      },
                                      onChanged: busy
                                          ? null
                                          : (value) {
                                              if (value == 'edit') {
                                                _edit(item);
                                              } else {
                                                _delete(item);
                                              }
                                            },
                                    ),
                                ]),
                                const SizedBox(height: 12),
                                Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: _statuses.entries
                                        .map((entry) => ChoiceChip(
                                              label: Text(entry.value.$1),
                                              avatar: Icon(Icons.circle,
                                                  size: 12,
                                                  color: entry.value.$2),
                                              selected:
                                                  item.status == entry.key,
                                              onSelected: busy
                                                  ? null
                                                  : (_) =>
                                                      _status(item, entry.key),
                                            ))
                                        .toList()),
                                if (busy) const LinearProgressIndicator(),
                              ]),
                        ));
                  });
            }),
      );
}

class _MenuEditor extends StatefulWidget {
  const _MenuEditor(
      {required this.uid,
      required this.item,
      required this.menu,
      required this.storage});
  final String uid;
  final MenuItemModel? item;
  final MenuService menu;
  final StorageService storage;
  @override
  State<_MenuEditor> createState() => _MenuEditorState();
}

class _MenuEditorState extends State<_MenuEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _section;
  late final TextEditingController _description;
  late final TextEditingController _portion;
  late final TextEditingController _ingredients;
  late final String _itemId;
  File? _image;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _price = TextEditingController(
        text: widget.item?.price.toStringAsFixed(2) ?? '');
    _section = TextEditingController(text: widget.item?.section ?? 'Main menu');
    _description = TextEditingController(text: widget.item?.description ?? '');
    _portion = TextEditingController(text: widget.item?.portionSize ?? '');
    _ingredients =
        TextEditingController(text: widget.item?.ingredients.join(', ') ?? '');
    // Reuse the same ID on retries so an uncertain network result cannot duplicate a dish.
    _itemId = widget.item?.itemId ?? widget.menu.newMenuItemId(widget.uid);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _section.dispose();
    _description.dispose();
    _portion.dispose();
    _ingredients.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final image = await widget.storage.pickImage();
      if (mounted && image != null) {
        setState(() => _image = image);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open your photos. Please retry.');
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await widget.storage
            .uploadMenuItemImage(widget.uid, _itemId, _image!);
      }
      if (widget.item == null) {
        await widget.menu.addMenuItem(
            widget.uid, _name.text.trim(), double.parse(_price.text.trim()),
            itemId: _itemId,
            imageUrl: imageUrl,
            section: _section.text.trim(),
            description: _description.text.trim(),
            portionSize: _portion.text.trim(),
            ingredients: _ingredients.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toSet()
                .toList());
      } else {
        await widget.menu.updateMenuItem(widget.uid, _itemId, _name.text.trim(),
            double.parse(_price.text.trim()),
            imageUrl: imageUrl,
            section: _section.text.trim(),
            description: _description.text.trim(),
            portionSize: _portion.text.trim(),
            ingredients: _ingredients.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toSet()
                .toList());
      }
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Could not save this dish. Your changes are still here. Please retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Form(
              key: _form,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      AppBackButton(
                          label: 'Cancel',
                          enabled: !_saving,
                          onPressed: () => Navigator.pop(context)),
                      Expanded(
                        child: Text(
                          widget.item == null ? 'Add dish' : 'Edit dish',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving…' : 'Done'),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (_image != null)
                      ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_image!,
                              height: 140, fit: BoxFit.cover))
                    else if (widget.item?.imageUrl.isNotEmpty == true)
                      Image.network(widget.item!.imageUrl,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.restaurant)),
                    TextButton.icon(
                        onPressed: _saving ? null : _pick,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Choose photo')),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _name,
                        enabled: !_saving,
                        maxLength: 80,
                        decoration:
                            const InputDecoration(labelText: 'Dish name'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a dish name.'
                                : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _section,
                        enabled: !_saving,
                        maxLength: 40,
                        decoration: const InputDecoration(
                            labelText: 'Menu section',
                            hintText: 'e.g. Drinks, Mains, Desserts'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a menu section.'
                                : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _price,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Price', prefixText: 'RM '),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          final price = double.tryParse(text);
                          if (price == null ||
                              !price.isFinite ||
                              price <= 0 ||
                              !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
                            return 'Enter a positive price with up to 2 decimal places.';
                          }
                          return null;
                        }),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _description,
                        enabled: !_saving,
                        maxLength: 500,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'What makes this dish special?')),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _portion,
                        enabled: !_saving,
                        maxLength: 80,
                        decoration: const InputDecoration(
                            labelText: 'Portion size',
                            hintText: 'e.g. 1 bowl, 6 pieces, serves 2')),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _ingredients,
                        enabled: !_saving,
                        maxLength: 500,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Ingredients',
                            hintText: 'Separate ingredients with commas')),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    if (_saving) const LinearProgressIndicator(),
                  ])),
        ),
      );
}
````

## File: lib/features/auth/screens/login_screen.dart
````dart
import '../../../core/widgets/app_back_button.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

Future<void> showLoginSheet(BuildContext context) {
  final media = MediaQuery.of(context);
  final useDialog = media.size.shortestSide >= 600;

  if (useDialog) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .32),
      builder: (dialogContext) {
        final dialogMedia = MediaQuery.of(dialogContext);
        final availableHeight = dialogMedia.size.height -
            dialogMedia.padding.vertical -
            dialogMedia.viewInsets.bottom -
            64;
        final dialogHeight = availableHeight.clamp(480.0, 660.0).toDouble();

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: 520,
            height: dialogHeight,
            child: const LoginScreen(embeddedInDialog: true),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .28),
    builder: (sheetContext) => AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .90,
        minChildSize: .55,
        maxChildSize: .96,
        snap: true,
        snapSizes: const [.55, .90],
        builder: (_, controller) => LoginScreen(
          embeddedInSheet: true,
          scrollController: controller,
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen(
      {super.key,
      this.embeddedInSheet = false,
      this.embeddedInDialog = false,
      this.scrollController})
      : assert(!(embeddedInSheet && embeddedInDialog));
  final bool embeddedInSheet;
  final bool embeddedInDialog;
  final ScrollController? scrollController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<User?>? _authSub;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null &&
          !user.isAnonymous &&
          mounted &&
          Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    final error =
        await _auth.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null) {
      _showError(error);
    }
  }

  Future<void> _google() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final error = await _auth.signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null && error != 'cancelled') {
      _showError(error);
    }
  }

  void _close() {
    if (!_busy) {
      Navigator.maybePop(context);
    }
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), backgroundColor: const Color(0xFFB3261E)));

  @override
  void dispose() {
    _authSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: const BorderSide(color: Color(0xFFB3261E))),
      );

  Widget _divider() => const Row(children: [
        Expanded(child: Divider(color: Color(0xFFE3E3E5))),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('OR',
                style: TextStyle(fontSize: 13, color: Color(0xFF77777E)))),
        Expanded(child: Divider(color: Color(0xFFE3E3E5))),
      ]);

  Widget _panel(BuildContext context) => Material(
        color: AppColors.background,
        borderRadius: widget.embeddedInDialog
            ? BorderRadius.circular(28)
            : widget.embeddedInSheet
                ? const BorderRadius.vertical(top: Radius.circular(28))
                : BorderRadius.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          if (widget.embeddedInSheet) ...[
            const SizedBox(height: 10),
            Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: const Color(0xFFD2D2D5),
                    borderRadius: BorderRadius.circular(3))),
          ],
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppBackButton(
                  label: 'Cancel', enabled: !_busy, onPressed: _close)),
          Expanded(
              child: SingleChildScrollView(
            controller: widget.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
                24,
                widget.embeddedInSheet ? 6 : 18,
                24,
                widget.embeddedInDialog
                    ? 24
                    : MediaQuery.paddingOf(context).bottom + 28),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                        child: Image.asset('assets/app_logo.png',
                            width: 54, height: 54)),
                    const SizedBox(height: 10),
                    const Text('Log in or sign up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.4)),
                    const SizedBox(height: 8),
                    const Text(
                        'Follow favourite stalls and receive live updates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Color(0xFF707078))),
                    const SizedBox(height: 28),
                    TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: _field('Email address'),
                        validator: (value) =>
                            value == null || !value.trim().contains('@')
                                ? 'Enter a valid email address.'
                                : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        decoration: _field('Password',
                            suffix: IconButton(
                                onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword),
                                icon: Icon(_hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined))),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password.'
                            : null),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: _busy
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ForgotPasswordScreen(
                                            initialEmail: _email.text.trim()))),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)))),
                    SizedBox(
                        height: 56,
                        child: FilledButton(
                            onPressed: _busy ? null : _login,
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28))),
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Continue',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)))),
                    const SizedBox(height: 22),
                    _divider(),
                    const SizedBox(height: 18),
                    SizedBox(
                        height: 56,
                        child: OutlinedButton(
                            onPressed: _busy ? null : _google,
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side:
                                    const BorderSide(color: Color(0xFFD5D5D8)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28))),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/google_logo.png',
                                      width: 21, height: 21),
                                  const SizedBox(width: 12),
                                  const Text('Continue with Google',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ]))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Color(0xFF707078))),
                      TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                          child: const Text('Sign up',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600))),
                    ]),
                  ],
                )),
          )),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInSheet || widget.embeddedInDialog) {
      return _panel(context);
    }
    return Scaffold(
        backgroundColor: Colors.white, body: SafeArea(child: _panel(context)));
  }
}
````

## File: lib/features/auth/auth_wrapper.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stallseeker/features/auth/screens/welcome_screen.dart';
import 'package:stallseeker/features/vendor/vendor_main_screen.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/core/services/notification_service.dart';
import 'package:stallseeker/core/services/auth_service.dart';
import 'screens/email_verification_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authStream = FirebaseAuth.instance.userChanges();
  bool _guestAccessGranted = false;

  void _grantGuestAccess() {
    if (!mounted) return;
    setState(() => _guestAccessGranted = true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: _authStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _AccountRecovery(
                message: 'Could not check your session. Please sign in again.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          if (user == null || (user.isAnonymous && !_guestAccessGranted)) {
            return WelcomeScreen(onGuestAccessGranted: _grantGuestAccess);
          }
          if (user.isAnonymous) {
            return const CustomerHomeScreen();
          }
          if (!user.emailVerified) {
            NotificationService.instance.setNavigationReady(false);
            return EmailVerificationScreen(key: ValueKey('verify-${user.uid}'));
          }
          return _AccountGate(key: ValueKey(user.uid), user: user);
        });
  }
}

class _AccountGate extends StatefulWidget {
  const _AccountGate({super.key, required this.user});
  final User user;
  @override
  State<_AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<_AccountGate> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _profile;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _profile = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots();
    unawaited(AuthService().repairCurrentUserProfile().catchError(
          (Object error) => debugPrint('Account profile repair failed: $error'),
        ));
  }

  @override
  void dispose() {
    NotificationService.instance.setNavigationReady(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data?.data()?['role'];
        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists ||
            (role != 'vendor' && role != 'customer')) {
          NotificationService.instance.setNavigationReady(false);
          return _AccountRecovery(
            message: snapshot.hasError
                ? 'Could not load your account. Check your connection and retry.'
                : 'Your account setup is incomplete. Retry, or sign out and contact support.',
            retry: () => setState(_listen),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            NotificationService.instance.setNavigationReady(true);
            unawaited(NotificationService.instance.configureForRole(role));
          }
        });
        return role == 'vendor'
            ? const VendorMainScreen()
            : const CustomerHomeScreen();
      },
    );
  }
}

class _AccountRecovery extends StatelessWidget {
  const _AccountRecovery({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
              child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Retry')),
          TextButton(
              onPressed: () async {
                try {
                  await AuthService().signOut();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Could not sign out. Please retry.')));
                  }
                }
              },
              child: const Text('Sign out')),
        ]),
      )));
}
````

## File: lib/features/customer/profile/customer_profile_screen.dart
````dart
import '../../shared/profile_page.dart';
import '../../shared/demo_orders_screen.dart';
import '../../shared/live_booking_section.dart';
import '../../shared/edit_profile_screen.dart';
import '../../shared/personal_information_screen.dart';
import '../../shared/change_password_screen.dart';
import '../../shared/notification_settings_screen.dart';
import '../../shared/legal_screen.dart';
import '../../shared/delete_account_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/faq_screen.dart';
import '../../shared/about_screen.dart';
import '../../shared/logout_helper.dart';
import '../../shared/manual_location_dialog.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.location,
    required this.onLocationChanged,
    this.onHomeLocation,
    this.onCustomLocation,
  });

  final LocationSelection? location;
  final void Function(LocationSelection selection, bool isManual)
      onLocationChanged;
  final VoidCallback? onHomeLocation;
  final VoidCallback? onCustomLocation;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _authService = AuthService();

  UserModel? _userModel;
  bool _isLoading = true;

  late String _locationText;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _locationText =
        widget.location?.label ?? 'Tap to set your preferred location';
    _loadUserData();
  }

  @override
  void didUpdateWidget(covariant CustomerProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLabel = widget.location?.label;
    if (!_isLoadingLocation &&
        newLabel != null &&
        newLabel != oldWidget.location?.label) {
      _locationText = newLabel;
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userData;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocation() async {
    if (!mounted || _isLoadingLocation) {
      return;
    }
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) {
        return;
      }
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services are turned off.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) {
        return;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission not granted.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));

      final coordinates = LatLng(position.latitude, position.longitude);
      String address;
      try {
        address = await describeLocation(coordinates);
      } catch (_) {
        address = 'Current location';
      }

      if (mounted) {
        widget.onLocationChanged(
          LocationSelection(coordinates: coordinates, label: address),
          false,
        );
        setState(() {
          _locationText = address;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _enterLocationManually() async {
    final selection = await showManualLocationDialog(
      context,
      initialLocation: widget.location?.coordinates,
      title: 'Set Your Location',
    );
    if (selection == null || !mounted) {
      return;
    }
    widget.onLocationChanged(selection, true);
    setState(() => _locationText = selection.label);
  }

  // Tapping "Current location" now offers a choice instead of jumping
  // straight to GPS, so a manual entry is always available -- not only
  // as a fallback once GPS has already failed.
  Future<void> _chooseLocation() async {
    if (_isLoadingLocation) {
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Set your location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.my_location_rounded, color: AppColors.primary),
            title: const Text('Use current location'),
            onTap: () => Navigator.pop(ctx, 'current'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_location_alt_outlined,
                color: AppColors.primary),
            title: const Text('Enter manually'),
            subtitle:
                const Text('Search for an area, city, state, or postcode'),
            onTap: () => Navigator.pop(ctx, 'manual'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    if (choice == 'current') {
      await _loadLocation();
    } else {
      await _enterLocationManually();
    }
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => EditProfileScreen(
                name: _userModel?.fullName ?? user?.displayName ?? '',
                email: _userModel?.email ?? user?.email ?? '',
                phoneNumber: _userModel?.phoneNumber,
                editPhone: true)));
    if (saved == true && mounted) {
      await _loadUserData();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    }
  }

  Future<void> _personalInformation() async {
    final user = FirebaseAuth.instance.currentUser;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PersonalInformationScreen(
                name: _userModel?.fullName ?? user?.displayName ?? '',
                email: _userModel?.email ?? user?.email ?? '',
                phoneNumber: _userModel?.phoneNumber,
                isVendor: false)));
    if (mounted) {
      await _loadUserData();
    }
  }

  void _changePassword() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChangePasswordScreen(
                email: _userModel?.email ??
                    FirebaseAuth.instance.currentUser?.email ??
                    '')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = FirebaseAuth.instance.currentUser;
    final guest = user?.isAnonymous ?? true;
    final name = guest
        ? 'Guest'
        : _userModel?.fullName.isNotEmpty == true
            ? _userModel!.fullName
            : user?.displayName ?? 'Your profile';
    return ProfilePage(
      name: name,
      email: guest ? '' : _userModel?.email ?? user?.email ?? '',
      photoUrl: guest ? null : user?.photoURL,
      isVendor: false,
      isGuest: guest,
      canChangePassword: user?.providerData
              .any((provider) => provider.providerId == 'password') ??
          false,
      location: _locationText,
      isLoadingLocation: _isLoadingLocation,
      onRefresh: _loadUserData,
      onLocation: _chooseLocation,
      onHomeLocation: widget.onHomeLocation,
      onCustomLocation: widget.onCustomLocation,
      onEdit: _editProfile,
      onPersonalInformation: _personalInformation,
      onOrders: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DemoOrdersScreen(isVendor: false))),
      bookingSection: guest ? null : const LiveBookingSection(isVendor: false),
      onPassword: _changePassword,
      onFaq: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: false))),
      onAbout: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onNotificationSettings: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen())),
      onPrivacyPolicy: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const LegalScreen(page: LegalPage.privacy))),
      onTerms: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const LegalScreen(page: LegalPage.terms))),
      onDeleteAccount: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen())),
    );
  }
}
````

## File: lib/core/services/auth_service.dart
````dart
// MANAGE ACCOUNT
// - signup, login, signin with google, signinasguest, getuserdata, save cust location, signout, resetpassword, req email verfiy, confir email verify, change password, update anem, delete account

import 'notification_service.dart';
import 'local_demo_booking_service.dart';
import 'vendor_location_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../constants/firestore_collections.dart';
import '../utils/vendor_phone.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // connect to firebase auth
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // connect to firestore db
  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance; // connect to google login
  static bool _googleSignInReady = false;

  Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) {
      return;
    }
    await _googleSignIn.initialize(
      serverClientId:
          '793011933510-ljrpbsf089fjdmjk58tfo7o1dmg1bmov.apps.googleusercontent.com',
    );
    _googleSignInReady = true;
  }

  // Stream of auth state changes (logged in / logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // repair current user profile
  Future<void> repairCurrentUserProfile() async {
    final user = _auth.currentUser;

    if (user == null || user.isAnonymous) {
      return;
    }

    final userRef =
        _firestore.collection(FirestoreCollections.users).doc(user.uid);

    final userSnapshot = await userRef.get();
    final existingData = userSnapshot.data();
    final existingRole = existingData?['role'];

    if (existingRole == 'customer' || existingRole == 'vendor') {
      return;
    }

    final vendorSnapshot = await _firestore
        .collection(FirestoreCollections.vendors)
        .doc(user.uid)
        .get();

    await userRef.set({
      'uid': user.uid,
      'email': user.email ?? '',
      'fullName': user.displayName ?? '',
      'role': vendorSnapshot.exists ? 'vendor' : 'customer',
      if (existingData?['createdAt'] == null)
        'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Register user with Email, Password, Name & Role
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? vendorPhone,
    String? customerPhone,
  }) async {
    try {
      final normalizedPhone =
          role == 'vendor' ? normalizeVendorPhone(vendorPhone ?? '') : null;
      if (role == 'vendor' && normalizedPhone == null) {
        return 'Enter a valid Malaysian business phone number.';
      }
      final customerPhoneInput = (customerPhone ?? '').trim();
      final normalizedCustomerPhone =
          role == 'customer' && customerPhoneInput.isNotEmpty
              ? normalizeVendorPhone(customerPhoneInput)
              : null;
      if (role == 'customer' &&
          customerPhoneInput.isNotEmpty &&
          normalizedCustomerPhone == null) {
        return 'Enter a valid Malaysian phone number.';
      }
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        UserModel newUser = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          fullName: fullName.trim(),
          phoneNumber: normalizedCustomerPhone,
          role: role,
          createdAt: DateTime.now(),
        );

        final batch = _firestore.batch();
        batch.set(
            _firestore
                .collection(FirestoreCollections.users)
                .doc(credential.user!.uid),
            newUser.toMap());
        if (role == 'vendor') {
          batch.set(
              _firestore
                  .collection(FirestoreCollections.vendors)
                  .doc(credential.user!.uid),
              {
                'vendorId': credential.user!.uid,
                'phoneNumber': normalizedPhone,
                'isOpen': false,
              });
        }
        await batch.commit();

        return null;
      }
      return "User creation failed.";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  // Login user with Email & Password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInReady();

      final GoogleSignInAccount googleUser = await _googleSignIn
          .authenticate()
          .timeout(const Duration(seconds: 25));

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(
              seconds:
                  25)); // cancel google sign in kalau lebih 25 sec  xbuat apa2
      final user = userCredential.user;

      if (user != null &&
          (userCredential.additionalUserInfo?.isNewUser ?? false)) {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? '',
          role: 'customer',
          createdAt: DateTime.now(),
        );
        await _firestore // save profile dalam firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .set(newUser.toMap());
      }

      return null;
    } on TimeoutException {
      return "Google sign-in timed out. Check your connection and try again, "
          "or sign in with email.";
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return "cancelled"; // user closed the picker without choosing
      }
      return e.description ?? "Google sign-in failed.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        return "An account already exists with this email. Log in with your email and password instead.";
      }
      return e.message ?? "Google sign-in failed.";
    } catch (e) {
      return e.toString();
    }
  }

// Guest mode
  Future<String?> signInAsGuest() async {
    try {
      await _auth.signInAnonymously();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Could not start guest session.";
    } catch (e) {
      return e.toString();
    }
  }

  // Fetch current user's data from Firestore                   //  read user id
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      return null;
    }
  }

// stores customer location
  Future<String?> saveCustomerLocation({
    required double latitude,
    required double longitude,
    required String label,
    required bool isManual,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return null;
    }
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set({
        'customerLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'label': label,
          'isManual': isManual,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      return null;
    } catch (_) {
      return 'Your location could not be saved.';
    }
  }

  // Sign Out
  // stop vendor location service
  Future<void> signOut() async {
    await VendorLocationService.instance.pause();
    try {
      await NotificationService.instance.clearCurrentDevice();
    } catch (_) {
      debugPrint('Notification cleanup could not finish.');
    }
    try {
      if (_googleSignInReady) {
        await _googleSignIn.signOut();
      }
    } finally {
      await _auth.signOut();
    }
  }

// reset password
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      // Give the same result for unknown accounts to avoid exposing sign-ups.
      if (e.code == 'user-not-found') {
        return null;
      }
      if (e.code == 'invalid-email') {
        return 'Enter a valid email address.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many requests. Please wait and try again.';
      }
      if (e.code == 'network-request-failed') {
        return 'Could not connect. Check your network and retry.';
      }
      return 'Could not send the reset link. Please try again.';
    } catch (_) {
      return 'Could not send the reset link. Please try again.';
    }
  }

// Ask Firebase Authentication to send its standard verification link.
  Future<String?> sendEmailVerificationLink() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) {
        return 'Sign in to verify your email.';
      }
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed?.emailVerified == true) return null;
      await refreshed!.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        return 'Too many emails were requested. Please wait and try again.';
      }
      if (e.code == 'network-request-failed') {
        return 'Could not connect. Check your network and try again.';
      }
      return e.message ?? 'Could not send the verification email.';
    } catch (_) {
      return 'Could not send the verification email. Please try again.';
    }
  }

// Refresh the user and signed email_verified token after the link is opened.
  Future<String?> refreshEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Your session ended. Please sign in again.';
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed?.emailVerified != true) {
        return 'The email is not verified yet. Open the link in your email first.';
      }
      await refreshed!.getIdToken(true);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not check your verification status.';
    } catch (_) {
      return 'Could not check your verification status. Please try again.';
    }
  }

  Future<String?> sendEmailChangeLink(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous) {
        return 'Sign in before changing your email.';
      }
      final email = newEmail.trim();
      if (email.toLowerCase() == (user.email ?? '').toLowerCase()) {
        return 'Enter a different email address.';
      }
      await user.verifyBeforeUpdateEmail(email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'For security, sign out and sign in again before changing your email.';
      }
      if (e.code == 'email-already-in-use') {
        return 'That email is already in use.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many emails were requested. Please wait and try again.';
      }
      return e.message ?? 'Could not send the email-change link.';
    } catch (_) {
      return 'Could not send the email-change link. Please try again.';
    }
  }

  Future<String?> refreshEmailChange(String expectedEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Your session ended. Please sign in again.';
      await user.reload();
      final refreshed = _auth.currentUser;
      if ((refreshed?.email ?? '').toLowerCase() !=
          expectedEmail.trim().toLowerCase()) {
        return 'The new email is not verified yet. Open the link in that email first.';
      }
      await refreshed!.getIdToken(true);
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(refreshed.uid)
          .set({
        'email': refreshed.email,
        'emailVerified': refreshed.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not check the new email.';
    } catch (_) {
      return 'Could not check the new email. Please try again.';
    }
  }

// change password
  Future<String?> changePassword(String newPassword,
      {String? currentPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return "No user is currently logged in.";
      }
      if (currentPassword != null) {
        if (user.email == null ||
            !user.providerData.any((p) => p.providerId == 'password')) {
          return 'Manage your password with your sign-in provider.';
        }
        final credential = EmailAuthProvider.credential(
            email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);
      }
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Your current password is incorrect. Please try again.';
      }
      if (e.code == 'too-many-requests') {
        return 'Too many attempts. Please wait and try again.';
      }
      if (e.code == 'network-request-failed') {
        return 'Could not connect. Check your network and retry.';
      }
      if (e.code == 'requires-recent-login') {
        return "For security, please log out and log back in before changing your password.";
      }
      return e.message ?? "Could not change password.";
    } catch (_) {
      return 'Could not update your password. Please try again.';
    }
  }

// update name
  Future<String?> updateFullName(
    String uid,
    String newName, {
    String? customerPhone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous || user.uid != uid) {
        return 'Please sign in to edit your profile.';
      }
      final name = newName.trim();
      if (name.isEmpty || name.length > 80) {
        return 'Enter a name between 1 and 80 characters.';
      }
      final updates = <String, dynamic>{'fullName': name};
      if (customerPhone != null) {
        final input = customerPhone.trim();
        final normalized =
            input.isEmpty ? null : normalizeVendorPhone(input);
        if (input.isNotEmpty && normalized == null) {
          return 'Enter a valid Malaysian phone number.';
        }
        updates['phoneNumber'] = normalized ?? FieldValue.delete();
      }
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .update(updates);
      // Firestore is the app's profile source. Sync Auth's display name as well.
      try {
        await user.updateDisplayName(name);
      } catch (_) {
        debugPrint('Profile saved; Auth display-name sync is unavailable.');
      }
      return null;
    } catch (_) {
      return 'Could not save your profile. Please try again.';
    }
  }

// delete account (bug)
  Future<String?> deleteAccount({String? currentPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return 'Sign in before deleting your account.';
    }
    try {
      final providers =
          user.providerData.map((provider) => provider.providerId).toSet();
      if (providers.contains('password')) {
        if (currentPassword == null ||
            currentPassword.isEmpty ||
            user.email == null) {
          return 'Enter your current password.';
        }
        await user.reauthenticateWithCredential(EmailAuthProvider.credential(
            email: user.email!, password: currentPassword));
      } else if (providers.contains('google.com')) {
        await _ensureGoogleSignInReady();
        final googleUser = await _googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        await user.reauthenticateWithCredential(
            GoogleAuthProvider.credential(idToken: googleAuth.idToken));
      } else {
        return 'Log out, sign in again, then retry account deletion.';
      }

      await NotificationService.instance.clearCurrentDevice();
      await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
      try {
        await LocalDemoBookingService().removeAccountData(user.uid);
      } catch (_) {
        debugPrint('Account deleted; local booking cleanup was unavailable.');
      }
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Your current password is incorrect.';
      }
      if (e.code == 'requires-recent-login') {
        return 'Log out, sign in again, then retry account deletion.';
      }
      return e.message ?? 'Could not verify your account.';
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') {
        return 'Your session expired. Sign in and try again.';
      }
      if (e.code == 'failed-precondition') {
        return 'Confirm your sign-in, then retry account deletion.';
      }
      return 'Could not finish account deletion. Please retry.';
    } catch (_) {
      return 'Could not delete your account. Please try again.';
    }
  }
}
````

## File: lib/features/vendor/dashboard/vendor_dashboard_screen.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/demo_order.dart';
import '../../../core/services/demo_order_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/vendor_location_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart';
import '../../shared/manual_location_dialog.dart';
import '../../shared/demo_orders_screen.dart';
import '../../shared/booking_detail_screen.dart';
import '../../customer/vendor_details/vendor_details_screen.dart';
import 'vendor_dashboard_view.dart';
import '../reviews/vendor_reviews_dashboard_card.dart';
import '../../../core/utils/vendor_phone.dart';
import 'vendor_demo_sales.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
  @override
  VendorDashboardScreenState createState() => VendorDashboardScreenState();
}

class VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final _vendorService = VendorService();
  final _orders = DemoOrderService();
  late Stream<List<DemoOrder>> _bookings;
  final _busyBookings = <String>{};
  Timer? _clock;
  final _location = VendorLocationService.instance;
  StreamSubscription<VendorModel?>? _subscription;
  VendorModel? _vendor;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listenBookings();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _location.addListener(_locationChanged);
    fetchVendorDetails();
  }

  void _locationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _location.removeListener(_locationChanged);
    _subscription?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  Future<void> fetchVendorDetails() async {
    await _subscription?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _subscription = _vendorService.watchVendorProfile(uid).listen((vendor) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vendor = vendor;
        _loading = false;
        _error = null;
      });
      if (vendor?.isOpen != true && _location.isSharing) {
        unawaited(_location.pause());
      }
    }, onError: (Object error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Could not load your stall. Check your connection and retry.';
        });
      }
    });
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on GPS before sharing your location.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('Allow location access in your phone settings.');
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Location permission is required.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 12));
  }

  Future<void> _toggle(bool open) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_saving || uid == null) {
      return;
    }
    if (open && (_vendor?.stallName.trim().isEmpty ?? true)) {
      _message('Set up your stall name before opening.');
      return;
    }
    if (open && normalizeVendorPhone(_vendor?.phoneNumber ?? '') == null) {
      _message('Add a business phone number in My stall before opening.');
      return;
    }
    if (open && (_vendor?.isTemporarilyClosed ?? false)) {
      _message('Remove the active temporary closure before opening.');
      return;
    }
    if (open) {
      final agreed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Open stall and share location?'),
                content: const Text(
                    'Your location continues updating while your stall is open, even when you lock your phone or use another app. Android shows a persistent notification while sharing is active.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Open stall')),
                ],
              ));
      if (agreed != true || !mounted) {
        return;
      }
    }
    setState(() => _saving = true);
    try {
      if (open) {
        double? latitude;
        double? longitude;
        var manualLocation = false;
        try {
          final position = await _position();
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (_) {
          if (!mounted) {
            return;
          }
          final existing = _vendor?.hasValidLocation == true
              ? LatLng(_vendor!.latitude, _vendor!.longitude)
              : null;
          final selection = await showManualLocationDialog(context,
              initialLocation: existing, title: 'Set Stall Location Manually');
          if (selection == null || !mounted) {
            return;
          }
          latitude = selection.coordinates.latitude;
          longitude = selection.coordinates.longitude;
          manualLocation = true;
        }
        if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
          return;
        }
        await _vendorService.updateVendorLocation(uid, latitude, longitude,
            sharingActive: !manualLocation);
        await _vendorService.toggleStallStatus(uid, true);
        if (!manualLocation && mounted) {
          await _location.start(uid);
        }
        if (manualLocation) {
          _message('Your stall is open using the manually entered location.');
        }
      } else {
        await _location.pause();
        await _vendorService.toggleStallStatus(uid, false);
      }
      if (!open) {
        _message('Your stall is closed.');
      }
      if (open && _location.isSharing) {
        _message('Your stall is open.');
      }
    } catch (_) {
      _message(
          'Could not update your stall. Check GPS, location permission, and connection, then retry.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _resume() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _position();
      if (mounted && FirebaseAuth.instance.currentUser?.uid == uid) {
        await _location.start(uid);
      }
    } catch (_) {
      _message('Could not share location. Check GPS and location permission.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleDemoSelfCollect(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) return;
    setState(() => _saving = true);
    try {
      await _vendorService.setSelfCollectEnabled(uid, enabled);
      _message(enabled
          ? 'Customers can now pay for self-collect bookings immediately.'
          : 'New self-collect bookings are off.');
    } catch (_) {
      _message('Could not save booking setting. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _listenBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _bookings = uid == null
        ? Stream.value(<DemoOrder>[])
        : _orders.watchVendorOrders(uid);
  }

  Future<void> _refresh() async {
    setState(_listenBookings);
    await fetchVendorDetails();
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _advanceBooking(DemoOrder booking) async {
    if (_busyBookings.contains(booking.id)) return;
    setState(() => _busyBookings.add(booking.id));
    try {
      await _orders.advance(booking.id, booking.effectiveStatus);
      _message(booking.effectiveStatus == 'preparing'
          ? 'Booking is ready for collection.'
          : 'Booking is now being prepared.');
    } catch (_) {
      _message('Could not update this booking. Please retry.');
    } finally {
      if (mounted) setState(() => _busyBookings.remove(booking.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _refresh, child: const Text('Retry')),
        ]),
      ));
    }
    return StreamBuilder<List<DemoOrder>>(
      stream: _bookings,
      builder: (context, snapshot) => VendorDashboardView(
        vendor: _vendor,
        reviewsCard: _vendor == null
            ? null
            : VendorReviewsDashboardCard(
                key: ValueKey(_vendor!.vendorId),
                vendorId: _vendor!.vendorId,
                stallName: _vendor!.stallName),
        bookings: snapshot.data ?? const [],
        bookingsLoading: !snapshot.hasData && !snapshot.hasError,
        bookingsError: snapshot.hasError,
        saving: _saving,
        locationSharing: _location.isSharing,
        locationError: _location.error,
        busyBookings: _busyBookings,
        onRefresh: _refresh,
        onToggleOpen: _toggle,
        onToggleSelfCollect: _toggleDemoSelfCollect,
        onResumeLocation: _resume,
        onPreview: () {
          if (_vendor != null) {
            _push(VendorDetailsScreen(vendor: _vendor!, previewOnly: true));
          }
        },
        onEditStall: () => _push(const EditStallScreen()),
        onMenu: () => _push(const VendorMenuScreen()),
        onStock: () => _push(const VendorMenuScreen(stockOnly: true)),
        onBookings: () => _push(const DemoOrdersScreen(isVendor: true)),
        onPaymentHistory: () => _push(const VendorPaymentHistoryScreen()),
        onOpenBooking: (booking) =>
            _push(BookingDetailScreen(bookingId: booking.id, isVendor: true)),
        onAdvanceBooking: _advanceBooking,
      ),
    );
  }
}
````

## File: lib/features/customer/vendor_details/vendor_details_screen.dart
````dart
import '../../shared/stall_review_card.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/stall_review.dart';
import '../../../core/models/dish_follow_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/stall_review_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/dish_follow_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';
import '../orders/demo_order_cart_screen.dart';

class VendorDetailsScreen extends StatefulWidget {
  final VendorModel vendor;
  final String? initialDishId;
  final bool previewOnly;
  // Freeze profile fields for the unsaved Edit stall preview.
  final bool draftPreview;
  final File? draftPhoto;

  const VendorDetailsScreen(
      {super.key,
      required this.vendor,
      this.initialDishId,
      this.previewOnly = false,
      this.draftPreview = false,
      this.draftPhoto})
      : assert(!draftPreview || previewOnly),
        assert(draftPhoto == null || draftPreview);

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  final _menuService = MenuService();
  final _followService = FollowService();
  final _dishFollows = DishFollowService();
  final _vendorService = VendorService();
  final _reviews = StallReviewService();

  // Local copy of the vendor, refreshable independently of the
  // instance passed in -- the one passed in is a snapshot from
  // whenever the customer tapped the marker/card, and doesn't update
  // on its own if the vendor changes their status while this screen
  // is open.
  late VendorModel _vendor;
  bool _isRefreshing = false;
  String? _vendorError;
  bool _vendorDeleted = false;
  bool _isFollowSaving = false;
  StreamSubscription<VendorModel?>? _vendorSub;
  Timer? _freshnessTimer;
  late Stream<List<MenuItemModel>> _menuStream;
  late Stream<List<StallReview>> _reviewStream;
  final _dishSearch = TextEditingController();
  String _dishQuery = '';
  String? _focusedDishId;
  final _selectedDishKey = GlobalKey();
  bool _revealedSelectedDish = false;
  final _followedDishIds = <String>{};
  final _savingDishes = <String>{};
  StreamSubscription<List<DishFollowModel>>? _dishFollowSub;
  StreamSubscription<User?>? _dishAuthSub;
  bool _dishFollowLoading = true;
  bool _dishFollowError = false;
  bool _customerAccount = false;

  // Local follow state, kept in sync with Firestore via a listener but
  // updated OPTIMISTICALLY (immediately, before the write completes)
  // when the user taps the heart -- this is what makes the icon flip
  // instantly instead of waiting on a round-trip.
  bool _isFollowing = false;
  StreamSubscription<bool>? _followSub;

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
    _focusedDishId = widget.initialDishId;
    _menuStream = _menuService.getMenuItems(_vendor.vendorId);
    _reviewStream = _reviews.watchReviews(_vendor.vendorId);
    if (!widget.draftPreview) {
      _vendorSub = _vendorService.watchVendorProfile(_vendor.vendorId).listen(
        (vendor) {
          if (!mounted) {
            return;
          }
          setState(() {
            _vendorDeleted = vendor == null;
            if (vendor != null) {
              _vendor = vendor;
            }
            _vendorError = null;
          });
        },
        onError: (Object error) {
          if (mounted) {
            setState(() => _vendorError =
                'Could not update this stall. Showing last known details.');
          }
        },
      );
      _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    final customerId = user?.uid;
    if (!widget.previewOnly &&
        customerId != null &&
        user?.isAnonymous == false) {
      _followSub = _followService
          .isFollowing(customerId, _vendor.vendorId)
          .listen((value) {
        if (mounted) {
          setState(() => _isFollowing = value);
        }
      });
    }
    if (!widget.previewOnly) {
      _dishAuthSub = FirebaseAuth.instance.userChanges().listen((_) {
        unawaited(_listenDishFollows());
      });
    } else {
      _dishFollowLoading = false;
    }
  }

  @override
  void dispose() {
    _followSub?.cancel();
    _dishFollowSub?.cancel();
    _dishAuthSub?.cancel();
    _vendorSub?.cancel();
    _freshnessTimer?.cancel();
    _dishSearch.dispose();
    super.dispose();
  }

  Future<void> _refreshVendor() async {
    if (widget.draftPreview) return;
    setState(() => _isRefreshing = true);
    final updated = await _vendorService.getVendorProfile(_vendor.vendorId);
    if (mounted) {
      setState(() {
        if (updated != null) {
          _vendor = updated;
        }
        _isRefreshing = false;
      });
    }
  }

  Future<void> _listenDishFollows() async {
    await _dishFollowSub?.cancel();
    _dishFollowSub = null;
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _followedDishIds.clear();
        _customerAccount = false;
        _dishFollowError = false;
        _dishFollowLoading = false;
      });
    }
    if (user == null || user.isAnonymous || !user.emailVerified) {
      return;
    }
    if (mounted) {
      setState(() {
        _dishFollowLoading = true;
        _dishFollowError = false;
      });
    }
    try {
      final profile = await AuthService()
          .getUserData(user.uid)
          .timeout(const Duration(seconds: 10));
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }
      if (profile?.role != 'customer') {
        setState(() {
          _dishFollowLoading = false;
          _dishFollowError = profile == null;
        });
        return;
      }
      _customerAccount = true;
      _dishFollowSub = _dishFollows
          .watch(user.uid, vendorId: _vendor.vendorId)
          .listen((follows) {
        if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
          return;
        }
        setState(() {
          _followedDishIds
            ..clear()
            ..addAll(follows.map((follow) => follow.itemId));
          _dishFollowLoading = false;
          _dishFollowError = false;
        });
      }, onError: (Object error) {
        if (mounted) {
          setState(() {
            _dishFollowLoading = false;
            _dishFollowError = true;
          });
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _dishFollowLoading = false;
          _dishFollowError = true;
        });
      }
    }
  }

  Future<void> _toggleDishFollow(MenuItemModel item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _showLoginRequiredDialog(context, action: 'Following dishes');
      return;
    }
    if (!user.emailVerified || !_customerAccount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!user.emailVerified
              ? 'Verify your email before following dishes.'
              : 'Only customer accounts can follow dishes.')));
      return;
    }
    if (_savingDishes.contains(item.itemId) ||
        _dishFollowLoading ||
        _dishFollowError) {
      return;
    }
    final following = _followedDishIds.contains(item.itemId);
    setState(() => _savingDishes.add(item.itemId));
    try {
      if (following) {
        await _dishFollows.unfollow(user.uid, _vendor.vendorId, item.itemId);
      } else {
        await _dishFollows.follow(user.uid, _vendor.vendorId, item.itemId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(following
                ? 'Dish unfollowed.'
                : 'Following ${item.name}. We’ll alert you when it is restocked.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not update dish following. Please retry.')));
      }
    } finally {
      if (mounted) {
        setState(() => _savingDishes.remove(item.itemId));
      }
    }
  }

  Future<void> _toggleFollow(String customerId) async {
    if (_isFollowSaving) {
      return;
    }
    _isFollowSaving = true;
    final wasFollowing = _isFollowing;
    // Flip immediately -- don't wait for Firestore to confirm. If the
    // write fails for some reason, it gets reverted in the catch below.
    setState(() => _isFollowing = !wasFollowing);

    try {
      if (wasFollowing) {
        await _followService.unfollowVendor(customerId, _vendor.vendorId);
      } else {
        await _followService.followVendor(customerId, _vendor.vendorId);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFollowing = wasFollowing);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not update following. Please retry.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowSaving = false);
      }
    }
  }

  Future<void> _openNavigation() async {
    final coordinates = '${_vendor.latitude},${_vendor.longitude}';
    final isApplePlatform = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final googleMapsUri = isApplePlatform
        ? Uri.parse(
            'comgooglemaps://?daddr=$coordinates&directionsmode=driving')
        : Uri.parse('google.navigation:q=$coordinates&mode=d');
    final wazeUri = Uri.parse('waze://?ll=$coordinates&navigate=yes');
    final browserUri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {'api': '1', 'destination': coordinates},
    );
    var googleMapsAvailable = false;
    var wazeAvailable = false;
    if (!kIsWeb) {
      try {
        googleMapsAvailable = await canLaunchUrl(googleMapsUri);
        wazeAvailable = await canLaunchUrl(wazeUri);
      } catch (_) {
        // The browser fallback remains available when app detection fails.
      }
    }
    if (!mounted) {
      return;
    }

    Future<void> launchNavigation(Uri uri) async {
      Navigator.pop(context);
      var launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open that navigation app.')));
      }
    }

    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  title: const Text('Choose navigation app'),
                  subtitle: Text(_vendor.stallName.isEmpty
                      ? 'Stall location'
                      : _vendor.stallName)),
              if (googleMapsAvailable)
                ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('Google Maps'),
                    onTap: () => launchNavigation(googleMapsUri)),
              if (wazeAvailable)
                ListTile(
                    leading: const Icon(Icons.navigation_outlined),
                    title: const Text('Waze'),
                    onTap: () => launchNavigation(wazeUri)),
              ListTile(
                  leading: const Icon(Icons.open_in_browser),
                  title: const Text('Google Maps in browser'),
                  onTap: () => launchNavigation(browserUri)),
              if (!googleMapsAvailable && !wazeAvailable)
                const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                        'Google Maps and Waze were not detected. Browser directions are still available.',
                        style: TextStyle(color: Colors.grey))),
            ])));
  }

  void _showLoginRequiredDialog(BuildContext context,
      {String action = 'Following vendors'}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create an Account'),
        content: Text(
          '$action requires an account. Log in or register to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF15803D);
      case 'low_stock':
        return const Color(0xFF92400E);
      case 'out_of_stock':
        return const Color(0xFFB42318);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'low_stock':
        return 'Low Stock';
      case 'out_of_stock':
        return 'Sold out';
      default:
        return status;
    }
  }

  Future<void> _editReview(StallReview? existing) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _showLoginRequiredDialog(context, action: 'Writing reviews');
      return;
    }
    final profile = await AuthService().getUserData(user.uid);
    if (!mounted) return;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _ReviewEditor(
            vendorId: _vendor.vendorId,
            customerId: user.uid,
            customerName: profile?.fullName ?? user.displayName ?? 'Customer',
            existing: existing));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final customerId = currentUser?.uid;
    final isGuest = currentUser?.isAnonymous ?? true;
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppPageAppBar(
        title: Text(widget.previewOnly ? 'Stall preview' : 'Stall details'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (!widget.draftPreview)
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh stall status',
              onPressed: _isRefreshing ? null : _refreshVendor,
            ),
          if (!widget.previewOnly && customerId != null)
            isGuest
                ? IconButton(
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Follow',
                    onPressed: () => _showLoginRequiredDialog(context),
                  )
                : IconButton(
                    icon: Icon(
                      _isFollowing ? Icons.favorite : Icons.favorite_border,
                      color: _isFollowing ? Colors.red : null,
                    ),
                    tooltip: _isFollowing ? 'Unfollow' : 'Follow',
                    onPressed: _isFollowSaving || _vendorDeleted
                        ? null
                        : () => _toggleFollow(customerId),
                  ),
        ],
      ),
      // On tablet: buttons sit neatly in the left sidebar. On phone: sticky bottom bar.
      bottomNavigationBar: isTablet || widget.previewOnly
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: _buildActionButtons(isGuest: isGuest),
            ),
      body: isTablet
          ? _buildTabletLayout(context, isGuest: isGuest)
          : _buildMobileLayout(context),
    );
  }

  // ---------------------------------------------------------------------------
  // Responsive Layouts (Mobile vs Tablet)
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        ..._buildStallInfoWidgets(isTablet: false),
        const SizedBox(height: 26),
        ..._buildMenuAndReviewWidgets(),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, {required bool isGuest}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Stall Identity & Info & Actions
        SizedBox(
          width: 380,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 24),
            children: [
              ..._buildStallInfoWidgets(isTablet: true),
              const SizedBox(height: 20),
              if (!widget.previewOnly) _buildActionButtons(isGuest: isGuest),
            ],
          ),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: Color(0xFFE9ECF0),
        ),
        // Right Column: Menu & Reviews
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: _buildMenuAndReviewWidgets(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Component Blocks
  // ---------------------------------------------------------------------------

  Widget _buildStallPhoto({double height = 210}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: widget.draftPhoto != null
            ? Image.file(widget.draftPhoto!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _photoPlaceholder())
            : _vendor.imageUrl.isNotEmpty
            ? Image.network(
                _vendor.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _photoPlaceholder(),
              )
            : _photoPlaceholder(),
      ),
    );
  }

  List<Widget> _buildStallInfoWidgets({required bool isTablet}) {
    return [
      if (widget.draftPreview)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Preview of your changes. Save changes to publish.',
              style: TextStyle(color: AppColors.primary, fontSize: 13)),
        ),
      if (_vendorDeleted || _vendorError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _vendorDeleted
                ? 'This stall is no longer available.'
                : _vendorError!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      _buildStallPhoto(height: isTablet ? 220 : 200),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _badge(
            _vendor.isOpenNow ? 'Open now' : 'Closed',
            _vendor.isOpenNow
                ? const Color(0xFF15803D)
                : const Color(0xFFB42318),
            Icons.circle,
          ),
          if (_vendor.categoryLabel.isNotEmpty)
            _badge(_vendor.categoryLabel, const Color(0xFF64748B),
                Icons.restaurant_outlined),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        _vendor.stallName.isEmpty ? 'Unnamed stall' : _vendor.stallName,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: Color(0xFF17202D),
        ),
      ),
      if (_vendor.description.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          _vendor.description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF64748B),
          ),
        ),
      ],
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            _info(
              Icons.schedule_rounded,
              'Opening hours',
              _vendor.hoursToday.isEmpty
                  ? 'Not provided by this vendor'
                  : _vendor.hoursToday,
            ),
            if (_vendor.isTemporarilyClosed) ...[
              const Divider(height: 24, indent: 36),
              _info(
                Icons.event_busy_outlined,
                'Temporary closure',
                'This stall is temporarily closed.',
              ),
            ],
            if (_vendor.phoneNumber.isNotEmpty) ...[
              const Divider(height: 24, indent: 36),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.call_outlined, color: Color(0xFF64748B)),
                title: const Text('Vendor phone'),
                subtitle: Text(_vendor.phoneNumber),
                trailing: const Icon(Icons.call),
                onTap: () =>
                    launchUrl(Uri(scheme: 'tel', path: _vendor.phoneNumber)),
              ),
            ],
            const Divider(height: 24, indent: 36),
            _info(
              Icons.location_on_outlined,
              _vendor.hasFreshLocation
                  ? 'Location updated recently'
                  : 'Last known location',
              _vendor.hasFreshLocation
                  ? 'The vendor is sharing their location.'
                  : 'This location may be outdated. Check before travelling.',
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildActionButtons({required bool isGuest}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_vendorDeleted &&
            _vendor.selfCollectEnabled &&
            _vendor.isOpenNow &&
            _vendor.hasValidLocation) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isGuest
                  ? () => _showLoginRequiredDialog(context,
                      action: 'self-collect bookings')
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              DemoOrderCartScreen(vendor: _vendor))),
              icon: const Icon(Icons.shopping_bag_outlined),
              label:
                  Text(isGuest ? 'Sign in to book' : 'Book for self-collect'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: !_vendorDeleted && _vendor.hasValidLocation
                ? _openNavigation
                : null,
            icon: const Icon(Icons.directions),
            label: const Text('Get directions'),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMenuAndReviewWidgets() {
    return [
      const Text(
        'On the menu',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF17202D),
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Availability is updated by the vendor',
        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      const SizedBox(height: 4),
      const Text(
        'Follow a dish to hear when it is back in stock.',
        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      if (_dishFollowError)
        Row(children: [
          const Expanded(child: Text('Could not load dish following.')),
          TextButton(
            onPressed: _listenDishFollows,
            child: const Text('Retry'),
          ),
        ]),
      if (_focusedDishId != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            const Expanded(child: Text('Showing the selected dish')),
            TextButton(
              onPressed: () => setState(() => _focusedDishId = null),
              child: const Text('Show all dishes'),
            ),
          ]),
        ),
      const SizedBox(height: 14),
      TextField(
        key: const ValueKey('stall-menu-search'),
        controller: _dishSearch,
        onChanged: (value) => setState(() {
          _focusedDishId = null;
          _dishQuery = value.trim().toLowerCase();
        }),
        decoration: InputDecoration(
          hintText: 'Search dishes',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _dishQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear dish search',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _dishSearch.clear();
                    setState(() => _dishQuery = '');
                  },
                ),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 14),
      StreamBuilder<List<MenuItemModel>>(
        // Preserve the live snapshot when selected-dish or error rows change.
        key: const ValueKey('stall-menu-stream'),
        stream: _menuStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('Could not load the menu.'),
                TextButton(
                  onPressed: () => setState(() => _menuStream =
                      _menuService.getMenuItems(_vendor.vendorId)),
                  child: const Text('Retry'),
                ),
              ]),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('The vendor has not added a menu yet.'),
            );
          }
          final filtered = items
              .where((item) =>
                  (_focusedDishId == null || item.itemId == _focusedDishId) &&
                  item.name.toLowerCase().contains(_dishQuery))
              .toList();
          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_focusedDishId != null
                  ? 'This dish is no longer on the menu.'
                  : 'No dishes match your search.'),
            );
          }
          final sections = <String, List<MenuItemModel>>{};
          if (_focusedDishId != null && !_revealedSelectedDish) {
            _revealedSelectedDish = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final target = _selectedDishKey.currentContext;
              if (mounted && target != null) {
                Scrollable.ensureVisible(target,
                    duration: const Duration(milliseconds: 300), alignment: .1);
              }
            });
          }
          for (final item in filtered) {
            sections.putIfAbsent(item.section, () => []).add(item);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in sections.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(
                          child: Text(entry.key,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700))),
                      Text('${entry.value.length}',
                          style: const TextStyle(color: AppColors.primary)),
                    ]),
                  ),
                ),
                ...entry.value.map((item) => KeyedSubtree(
                    key:
                        item.itemId == _focusedDishId ? _selectedDishKey : null,
                    child: _menuCard(item))),
              ],
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      StreamBuilder<List<StallReview>>(
        key: const ValueKey('stall-reviews-stream'),
        stream: _reviewStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Could not load reviews.');
          }
          final reviews = snapshot.data ?? [];
          final uid = FirebaseAuth.instance.currentUser?.uid;
          StallReview? mine;
          for (final review in reviews) {
            if (review.customerId == uid) {
              mine = review;
              break;
            }
          }
          final average = reviews.isEmpty
              ? 0.0
              : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
                  reviews.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    'Reviews (${reviews.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (reviews.isNotEmpty)
                  Text(
                    '${average.toStringAsFixed(1)} ★',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
              ]),
              const SizedBox(height: 8),
              if (!widget.previewOnly)
                OutlinedButton.icon(
                  onPressed: () => _editReview(mine),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(
                      mine == null ? 'Write a review' : 'Edit your review'),
                ),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No reviews yet.'),
                ),
              for (final review in reviews) _reviewCard(review),
            ],
          );
        },
      ),
    ];
  }

  Widget _photoPlaceholder() => Container(
      color: AppColors.mint,
      alignment: Alignment.center,
      child: const Icon(Icons.storefront_rounded,
          size: 60, color: AppColors.primary));

  Widget _badge(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color))),
        ]),
      );

  Widget _info(IconData icon, String title, String detail) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF64748B), size: 21),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF17202D))),
          const SizedBox(height: 4),
          Text(detail,
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
        ])),
      ]);

  Widget _menuCard(MenuItemModel item) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                  width: 68,
                  height: 68,
                  child: item.imageUrl.isEmpty
                      ? _photoPlaceholder()
                      : Image.network(item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder()))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17202D))),
                const SizedBox(height: 4),
                Text('RM ${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                const SizedBox(height: 8),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(item.description,
                      style: const TextStyle(color: AppColors.textMuted)),
                ],
                if (item.portionSize.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Portion: ${item.portionSize}'),
                ],
                if (item.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Ingredients: ${item.ingredients.join(', ')}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
                const SizedBox(height: 8),
                _badge(_statusLabel(item.status), _statusColor(item.status),
                    Icons.circle),
                if (item.statusUpdatedAt != null) ...[
                  const SizedBox(height: 5),
                  Text(
                      'Stock updated ${_formatStockTime(item.statusUpdatedAt!)}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B))),
                ],
                const SizedBox(height: 6),
                if (!widget.previewOnly)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft),
                    onPressed: _vendorDeleted ||
                            _savingDishes.contains(item.itemId) ||
                            _dishFollowLoading ||
                            _dishFollowError
                        ? null
                        : () => _toggleDishFollow(item),
                    icon: _savingDishes.contains(item.itemId)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(
                            _followedDishIds.contains(item.itemId)
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_none_outlined,
                            size: 18),
                    label: Text(_followedDishIds.contains(item.itemId)
                        ? 'Following dish'
                        : 'Follow dish'),
                  ),
              ])),
        ]),
      );

  String _formatStockTime(DateTime value) {
    final my = value.toUtc().add(const Duration(hours: 8));
    final hour = my.hour % 12 == 0 ? 12 : my.hour % 12;
    final minute = my.minute.toString().padLeft(2, '0');
    return '${my.day}/${my.month}/${my.year} $hour:$minute ${my.hour < 12 ? 'AM' : 'PM'}';
  }

  Future<void> _deleteReview(StallReview review) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        user.isAnonymous ||
        user.uid != review.customerId ||
        !_customerAccount ||
        widget.previewOnly) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your review?'),
        content: const Text(
          'Your rating, review, photos, and any stall owner reply will be removed from this stall.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete review'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _reviews.deleteReview(_vendor.vendorId, review.customerId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review deleted.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete your review. Please retry.'),
          ),
        );
      }
    }
  }

  Widget _reviewCard(StallReview review) {
    final canEdit = !widget.previewOnly &&
        _customerAccount &&
        FirebaseAuth.instance.currentUser?.uid == review.customerId;
    return StallReviewCard(
      review: review,
      stallName: _vendor.stallName,
      onEditReview: canEdit ? () => _editReview(review) : null,
      onDeleteReview: canEdit ? () => _deleteReview(review) : null,
    );
  }
}

class _ReviewEditor extends StatefulWidget {
  const _ReviewEditor(
      {required this.vendorId,
      required this.customerId,
      required this.customerName,
      required this.existing});
  final String vendorId;
  final String customerId;
  final String customerName;
  final StallReview? existing;
  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  final _storage = StorageService();
  final _service = StallReviewService();
  final _text = TextEditingController();
  final _photos = <File>[];
  final _existingUrls = <String>[];
  int _rating = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _text.text = widget.existing?.text ?? '';
    _existingUrls.addAll(widget.existing?.photoUrls ?? []);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final remaining = 5 - _existingUrls.length - _photos.length;
    if (remaining <= 0) {
      return;
    }
    final picked = await _storage.pickReviewImages(remaining);
    if (mounted) setState(() => _photos.addAll(picked));
  }

  Future<void> _save() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Choose a star rating.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final urls = [..._existingUrls];
      for (var i = 0; i < _photos.length; i++) {
        urls.add(await _storage.uploadReviewImage(
            widget.vendorId,
            widget.customerId,
            '${DateTime.now().microsecondsSinceEpoch}_$i',
            _photos[i]));
      }
      await _service.saveReview(widget.vendorId, widget.customerId,
          widget.customerName, _rating, _text.text, urls,
          customerAvatarUrl: FirebaseAuth.instance.currentUser?.photoURL ?? '');
      final removed = (widget.existing?.photoUrls ?? <String>[])
          .where((url) => !urls.contains(url));
      for (final url in removed) {
        try {
          await _storage.deleteReviewImageUrl(
              widget.vendorId, widget.customerId, url);
        } catch (_) {
          // The review was saved; account deletion also cleans up old photos.
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save your review. Please retry.')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
                widget.existing == null
                    ? 'Review this stall'
                    : 'Edit your review',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                    tooltip: '$star stars',
                    onPressed:
                        _saving ? null : () => setState(() => _rating = star),
                    icon: Icon(star <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber))
            ]),
            TextField(
                controller: _text,
                maxLength: 1000,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Your experience (optional)',
                    border: OutlineInputBorder())),
            Text('Photos (${_existingUrls.length + _photos.length}/5)'),
            Wrap(spacing: 8, children: [
              for (var i = 0; i < _existingUrls.length; i++)
                InputChip(
                    label: Text('Photo ${i + 1}'),
                    onDeleted: _saving
                        ? null
                        : () => setState(() => _existingUrls.removeAt(i))),
              for (var i = 0; i < _photos.length; i++)
                InputChip(
                    label: Text('New photo ${i + 1}'),
                    onDeleted: _saving
                        ? null
                        : () => setState(() => _photos.removeAt(i))),
            ]),
            TextButton.icon(
                onPressed: _saving ? null : _addPhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add photos')),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save review')),
          ])));
}
````

## File: lib/features/customer/home/customer_home_screen.dart
````dart
import '../../../core/widgets/app_sheet_header.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import 'discovery_options.dart';
import '../../../core/services/stall_review_service.dart';
import '../../../core/services/saved_search_service.dart';
import '../../../core/services/notification_history_service.dart';
import '../../../core/services/demo_order_service.dart';
import '../notifications/customer_notifications_screen.dart';
import 'dart:async'; // bawak time, future dan unawaited
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_pill_navigation.dart';
import '../../../core/widgets/ios_grouped.dart';
import '../../../core/constants/stall_categories.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/models/dish_search_entry.dart';
import 'open_at_picker.dart';
import 'discovery_search_filters.dart';
import 'price_range_picker.dart';
import 'discovery_map_widgets.dart';
import 'stall_map_marker.dart';
import 'stall_preview_sheet.dart';
import '../../../core/services/follow_service.dart';
import '../orders/demo_order_cart_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/dish_search_service.dart';
import '../../../core/services/search_history_service.dart';
import '../../../core/services/vendor_service.dart';
import '../following/customer_following_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../../shared/profile_page.dart';
import '../vendor_details/vendor_details_screen.dart';
import '../../shared/manual_location_dialog.dart';
import '../../shared/saved_locations_sheet.dart';
import '../../shared/pin_location_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _vendorService = VendorService(); // loads vendor
  final _authService = AuthService(); // loads customer info
  final _dishSearchService = DishSearchService();
  final _searchHistoryService = SearchHistoryService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Stream<int>? _unreadCount;
  Stream<int>? _bookingUnreadCount;

  int _selectedIndex = 0;
  String _searchQuery = '';
  GoogleMapController? _mapController; // move the map dan zoom
  LatLng? _customerPosition;
  String? _customerLocationLabel;
  double _searchRadiusKm = 5;

  // NEW: Track the visible map area to filter vendors
  LatLngBounds? _visibleBounds;
  LatLngBounds? _pendingBounds;
  LatLng? _mapCenter;
  CameraPosition? _lastCameraPosition;
  final ValueNotifier<double> _mapBearing = ValueNotifier(0);
  LatLng? _searchCenter;
  bool _showSearchArea = false;
  bool _programmaticCameraMove = false;
  Timer? _cameraMoveGuard;
  bool _cameraMovedByUser = false;
  int _boundsRequest = 0;
  DiscoverySort _sort = DiscoverySort.distance;
  bool _listOnly = false;
  bool _availableOnly = false;
  bool _selfCollectOnly = false;
  bool _recentOnly = false;
  final _reviewService = StallReviewService();
  final _savedSearches = SavedSearchService();
  final _ratings = <String, StallRatingSummary>{};
  final _ratingErrors = <String>{};
  final _ratingSubscriptions = <String, StreamSubscription<dynamic>>{};
  static const _clusterId = ClusterManagerId('nearby-stalls');
  OpeningTimeFilter? _openingTime;
  MenuPriceRange? _priceRange;

  final List<String> _tabTitles = [
    'Home',
    'Following',
    'Notifications',
    'Settings'
  ];
  String _greeting = 'Guest';

  static const _mapStyle = '''[
    {"featureType":"all","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f7f2e3"}]},
    {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#d9efd9"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#cce9d0"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ebe9df"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#d9d9ce"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#bfdfe7"}]},
    {"featureType":"transit","elementType":"geometry","stylers":[{"visibility":"off"}]}
  ]''';

  String get _welcomeLine {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$salutation, $_greeting 👋';
  }

  String? _selectedVendorId;
  bool _isLocatingCustomer = true;
  bool _locationPermissionGranted = false;
  String? _locationError;
  String? _category;
  String _statusFilter = 'All';
  Timer? _freshnessTimer;
  late Stream<List<VendorModel>> _vendors;
  StreamSubscription<List<DishSearchEntry>>? _dishSubscription;
  List<DishSearchEntry> _allDishes = const [];
  List<String> _recentSearches = const [];
  bool _dishesLoading = true;
  String? _dishSearchError;
  final _markerCache = StallMapMarkerCache();
  final _markerIcons = <(String, bool), BitmapDescriptor>{};
  final _followService = FollowService();
  final _previewExtent = ValueNotifier<double>(.55);
  String? _previewVendorId;
  String? _selectedDishId;
  CameraPosition? _previewCamera;
  Stream<bool>? _previewFollowStream;
  bool _followingBusy = false;
  bool _searchBoundsActive = false;
  int _cameraRequest = 0;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

// cari vendor data, tgk notification, loads customer location, name for greeting
  @override
  void initState() {
    super.initState();
    _vendors = _watchVendors();
    unawaited(_loadMapMarkerIcons());
    _searchFocus.addListener(_onSearchFocusChanged);
    _dishSubscription = _dishSearchService.watchAllDishes().listen(
      (dishes) {
        if (!mounted) return;
        setState(() {
          _allDishes = dishes;
          _dishesLoading = false;
          _dishSearchError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _dishesLoading = false;
          _dishSearchError = 'Could not load dishes.';
        });
      },
    );
    unawaited(_loadRecentSearches());
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      _unreadCount = NotificationHistoryService().watchUnreadCount(user.uid);
      _bookingUnreadCount =
          DemoOrderService().watchUnseenCount(user.uid, isVendor: false);
    }
    _initializeCustomerLocation();
    _loadGreeting();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // refresh location setiap 30sec
      if (mounted) {
        setState(() {});
      }
    });
  }

// bila customer leave app dia clean up
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    _dishSubscription?.cancel();
    for (final subscription in _ratingSubscriptions.values) {
      subscription.cancel();
    }
    _mapController?.dispose();
    _mapBearing.dispose();
    _previewExtent.dispose();
    _freshnessTimer?.cancel();
    _cameraMoveGuard?.cancel();
    super.dispose();
  }

  void _expectProgrammaticCameraMove() {
    _programmaticCameraMove = true;
    _cameraMoveGuard?.cancel();
    _cameraMoveGuard = Timer(const Duration(seconds: 3), () {
      _programmaticCameraMove = false;
    });
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentSearches() async {
    try {
      await _searchHistoryService.mergeGuestHistoryIntoCustomerAccount();
      final recent = await _searchHistoryService.loadRecent();
      if (mounted) setState(() => _recentSearches = recent);
    } catch (_) {
      // Search still works when history is unavailable.
    }
  }

  void _submitSearch(String rawQuery) {
    final query = rawQuery.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.isEmpty) return;
    _searchController.text = query;
    _searchController.selection = TextSelection.collapsed(offset: query.length);
    setState(() {
      _searchQuery = query;
      _selectedVendorId = null;
      _recentSearches = [
        query,
        ..._recentSearches
            .where((item) => item.toLowerCase() != query.toLowerCase()),
      ].take(10).toList();
    });
    _searchFocus.unfocus();
    unawaited(_searchHistoryService.save(query).catchError((Object error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Search worked, but history could not be saved.')));
      }
    }));
  }

  Future<void> _removeRecentSearch(String query) async {
    setState(() => _recentSearches = _recentSearches
        .where((item) => item.toLowerCase() != query.toLowerCase())
        .toList());
    try {
      await _searchHistoryService.remove(query);
    } catch (_) {
      if (mounted) await _loadRecentSearches();
    }
  }

  Future<void> _clearRecentSearches() async {
    setState(() => _recentSearches = const []);
    try {
      await _searchHistoryService.clear();
    } catch (_) {
      if (mounted) await _loadRecentSearches();
    }
  }

  Future<void> _loadGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    if (user.isAnonymous) {
      if (mounted) {
        setState(() => _greeting = 'Guest');
      }
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final name = userData?.fullName;
    if (mounted) {
      setState(() {
        _greeting = (name != null && name.trim().isNotEmpty)
            ? name.trim().split(RegExp(r'\s+')).first
            : 'Guest';
      });
    }
  }

  bool _locationRequestActive = false;
  int _locationSelectionVersion = 0;

  Future<void> _initializeCustomerLocation() async {
    final selectionVersion = _locationSelectionVersion;
    // check kalau customer ada saved location, kalau takde baru call getcustomerlocation
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final userData = await _authService.getUserData(user.uid);
      if (!mounted || selectionVersion != _locationSelectionVersion) {
        return;
      }
      if (userData?.hasCustomerLocation == true) {
        _applyCustomerLocation(
          LocationSelection(
            coordinates: LatLng(
              userData!.customerLatitude!,
              userData.customerLongitude!,
            ),
            label: userData.customerLocationLabel ?? 'Selected location',
          ),
          userData.customerLocationIsManual,
          persist: false, // false for check cust loc, it move to get cust loc
        );
        setState(() => _isLocatingCustomer = false);
        return;
      }
    }
    if (mounted && selectionVersion == _locationSelectionVersion) {
      await _getCustomerLocation(); // get cust loc
    }
  }

  void _applyCustomerLocation(
    LocationSelection selection,
    bool isManual, {
    bool persist = true,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      // default
      _locationSelectionVersion++;
      _isLocatingCustomer = false;
      _selectedVendorId = null;
      _customerPosition = selection.coordinates;
      _searchCenter = selection.coordinates;
      _visibleBounds = null;
      _searchBoundsActive = false;
      _previewVendorId = null;
      _selectedDishId = null;
      _showSearchArea = false;
      _customerLocationLabel = selection.label;
      _locationPermissionGranted = !isManual;
      _locationError = null; // buang error
    });
    final controller = _mapController;
    if (controller != null) _expectProgrammaticCameraMove();
    controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
          selection.coordinates,
          isManual
              ? 13.5
              : 15), // moves map. 13.5 size kalau manual, 15 gps (closer)
    );
    if (persist) {
      unawaited(_authService.saveCustomerLocation(
        latitude: selection.coordinates.latitude,
        longitude: selection.coordinates.longitude,
        label: selection.label,
        isManual: isManual,
      ));
    }
  }

  Future<void> _getCustomerLocation() async {
    if (_isLocatingCustomer && _locationRequestActive) {
      return;
    }
    _locationRequestActive = true;
    final selectionVersion = _locationSelectionVersion;
    if (mounted) {
      setState(() {
        _isLocatingCustomer = true;
        _locationError = null;
        _locationPermissionGranted = false;
      });
    }
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled(); // check gps bukak ke tak
      if (!serviceEnabled) {
        throw StateError('Turn on GPS, or browse the map manually.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission(); // check gps permission
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || // customer reject
          permission == LocationPermission.deniedForever) {
        // customer kena allow gps thru setting phone
        throw StateError(permission == LocationPermission.deniedForever
            ? 'Allow location access in phone settings, or browse manually.'
            : 'Location access denied. You can still browse the map.');
      }

      final position = await Geolocator.getCurrentPosition(
        // read coordinate lepas allow gps, 12s limit kalau x, set manual
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      if (!mounted) {
        return;
      }
      final coordinates = LatLng(position.latitude, position.longitude);
      String label;
      try {
        label = await describeLocation(coordinates);
      } catch (_) {
        label = 'Current location';
      }
      if (!mounted || selectionVersion != _locationSelectionVersion) return;
      _applyCustomerLocation(
        LocationSelection(coordinates: coordinates, label: label),
        false,
      );
    } catch (error) {
      if (mounted && selectionVersion == _locationSelectionVersion) {
        setState(() {
          _locationError = error is StateError
              ? error.message.toString()
              : 'Could not find your location. Retry or browse the map manually.';
        });
      }
    } finally {
      _locationRequestActive = false;
      if (mounted) {
        setState(() => _isLocatingCustomer = false);
      }
    }
  }

  Future<void> _enterCustomerLocationManually() async {
    final selection = await showManualLocationDialog(
      context,
      initialLocation: _customerPosition ?? _defaultPosition.target,
      title: 'Set Search Location',
    );

    if (selection == null || !mounted) {
      return;
    }

    _applyCustomerLocation(selection, true);
  }

  void _setSearchRadius(double radius) {
    setState(() {
      _searchRadiusKm = radius;
      _visibleBounds = null;
      _searchBoundsActive = false;
      _showSearchArea = false;
    });
    final center = _searchCenter ?? _customerPosition;
    if (center != null) {
      if (_mapController != null) _expectProgrammaticCameraMove();
      final zoom = switch (radius) {
        <= 5 => 13.5,
        <= 10 => 12.5,
        <= 25 => 11.0,
        _ => 10.0,
      };
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(center, zoom));
    }
  }

  Future<void> _chooseSavedLocation({String? type}) async {
    final selection = await showSavedLocationsSheet(context,
        initialLocation:
            _searchCenter ?? _customerPosition ?? _defaultPosition.target,
        initialType: type);
    if (!mounted || selection == null) return;
    _applyCustomerLocation(selection, true);
  }

  Future<void> _pinSearchLocation() async {
    final selection = await Navigator.push<LocationSelection>(
        context,
        MaterialPageRoute(
            builder: (_) => PinLocationScreen(
                initialLocation: _searchCenter ??
                    _customerPosition ??
                    _defaultPosition.target)));
    if (!mounted || selection == null) return;
    _applyCustomerLocation(selection, true);
  }

  // ui for set location, enter manually button
  Future<void> _chooseLocationSource() async {
    FocusScope.of(context).unfocus();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Set your location',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppGroupedCard(children: [
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.my_location_rounded, color: Color(0xFF43CE72)),
                title: const Text('Use current location'),
                subtitle: const Text('Find stalls near where you are now'),
                onTap: () => Navigator.pop(ctx, 'current'),
              ),
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.search_rounded, color: AppColors.primary),
                title: const Text('Enter manually'),
                subtitle:
                    const Text('Search for an area, city, state, or postcode'),
                onTap: () => Navigator.pop(ctx, 'manual'),
              ),
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.push_pin_rounded, color: Color(0xFFFFAE22)),
                title: const Text('Pin on map'),
                subtitle: const Text('Choose an exact search location'),
                onTap: () => Navigator.pop(ctx, 'pin'),
              ),
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.home_rounded, color: Color(0xFFAD55E8)),
                title: const Text('Home & saved places'),
                subtitle: const Text('Save and choose Home or custom pins'),
                onTap: () => Navigator.pop(ctx, 'saved'),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    if (choice == 'current') {
      await _getCustomerLocation();
    } else if (choice == 'saved') {
      await _chooseSavedLocation();
    } else if (choice == 'pin') {
      await _pinSearchLocation();
    } else {
      await _enterCustomerLocationManually();
    }
  }

  Future<void> _selectVendor(VendorModel vendor) async {
    if (!vendor.hasValidLocation) {
      return;
    }
    FocusScope.of(context).unfocus();
    final request = ++_cameraRequest;
    setState(() {
      _selectedVendorId = vendor.vendorId;
    });
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    _expectProgrammaticCameraMove();
    try {
      final currentZoom = await controller.getZoomLevel();
      if (!mounted || request != _cameraRequest) {
        return;
      }

      final targetZoom =
          currentZoom < 16 ? 16.0 : currentZoom.clamp(16.0, 17.5).toDouble();
      await controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(vendor.latitude, vendor.longitude),
        targetZoom,
      ));
    } catch (_) {
      // A controller may be disposed while the user changes screens.
      if (request == _cameraRequest) {
        _programmaticCameraMove = false;
        _cameraMoveGuard?.cancel();
      }
    }
  }

  // Camera movement never rewrites the searched area or carousel membership.
  // Only Search here commits new bounds; this keeps the next card reachable.
  void _updateVisibleBounds() async {
    final controller = _mapController;
    if (controller == null) return;
    final request = ++_boundsRequest;
    final movedByUser = _cameraMovedByUser && !_programmaticCameraMove;
    _cameraMovedByUser = false;
    try {
      final bounds = await controller.getVisibleRegion();
      if (!mounted || request != _boundsRequest) return;
      setState(() {
        _pendingBounds = bounds;
        _visibleBounds ??= bounds;
        if (movedByUser) {
          final previous = _visibleBounds!;
          _showSearchArea =
              (previous.southwest.latitude - bounds.southwest.latitude).abs() >
                      .0001 ||
                  (previous.southwest.longitude - bounds.southwest.longitude)
                          .abs() >
                      .0001 ||
                  (previous.northeast.latitude - bounds.northeast.latitude)
                          .abs() >
                      .0001 ||
                  (previous.northeast.longitude - bounds.northeast.longitude)
                          .abs() >
                      .0001;
        }
        _programmaticCameraMove = false;
        _cameraMoveGuard?.cancel();
      });
    } catch (_) {
      _programmaticCameraMove = false;
      _cameraMoveGuard?.cancel();
    }
  }

  void _searchThisArea() {
    if (_pendingBounds == null || _mapCenter == null) return;
    setState(() {
      _visibleBounds = _pendingBounds;
      _searchBoundsActive = true;
      _selectedDishId = null;
      _searchCenter = _mapCenter;
      _showSearchArea = false;
      _selectedVendorId = null;
    });
  }

  Future<void> _resetCompass() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      _expectProgrammaticCameraMove();
      final camera = _lastCameraPosition;
      final zoom = camera?.zoom ?? await controller.getZoomLevel();
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: camera?.target ??
                _mapCenter ??
                _searchCenter ??
                _customerPosition ??
                _defaultPosition.target,
            zoom: zoom,
            bearing: 0,
            tilt: 0,
          ),
        ),
      );
    } catch (_) {
      // The map may be disposed while the user changes screens.
    }
  }

  Future<void> _chooseOpeningTime() async {
    final result = await showOpeningTimePicker(context);
    if (result == null || !mounted) return;
    setState(() {
      _openingTime = result;
      _statusFilter = 'All';
    });
  }

  Future<void> _choosePriceRange() async {
    _searchFocus.unfocus();
    final result =
        await showPriceRangePicker(context, initialRange: _priceRange);
    if (result == null || !mounted) return;
    setState(() {
      _priceRange = result.isActive ? result : null;
      _selectedVendorId = null;
    });
  }

  void _clearDiscoveryFilters() {
    _searchFocus.unfocus();
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _category = null;
      _priceRange = null;
      _openingTime = null;
      _statusFilter = 'All';
      _sort = DiscoverySort.distance;
      _availableOnly = false;
      _selfCollectOnly = false;
      _recentOnly = false;
      _selectedVendorId = null;
    });
  }

  bool _matchesOpening(VendorModel vendor) {
    final filter = _openingTime;
    if (filter != null) {
      return filter.end == null
          ? vendor.isScheduledOpenAt(filter.start)
          : hasScheduledOpening(filter.start, filter.end!, vendor.weeklyHours,
              vendor.temporaryClosures);
    }
    if (_statusFilter == 'Open') return vendor.isOpenNow;
    if (_statusFilter == 'Closed') return !vendor.isOpenNow;
    return true;
  }

  String _stallStatus(VendorModel vendor) => _openingTime != null
      ? 'Scheduled open'
      : vendor.isOpenNow
          ? 'Open now'
          : 'Closed';

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m away';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor:
          _selectedIndex == 3 ? ProfilePage.background : AppColors.background,
      appBar: _selectedIndex == 0 || _selectedIndex == 3
          ? null
          : AppPageAppBar(
              title: Text(
                _tabTitles[_selectedIndex],
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(top: true, bottom: false, child: _buildMapTab()),
          const CustomerFollowingScreen(),
          const CustomerNotificationsScreen(),
          CustomerProfileScreen(
            location: _customerPosition == null
                ? null
                : LocationSelection(
                    coordinates: _customerPosition!,
                    label: _customerLocationLabel ?? 'Selected location',
                  ),
            onLocationChanged: _applyCustomerLocation,
            onHomeLocation: () => _chooseSavedLocation(type: 'home'),
            onCustomLocation: () => _chooseSavedLocation(type: 'custom'),
          ),
        ],
      ),
      bottomNavigationBar: AppPillNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);

          if (index == 0) {
            unawaited(_loadGreeting());
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Following',
          ),
          NavigationDestination(
            icon: _notificationIcon(false),
            selectedIcon: _notificationIcon(true),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: _settingsIcon(false),
            selectedIcon: _settingsIcon(true),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _mapHeader() => Row(children: [
        Expanded(
          child: Material(
            color: AppColors.cardColor.withValues(alpha: .94),
            elevation: 3,
            shadowColor: const Color(0x18000000),
            borderRadius: BorderRadius.circular(25),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _chooseLocationSource,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                child: Row(children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.mint,
                    child:
                        Icon(Icons.person_rounded, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_welcomeLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.place_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                            child: Text(
                                _customerLocationLabel ?? 'Set your location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted))),
                      ]),
                    ],
                  )),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.cardColor.withValues(alpha: .94),
          elevation: 3,
          shadowColor: const Color(0x18000000),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () => setState(() => _selectedIndex = 2),
            icon: _notificationIcon(false),
          ),
        ),
      ]);

  Widget _notificationIcon(bool selected) => StreamBuilder<int>(
        stream: _unreadCount,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Badge(
            isLabelVisible: count > 0,
            label: Text(count >= 100 ? '99+' : '$count'),
            child: Icon(
              selected ? Icons.notifications : Icons.notifications_none_rounded,
            ),
          );
        },
      );

  Widget _settingsIcon(bool selected) => StreamBuilder<int>(
        stream: _bookingUnreadCount,
        builder: (context, snapshot) => Badge(
          isLabelVisible: (snapshot.data ?? 0) > 0,
          label:
              Text((snapshot.data ?? 0) > 99 ? '99+' : '${snapshot.data ?? 0}'),
          child: Icon(selected ? Icons.settings : Icons.settings_outlined),
        ),
      );

  IconData _suggestionIcon(DiscoverySuggestion suggestion) =>
      switch (suggestion.kind) {
        DiscoverySuggestionKind.dish => Icons.restaurant_menu_rounded,
        DiscoverySuggestionKind.stall => Icons.storefront_rounded,
        DiscoverySuggestionKind.category => Icons.category_outlined,
        DiscoverySuggestionKind.recent => Icons.history_rounded,
      };

  Widget _suggestionPanel(List<DiscoverySuggestion> suggestions) => Material(
        elevation: 7,
        shadowColor: const Color(0x33000000),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 304),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              if (_searchController.text.trim().isEmpty &&
                  _recentSearches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 6, 0),
                  child: Row(children: [
                    const Expanded(
                        child: Text('Recent searches',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                    TextButton(
                        onPressed: _clearRecentSearches,
                        child: const Text('Clear')),
                  ]),
                ),
              for (final suggestion in suggestions)
                ListTile(
                  dense: true,
                  leading: Icon(_suggestionIcon(suggestion),
                      size: 20, color: const Color(0xFF64748B)),
                  title: Text(suggestion.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(suggestion.detail),
                  trailing: suggestion.isRecent
                      ? IconButton(
                          tooltip: 'Remove recent search',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () =>
                              _removeRecentSearch(suggestion.label))
                      : const Icon(Icons.north_west_rounded, size: 17),
                  onTap: () => _submitSearch(suggestion.label),
                ),
            ],
          ),
        ),
      );

  Stream<List<VendorModel>> _watchVendors() =>
      _vendorService.getAllVendors().map((vendors) {
        final ids = vendors.map((vendor) => vendor.vendorId).toSet();
        for (final id in _ratingSubscriptions.keys.toList()) {
          if (!ids.contains(id)) {
            _ratingSubscriptions.remove(id)?.cancel();
            _ratings.remove(id);
            _ratingErrors.remove(id);
          }
        }
        for (final id in ids) {
          _ratingSubscriptions.putIfAbsent(
              id,
              () => _reviewService.watchReviews(id).listen((reviews) {
                    if (!mounted) return;
                    setState(() {
                      _ratingErrors.remove(id);
                      _ratings[id] = StallRatingSummary(
                          reviews.isEmpty
                              ? 0
                              : reviews.fold<int>(
                                      0, (sum, review) => sum + review.rating) /
                                  reviews.length,
                          reviews.length);
                    });
                  }, onError: (Object _) {
                    if (mounted) setState(() => _ratingErrors.add(id));
                  }));
        }
        return vendors;
      });

  Widget _ratingLine(VendorModel vendor) {
    final summary = _ratings[vendor.vendorId];
    final text = _ratingErrors.contains(vendor.vendorId)
        ? 'Rating unavailable'
        : summary == null
            ? 'Loading rating…'
            : summary.count == 0
                ? 'No reviews yet'
                : '${summary.average.toStringAsFixed(1)} (${summary.count} ${summary.count == 1 ? 'review' : 'reviews'})';
    return Row(children: [
      const Icon(Icons.star_rounded, size: 15, color: Color(0xFF946000)),
      const SizedBox(width: 4),
      Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted))),
    ]);
  }

  Future<void> _zoomToCluster(Cluster cluster) async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      if (cluster.bounds.southwest == cluster.bounds.northeast) {
        final zoom = await controller.getZoomLevel();
        await controller.animateCamera(CameraUpdate.newLatLngZoom(
            cluster.position, (zoom + 2).clamp(0, 21).toDouble()));
      } else {
        await controller
            .animateCamera(CameraUpdate.newLatLngBounds(cluster.bounds, 60));
      }
    } catch (_) {
      // The map may have been closed while its camera was updating.
    }
  }

  bool get _canSaveSearch =>
      FirebaseAuth.instance.currentUser != null &&
      FirebaseAuth.instance.currentUser!.isAnonymous == false &&
      FirebaseAuth.instance.currentUser!.emailVerified;

  Widget _buildDiscoveryList(
      AsyncSnapshot<List<VendorModel>> snapshot,
      List<VendorModel> vendors,
      List<DishSearchEntry> dishes,
      Map<String, VendorModel> vendorById,
      List<DiscoverySuggestion> suggestions) {
    final showDishes = _searchQuery.trim().isNotEmpty && dishes.isNotEmpty;
    final count = showDishes ? dishes.length : vendors.length;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _mapHeader()),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() {
                    _searchQuery = value;
                    _selectedVendorId = null;
                  }),
              onSubmitted: _submitSearch,
              decoration: InputDecoration(
                  hintText: 'Search dishes or stalls…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedVendorId = null;
                              }))))),
      Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 4),
          child: _compactMapFilters()),
      if (suggestions.isNotEmpty)
        ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: _suggestionPanel(suggestions)),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(
                child: Text('$count ${showDishes ? 'dishes' : 'stalls'}',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            if ((_searchCenter ?? _customerPosition) == null)
              const Flexible(
                  child: Text('Set a location for distance sorting',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textMuted))),
          ])),
      Expanded(
          child: snapshot.hasError
              ? Center(
                  child: TextButton(
                      onPressed: () =>
                          setState(() => _vendors = _watchVendors()),
                      child: const Text('Retry loading stalls')))
              : snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : count == 0
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                  _dishesLoading
                                      ? 'Loading dishes…'
                                      : _dishSearchError ??
                                          'No results match these filters. Try another search or a wider area.',
                                  textAlign: TextAlign.center)))
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 4, 16,
                              MediaQuery.paddingOf(context).bottom + 24),
                          itemCount: count,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final scaled =
                                MediaQuery.textScalerOf(context).scale(14) > 19;
                            return SizedBox(
                                height: scaled
                                    ? 210
                                    : showDishes
                                        ? 144
                                        : 136,
                                child: showDishes
                                    ? _dishCard(dishes[index],
                                        vendorById[dishes[index].vendorId]!)
                                    : _stallCard(vendors[index]));
                          })),
    ]);
  }

  Map<String, dynamic> _currentSearchFilters() {
    final center = _searchCenter ?? _customerPosition;
    return {
      'query': _searchController.text.trim(),
      'category': _category,
      'minimum': _priceRange?.minimum,
      'maximum': _priceRange?.maximum,
      'radius': _searchRadiusKm,
      'status': _statusFilter,
      'sort': _sort.name,
      'availableOnly': _availableOnly,
      'selfCollectOnly': _selfCollectOnly,
      'recentOnly': _recentOnly,
      'listOnly': _listOnly,
      'latitude': center?.latitude,
      'longitude': center?.longitude,
      'openingStart': _openingTime?.start.millisecondsSinceEpoch,
      'openingEnd': _openingTime?.end?.millisecondsSinceEpoch,
      'openingLabel': _openingTime?.label,
    };
  }

  Future<void> _saveCurrentSearch() async {
    if (!_canSaveSearch) return;
    _searchFocus.unfocus();
    final filters = _currentSearchFilters();
    final query = _searchController.text.trim();
    var name =
        '${query.isEmpty ? 'Nearby stalls' : query}${_priceRange == null ? '' : ' · ${_priceRange!.label}'} · within ${_searchRadiusKm.toStringAsFixed(0)} km';
    if (name.length > 80) name = name.substring(0, 80);
    final chosen = await showDialog<String>(
        context: context,
        builder: (dialog) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: const Text('Save this search'),
                    content: TextFormField(
                        initialValue: name,
                        maxLength: 80,
                        decoration:
                            const InputDecoration(labelText: 'Search name'),
                        onChanged: (value) => update(() => name = value)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialog),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: name.trim().isEmpty
                              ? null
                              : () => Navigator.pop(dialog, name.trim()),
                          child: const Text('Save')),
                    ])));
    if (chosen == null || !mounted || !_canSaveSearch) return;
    try {
      await _savedSearches.save(chosen, filters);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Search saved.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save this search. Please retry.')));
      }
    }
  }

  Future<void> _showSavedSearches() async {
    if (!_canSaveSearch) return;
    _searchFocus.unfocus();
    var future = _savedSearches.load();
    final selected = await showModalBottomSheet<SavedDiscoverySearch>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheet) => StatefulBuilder(
            builder: (context, update) => SizedBox(
                height: MediaQuery.sizeOf(context).height * .65,
                child: Column(children: [
                  AppSheetHeader(
                      title: const Text('Saved searches'),
                      onBack: () => Navigator.pop(sheet)),
                  Expanded(
                      child: FutureBuilder<List<SavedDiscoverySearch>>(
                          future: future,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                  child: TextButton(
                                      onPressed: () => update(
                                          () => future = _savedSearches.load()),
                                      child: const Text(
                                          'Retry loading saved searches')));
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final searches = snapshot.data!;
                            if (searches.isEmpty) {
                              return const Center(
                                  child: Text('No saved searches yet.'));
                            }
                            return ListView.builder(
                                itemCount: searches.length,
                                itemBuilder: (context, index) {
                                  final search = searches[index];
                                  return ListTile(
                                      title: Text(search.name),
                                      leading:
                                          const Icon(Icons.bookmark_outline),
                                      onTap: () => Navigator.pop(sheet, search),
                                      trailing: IconButton(
                                          tooltip: 'Delete saved search',
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          onPressed: () async {
                                            try {
                                              await _savedSearches
                                                  .remove(search.id);
                                              if (context.mounted) {
                                                update(() => future =
                                                    _savedSearches.load());
                                              }
                                            } catch (_) {
                                              if (sheet.mounted) {
                                                ScaffoldMessenger.of(sheet)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Could not delete this search.')));
                                              }
                                            }
                                          }));
                                });
                          })),
                ]))));
    if (selected == null || !mounted || !_canSaveSearch) return;
    final filters = selected.filters;
    setState(() {
      _searchQuery = filters['query'] as String;
      _searchController.text = _searchQuery;
      _searchController.selection =
          TextSelection.collapsed(offset: _searchQuery.length);
      _category = filters['category'] as String?;
      final minimum = (filters['minimum'] as num?)?.toDouble();
      final maximum = (filters['maximum'] as num?)?.toDouble();
      _priceRange = minimum == null && maximum == null
          ? null
          : MenuPriceRange(minimum: minimum, maximum: maximum);
      _searchRadiusKm = (filters['radius'] as num).toDouble();
      _statusFilter = filters['status'] as String;
      _sort = DiscoverySort.values.firstWhere(
          (sort) => sort.name == filters['sort'],
          orElse: () => DiscoverySort.distance);
      _availableOnly = filters['availableOnly'] == true;
      _selfCollectOnly = filters['selfCollectOnly'] == true;
      _recentOnly = filters['recentOnly'] == true;
      _listOnly = filters['listOnly'] == true;
      _searchCenter = filters['latitude'] == null
          ? null
          : LatLng((filters['latitude'] as num).toDouble(),
              (filters['longitude'] as num).toDouble());
      _openingTime = filters['openingStart'] == null
          ? null
          : OpeningTimeFilter(
              DateTime.fromMillisecondsSinceEpoch(
                  filters['openingStart'] as int),
              filters['openingLabel'] as String,
              end: filters['openingEnd'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      filters['openingEnd'] as int));
      _selectedVendorId = null;
      _visibleBounds = null;
      _searchBoundsActive = false;
      if (_listOnly) _mapController = null;
    });
    if (!_listOnly && _searchCenter != null && _mapController != null) {
      try {
        await _mapController!
            .animateCamera(CameraUpdate.newLatLngZoom(_searchCenter!, 14));
      } catch (_) {/* The map may still be mounting. */}
    }
  }

  Widget _buildMapTab() {
    return StreamBuilder<List<VendorModel>>(
      stream: _vendors,
      builder: (context, snapshot) {
        final eligibleDishes = _allDishes
            .where((dish) => !_availableOnly || dishIsAvailable(dish))
            .toList();
        final allVendors = (snapshot.data ?? [])
            .where((v) =>
                v.hasValidLocation &&
                (_category == null || v.hasCategory(_category!)))
            .toList();

        final query = normalizeDiscoveryQuery(_searchQuery);
        final dishesByVendor = <String, List<DishSearchEntry>>{};
        for (final dish in eligibleDishes) {
          (dishesByVendor[dish.vendorId] ??= []).add(dish);
        }
        final sortMenus = _sort == DiscoverySort.price && _priceRange != null
            ? {
                for (final entry in dishesByVendor.entries)
                  entry.key: entry.value.where(_priceRange!.contains).toList()
              }
            : dishesByVendor;
        final currentRatings = {
          for (final entry in _ratings.entries)
            if (!_ratingErrors.contains(entry.key)) entry.key: entry.value
        };
        final matchingVendors = allVendors.where((vendor) {
          final menu =
              dishesByVendor[vendor.vendorId] ?? const <DishSearchEntry>[];
          if (_availableOnly &&
              (!vendor.isOpenNow || !menu.any(dishIsAvailable))) {
            return false;
          }
          if (_selfCollectOnly && !vendor.selfCollectEnabled) return false;
          if (_recentOnly && !stallUpdatedRecently(vendor, menu)) return false;
          // All stalls are visible until the customer explicitly filters hours.
          // Open now must also apply to stalls found through a dish search.
          if (!_matchesOpening(vendor)) return false;
          return vendorMatchesQueryAndPrice(
            vendor: vendor,
            dishes: dishesByVendor[vendor.vendorId] ?? const [],
            query: query,
            priceRange: _priceRange,
          );
        });
        final filteredVendors = matchingVendors.where((vendor) {
          final position = _searchCenter ?? _customerPosition;
          if (position == null) {
            return true;
          }
          return Geolocator.distanceBetween(position.latitude,
                  position.longitude, vendor.latitude, vendor.longitude) <=
              _searchRadiusKm * 1000;
        }).toList();

        final filteredVendorById = {
          for (final vendor in filteredVendors) vendor.vendorId: vendor,
        };
        final dishResults = query.isEmpty
            ? <DishSearchEntry>[]
            : eligibleDishes
                .where((dish) =>
                    discoveryMatches(query, dish.item.name) &&
                    (_priceRange == null || _priceRange!.contains(dish)) &&
                    filteredVendorById.containsKey(dish.vendorId))
                .toList()
          ..sort((a, b) => compareDiscoveryDishes(a, b,
              sort: _sort,
              vendors: filteredVendorById,
              center: _searchCenter ?? _customerPosition,
              ratings: currentRatings,
              dishes: sortMenus,
              query: query));
        final suggestionVendors = allVendors.where((vendor) {
          final center = _searchCenter ?? _customerPosition;
          return center == null ||
              Geolocator.distanceBetween(center.latitude, center.longitude,
                      vendor.latitude, vendor.longitude) <=
                  _searchRadiusKm * 1000;
        });
        final suggestions = buildDiscoverySuggestions(
          query: _searchController.text,
          vendors: suggestionVendors,
          dishes: eligibleDishes,
          categories: stallCategories,
          recentSearches: _recentSearches,
          priceRange: _priceRange,
        );
        final showSuggestions = _searchFocus.hasFocus && suggestions.isNotEmpty;
        final showingDishResults = query.isNotEmpty && dishResults.isNotEmpty;

        // Freeze a committed search area while card swipes move the camera.
        var onScreenVendors = List<VendorModel>.from(filteredVendors);

        if (_searchBoundsActive && _visibleBounds != null) {
          final southWest = _visibleBounds!.southwest;
          final northEast = _visibleBounds!.northeast;

          onScreenVendors = onScreenVendors.where((v) {
            return v.latitude >= southWest.latitude &&
                v.latitude <= northEast.latitude &&
                v.longitude >= southWest.longitude &&
                v.longitude <= northEast.longitude;
          }).toList();
        }

        onScreenVendors.sort((a, b) => compareDiscoveryVendors(a, b,
            sort: _sort,
            center: _searchCenter ?? _customerPosition,
            ratings: currentRatings,
            dishes: sortMenus,
            query: query));

        if (!onScreenVendors
            .any((vendor) => vendor.vendorId == _selectedVendorId)) {
          _selectedVendorId = onScreenVendors.firstOrNull?.vendorId;
        }
        if (_previewVendorId != null &&
            !onScreenVendors
                .any((vendor) => vendor.vendorId == _previewVendorId)) {
          _previewVendorId = null;
          _previewCamera = null;
        }

        final markers = onScreenVendors
            .where((vendor) =>
                _markerIcons.containsKey((_markerCategory(vendor), false)))
            .map(
              (v) => Marker(
                markerId: MarkerId(v.vendorId),
                clusterManagerId:
                    v.vendorId == _selectedVendorId ? null : _clusterId,
                position: LatLng(v.latitude, v.longitude),
                anchor: const Offset(.5, .5),
                zIndexInt: v.vendorId == _selectedVendorId ? 2 : 1,
                icon: _markerIcons[(
                  _markerCategory(v),
                  v.vendorId == _selectedVendorId
                )]!,
                infoWindow: InfoWindow(
                  title: v.stallName,
                  snippet: '${v.categoryLabel} · ${_stallStatus(v)}',
                  onTap: () => _openStallPreview(v),
                ),
                consumeTapEvents: true,
                onTap: () => _selectVendor(v),
              ),
            )
            .toSet();
        final searchPosition = _searchCenter ?? _customerPosition;
        if (searchPosition != null) {
          markers.add(Marker(
            markerId: const MarkerId('customer-search-location'),
            position: searchPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
                title: 'Search location',
                snippet: searchPosition == _customerPosition
                    ? _customerLocationLabel ?? 'Selected location'
                    : 'Selected map area'),
          ));
        }

        if (_listOnly) {
          return _buildDiscoveryList(snapshot, onScreenVendors, dishResults,
              filteredVendorById, showSuggestions ? suggestions : const []);
        }

        return LayoutBuilder(builder: (context, constraints) {
          final navClearance = MediaQuery.paddingOf(context).bottom + 12;
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final geometry = DiscoveryMapGeometry(constraints.biggest);
          final overlayWidth = geometry.overlayWidth;
          final headerHeight = math.max(54.0, 32 * textScale + 14);
          final searchTop = 10 + headerHeight + 8;
          final searchHeight = math.max(50.0, 16 * textScale + 28);
          final filterTop = searchTop + searchHeight + 8;
          final headerBottom =
              filterTop + math.max(48.0, 14 * textScale + 26) + 10;
          final panelWidth = geometry.panelWidth;
          final desiredCardHeight = showingDishResults
              ? 160.0 * textScale
              : StallMapCard.preferredHeight(
                  context, panelWidth, onScreenVendors,
                  viewportFraction: geometry.viewportFraction,
                  cardsPerPage: geometry.cardsPerPage);
          final cardHeight = math.min(
              desiredCardHeight,
              math.max(100.0,
                  constraints.maxHeight - headerBottom - navClearance - 56));
          final panelHeight = cardHeight + 36;
          final preview = onScreenVendors
              .where((vendor) => vendor.vendorId == _previewVendorId)
              .firstOrNull;
          final cards = showingDishResults
              ? dishResults
                  .where((dish) => onScreenVendors
                      .any((vendor) => vendor.vendorId == dish.vendorId))
                  .toList()
              : <DishSearchEntry>[];
          final resultCount =
              showingDishResults ? cards.length : onScreenVendors.length;
          final ids = showingDishResults
              ? cards
                  .map((dish) => '${dish.vendorId}/${dish.item.itemId}')
                  .toList()
              : onScreenVendors.map((vendor) => vendor.vendorId).toList();
          if (showingDishResults &&
              !cards.any((dish) =>
                  '${dish.vendorId}/${dish.item.itemId}' == _selectedDishId &&
                  dish.vendorId == _selectedVendorId)) {
            final dish = cards
                    .where((dish) => dish.vendorId == _selectedVendorId)
                    .firstOrNull ??
                cards.firstOrNull;
            _selectedDishId =
                dish == null ? null : '${dish.vendorId}/${dish.item.itemId}';
          }
          final selectedCard =
              showingDishResults ? _selectedDishId : _selectedVendorId;
          final searching = snapshot.connectionState == ConnectionState.waiting;

          return ValueListenableBuilder<double>(
            valueListenable: _previewExtent,
            builder: (context, extent, _) {
              final covered = preview == null
                  ? panelHeight + 64
                  : (constraints.maxHeight - navClearance) * extent;
              final controlsBottom = navClearance + covered + 12;
              final controlsRoom = constraints.maxHeight -
                  controlsBottom -
                  headerBottom -
                  (_locationError != null ? 60 : 0);
              final mapTopInset =
                  math.min(headerBottom, constraints.maxHeight * .38);
              return Stack(children: [
                Positioned.fill(
                    child: GoogleMap(
                  style: _mapStyle,
                  initialCameraPosition: CameraPosition(
                    target: _lastCameraPosition?.target ??
                        _searchCenter ??
                        _customerPosition ??
                        _defaultPosition.target,
                    zoom: _lastCameraPosition?.zoom ?? 14,
                  ),
                  markers: markers,
                  clusterManagers: {
                    ClusterManager(
                        clusterManagerId: _clusterId,
                        onClusterTap: _zoomToCluster)
                  },
                  myLocationEnabled: _locationPermissionGranted,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  padding: EdgeInsets.fromLTRB(
                      12,
                      mapTopInset,
                      12,
                      math.min(
                          navClearance + covered + 12,
                          math.max(
                              12, constraints.maxHeight - mapTopInset - 80))),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_lastCameraPosition != null) {
                      _expectProgrammaticCameraMove();
                      controller.moveCamera(
                          CameraUpdate.newCameraPosition(_lastCameraPosition!));
                    } else if (_customerPosition != null) {
                      _expectProgrammaticCameraMove();
                      controller.animateCamera(
                          CameraUpdate.newLatLngZoom(_customerPosition!, 15));
                    }
                    _updateVisibleBounds();
                  },
                  onCameraMove: (position) {
                    _mapCenter = position.target;
                    _lastCameraPosition = position;
                    if ((_mapBearing.value - position.bearing).abs() > .1) {
                      _mapBearing.value = position.bearing;
                    }
                  },
                  onCameraMoveStarted: () {
                    _boundsRequest++;
                    if (!_programmaticCameraMove) _cameraMovedByUser = true;
                  },
                  onCameraIdle: _updateVisibleBounds,
                  onTap: (_) => _searchFocus.unfocus(),
                )),
                Positioned(
                    top: 10,
                    left: 12,
                    width: overlayWidth,
                    child: _mapHeader()),
                Positioned(
                    top: searchTop,
                    left: 12,
                    width: overlayWidth,
                    child: Material(
                      color: AppColors.cardColor,
                      elevation: 3,
                      shadowColor: const Color(0x22000000),
                      borderRadius: BorderRadius.circular(28),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) => setState(() {
                          _searchQuery = value;
                          _selectedVendorId = null;
                          _selectedDishId = null;
                          _previewVendorId = null;
                        }),
                        onSubmitted: _submitSearch,
                        decoration: InputDecoration(
                          filled: false,
                          hintText: 'Search dishes or stalls…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.textMuted),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _selectedVendorId = null;
                                    _selectedDishId = null;
                                  }),
                                ),
                        ),
                      ),
                    )),
                Positioned(
                    top: filterTop,
                    left: 12,
                    width: overlayWidth,
                    child: _compactMapFilters()),
                if (_locationError != null && preview == null)
                  Positioned(
                      top: headerBottom,
                      left: 12,
                      width: overlayWidth,
                      child: Material(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(children: [
                            const Icon(Icons.location_off_outlined, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: Text(
                                    'Location unavailable. Browse the map or set a location.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11))),
                            TextButton(
                                onPressed: _chooseLocationSource,
                                child: const Text('Set location')),
                          ]),
                        ),
                      )),
                if (controlsRoom >= 48 && (preview == null || extent < .7))
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 120),
                    right: 12,
                    bottom: controlsBottom,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (controlsRoom >= 104) ...[
                        FloatingActionButton.small(
                          heroTag: 'compass_button',
                          tooltip: 'Reset compass',
                          backgroundColor: AppColors.cardColor,
                          onPressed: _resetCompass,
                          child: ValueListenableBuilder<double>(
                              valueListenable: _mapBearing,
                              builder: (_, bearing, __) => Transform.rotate(
                                  angle: -bearing * math.pi / 180,
                                  child: const Icon(Icons.navigation_rounded))),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FloatingActionButton.small(
                        heroTag: 'recenter_button',
                        tooltip: 'My location',
                        backgroundColor: AppColors.cardColor,
                        onPressed: _getCustomerLocation,
                        child: _isLocatingCustomer
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded),
                      ),
                    ]),
                  ),
                if (preview == null) ...[
                  if (_showSearchArea)
                    Positioned(
                      left: geometry.panelLeft + 12,
                      right: geometry.panelLeft + 12,
                      bottom: navClearance + panelHeight + 14,
                      child: Center(
                          child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardColor,
                            foregroundColor: AppColors.textDark,
                            shape: const StadiumBorder(),
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10)),
                        onPressed: _searchThisArea,
                        child: const Text('Search here'),
                      )),
                    ),
                  Positioned(
                    left: geometry.panelLeft,
                    bottom: navClearance + 8,
                    width: panelWidth,
                    height: panelHeight,
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  '$resultCount ${showingDishResults ? 'dishes' : 'stalls'} nearby',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600))),
                          SizedBox(
                              height: 30,
                              child: TextButton(
                                onPressed: snapshot.hasError
                                    ? () => setState(
                                        () => _vendors = _watchVendors())
                                    : () => showingDishResults
                                        ? _showAllDishes(
                                            cards, filteredVendorById)
                                        : _showAllStalls(onScreenVendors),
                                child: Text(
                                    snapshot.hasError ? 'Retry' : 'View all'),
                              )),
                        ]),
                      ),
                      Expanded(
                        child: searching
                            ? const Center(child: CircularProgressIndicator())
                            : resultCount == 0
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Material(
                                      color: AppColors.cardColor,
                                      borderRadius: BorderRadius.circular(23),
                                      child: Center(
                                        child: Padding(
                                            padding: const EdgeInsets.all(18),
                                            child: Text(
                                                snapshot.hasError
                                                    ? 'Could not load stalls. Check your connection and retry.'
                                                    : _dishSearchError !=
                                                                null &&
                                                            (query.isNotEmpty ||
                                                                _priceRange !=
                                                                    null)
                                                        ? _dishSearchError!
                                                        : _dishesLoading &&
                                                                (query.isNotEmpty ||
                                                                    _priceRange !=
                                                                        null)
                                                            ? 'Loading dishes and prices…'
                                                            : 'No matching stalls in this area. Move the map, expand the distance, or reset filters.',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textMuted))),
                                      ),
                                    ))
                                : StallCardCarousel(
                                    key: ValueKey(showingDishResults
                                        ? 'dish-map-cards'
                                        : 'stall-map-cards'),
                                    ids: ids,
                                    selectedId: selectedCard,
                                    viewportFraction: geometry.viewportFraction,
                                    cardsPerPage: geometry.cardsPerPage,
                                    onSelected: (index) {
                                      if (showingDishResults) {
                                        final dish = cards[index];
                                        _selectedDishId = ids[index];
                                        _selectVendor(
                                            filteredVendorById[dish.vendorId]!);
                                      } else {
                                        _selectVendor(onScreenVendors[index]);
                                      }
                                    },
                                    itemBuilder: (_, index) =>
                                        showingDishResults
                                            ? _dishCard(
                                                cards[index],
                                                filteredVendorById[
                                                    cards[index].vendorId]!)
                                            : StallMapCard(
                                                vendor: onScreenVendors[index],
                                                onTap: () {
                                                  final vendor =
                                                      onScreenVendors[index];
                                                  if (vendor.vendorId ==
                                                      _selectedVendorId) {
                                                    _openStallPreview(vendor);
                                                  } else {
                                                    _selectVendor(vendor);
                                                  }
                                                }),
                                  ),
                      ),
                    ]),
                  ),
                ],
                if (preview != null)
                  Positioned.fill(
                      left: geometry.previewInset,
                      right: geometry.previewInset,
                      bottom: navClearance,
                      child: _buildStallPreview(preview)),
                if (showSuggestions && preview == null)
                  Positioned(
                      top: searchTop + searchHeight + 4,
                      left: 12,
                      width: overlayWidth,
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight * .4),
                          child: _suggestionPanel(suggestions))),
              ]);
            },
          );
        });
      },
    );
  }

  Widget _compactMapFilters() => DiscoveryMapFilters(
        category: _category,
        hasExtraFilters: _priceRange != null ||
            _openingTime != null ||
            _statusFilter == 'Closed' ||
            _searchRadiusKm != 5,
        openNow: _statusFilter == 'Open' && _openingTime == null,
        sort: _sort,
        availableOnly: _availableOnly,
        selfCollectOnly: _selfCollectOnly,
        recentOnly: _recentOnly,
        onCategory: (value) => setState(() {
          _category = value;
          _selectedVendorId = null;
        }),
        onOpenNow: (value) => setState(() {
          _statusFilter = value ? 'Open' : 'All';
          _openingTime = null;
        }),
        onSort: (value) => setState(() => _sort = value),
        onAvailable: (value) => setState(() => _availableOnly = value),
        onSelfCollect: (value) => setState(() => _selfCollectOnly = value),
        onRecent: (value) => setState(() => _recentOnly = value),
        onReset: _clearDiscoveryFilters,
        moreItems: [
          MenuItemButton(
              leadingIcon: Icon(_listOnly ? Icons.map_outlined : Icons.list),
              onPressed: () {
                _searchFocus.unfocus();
                setState(() {
                  _listOnly = !_listOnly;
                  _previewVendorId = null;
                  if (_listOnly) _mapController = null;
                });
              },
              child: Text(_listOnly ? 'Map view' : 'List view')),
          MenuItemButton(
              onPressed: _chooseLocationSource,
              child: const Text('Set location')),
          MenuItemButton(
              onPressed: _choosePriceRange,
              child: Text(_priceRange?.label ?? 'Any price')),
          MenuItemButton(
              onPressed: _chooseOpeningTime,
              child: Text(_openingTime?.label ?? 'Open at…')),
          SubmenuButton(
              menuStyle: discoveryMenuStyle,
              menuChildren: [
                for (final radius in [5.0, 10.0, 25.0, 50.0])
                  DiscoveryMenuChoice(
                      label: 'Within ${radius.toStringAsFixed(0)} km',
                      selected: _searchRadiusKm == radius,
                      onPressed: () => _setSearchRadius(radius)),
              ],
              child:
                  Text('Distance: ${_searchRadiusKm.toStringAsFixed(0)} km')),
          SubmenuButton(
              menuStyle: discoveryMenuStyle,
              menuChildren: [
                for (final status in ['All', 'Open', 'Closed'])
                  DiscoveryMenuChoice(
                      label: status == 'All' ? 'All stalls' : status,
                      selected: _statusFilter == status && _openingTime == null,
                      onPressed: () => setState(() {
                            _statusFilter = status;
                            _openingTime = null;
                          })),
              ],
              child: const Text('Stall status')),
          if (_canSaveSearch) ...[
            MenuItemButton(
                onPressed: _saveCurrentSearch,
                child: const Text('Save search')),
            MenuItemButton(
                onPressed: _showSavedSearches,
                child: const Text('Saved searches')),
          ],
        ],
      );

  String _markerCategory(VendorModel vendor) =>
      vendor.allCategories.where(stallCategories.contains).firstOrNull ?? '';

  Future<void> _loadMapMarkerIcons() async {
    try {
      final entries = await Future.wait([
        for (final category in ['', ...stallCategories])
          for (final selected in [false, true])
            _markerCache
                .icon(category, selected: selected)
                .then((icon) => MapEntry((category, selected), icon)),
      ]);
      if (mounted) setState(() => _markerIcons.addEntries(entries));
    } catch (_) {
      // A disposed renderer must not interrupt discovery.
    }
  }

  void _openStallPreview(VendorModel vendor) {
    _searchFocus.unfocus();
    _previewExtent.value = .55;
    _previewCamera = _lastCameraPosition;
    final user = FirebaseAuth.instance.currentUser;
    _previewFollowStream = user == null || user.isAnonymous
        ? Stream.value(false)
        : _followService.isFollowing(user.uid, vendor.vendorId);
    _expectProgrammaticCameraMove();
    setState(() {
      _selectedVendorId = vendor.vendorId;
      _previewVendorId = vendor.vendorId;
    });
  }

  Future<void> _closeStallPreview() async {
    final camera = _previewCamera;
    _expectProgrammaticCameraMove();
    setState(() {
      _previewVendorId = null;
      _previewCamera = null;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (camera != null && _mapController != null) {
      try {
        await _mapController!
            .animateCamera(CameraUpdate.newCameraPosition(camera));
      } catch (_) {/* Map can be disposed during navigation. */}
    }
  }

  Widget _buildStallPreview(VendorModel vendor) => StreamBuilder<bool>(
        stream: _previewFollowStream,
        builder: (context, snapshot) => StallPreviewSheet(
          key: ValueKey('preview-${vendor.vendorId}'),
          vendor: vendor,
          rating: _ratingLine(vendor),
          distance: _distanceTo(vendor),
          photos: <String>{
            if (vendor.imageUrl.isNotEmpty) vendor.imageUrl,
            ..._allDishes
                .where((dish) => dish.vendorId == vendor.vendorId)
                .map((dish) => dish.item.imageUrl)
                .where((url) => url.isNotEmpty)
          }.take(6).toList(),
          following: snapshot.data ?? false,
          onFollow: _followingBusy ||
                  snapshot.connectionState == ConnectionState.waiting
              ? null
              : () => snapshot.hasError
                  ? _retryPreviewFollow(vendor)
                  : _togglePreviewFollow(vendor, snapshot.data ?? false),
          onDirections: () => _previewDirections(vendor),
          onViewMenu: () => _openVendorDetails(vendor,
              dishId: _allDishes
                  .where((dish) => dish.vendorId == vendor.vendorId)
                  .firstOrNull
                  ?.item
                  .itemId),
          onSelfCollect: vendor.isOpenNow && vendor.hasValidLocation
              ? () => _previewSelfCollect(vendor)
              : null,
          onDetails: () => _openVendorDetails(vendor),
          onClose: _closeStallPreview,
          onExtentChanged: (extent) {
            if ((_previewExtent.value - extent).abs() >= .015) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _previewVendorId != vendor.vendorId) return;
                _expectProgrammaticCameraMove();
                _previewExtent.value = extent;
              });
            }
          },
        ),
      );

  void _retryPreviewFollow(VendorModel vendor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    setState(() => _previewFollowStream =
        _followService.isFollowing(user.uid, vendor.vendorId));
    _previewMessage('Could not load following. Retrying…');
  }

  void _previewMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<bool> _requireCustomerForPreview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      final signIn = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: const Text('Sign in to continue'),
                content: const Text(
                    'Use your customer account to follow stalls or book self-collect.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Sign in'))
                ],
              ));
      if (mounted && signIn == true) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return false;
    }
    if (!user.emailVerified) {
      _previewMessage('Verify your email to continue.');
      return false;
    }
    final profile = await _authService.getUserData(user.uid);
    if (!mounted) return false;
    if (profile?.role != 'customer') {
      _previewMessage(
          'Only customer accounts can follow stalls or book self-collect.');
      return false;
    }
    return true;
  }

  Future<void> _togglePreviewFollow(VendorModel vendor, bool following) async {
    if (_followingBusy) return;
    setState(() => _followingBusy = true);
    try {
      if (!await _requireCustomerForPreview() || !mounted) return;
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (following) {
        await _followService.unfollowVendor(uid, vendor.vendorId);
      } else {
        await _followService.followVendor(uid, vendor.vendorId);
      }
    } catch (_) {
      _previewMessage('Could not update following. Please retry.');
    } finally {
      if (mounted) setState(() => _followingBusy = false);
    }
  }

  Future<void> _previewDirections(VendorModel vendor) async {
    try {
      final launched = await launchUrl(
          Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': '${vendor.latitude},${vendor.longitude}',
          }),
          mode: LaunchMode.externalApplication);
      if (!launched) {
        _previewMessage('Could not open directions. Please retry.');
      }
    } catch (_) {
      _previewMessage('Could not open directions. Please retry.');
    }
  }

  Future<void> _previewSelfCollect(VendorModel vendor) async {
    try {
      if (!await _requireCustomerForPreview() || !mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DemoOrderCartScreen(vendor: vendor)));
    } catch (_) {
      _previewMessage('Could not open self-collect. Please retry.');
    }
  }

  String? _distanceTo(VendorModel vendor) {
    final position = _searchCenter ?? _customerPosition;
    if (position == null) {
      return null;
    }
    return _formatDistance(Geolocator.distanceBetween(position.latitude,
        position.longitude, vendor.latitude, vendor.longitude));
  }

  String _stockLabel(String status) => switch (status) {
        'low_stock' => 'Low stock',
        'out_of_stock' => 'Out of stock',
        _ => 'In stock',
      };

  Color _stockColor(String status) => switch (status) {
        'low_stock' => const Color(0xFFB45309),
        'out_of_stock' => const Color(0xFFB91C1C),
        _ => const Color(0xFF15803D),
      };

  Widget _dishPhoto(DishSearchEntry dish, {double size = 70}) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          color: AppColors.mint,
          child: dish.item.imageUrl.isEmpty
              ? const Icon(Icons.restaurant_rounded, color: AppColors.primary)
              : Image.network(
                  dish.item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.primary),
                ),
        ),
      );

  Widget _dishCard(DishSearchEntry dish, VendorModel vendor) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openVendorDetails(vendor, dishId: dish.item.itemId),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _dishPhoto(dish),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dish.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                        dish.priceIsKnown
                            ? 'RM ${dish.item.price.toStringAsFixed(2)}'
                            : 'Price unavailable',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text(vendor.stallName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11)),
                    const Spacer(),
                    Wrap(spacing: 7, runSpacing: 2, children: [
                      Text(_stockLabel(dish.item.status),
                          style: TextStyle(
                              color: _stockColor(dish.item.status),
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      Text(_stallStatus(vendor),
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 10)),
                      if (_distanceTo(vendor) != null)
                        Text(_distanceTo(vendor)!,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 10)),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _stallPhoto(VendorModel vendor, {double size = 48}) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
            width: size,
            height: size,
            color: AppColors.mint,
            child: vendor.imageUrl.isEmpty
                ? const Icon(Icons.storefront_rounded, color: AppColors.primary)
                : Image.network(vendor.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary))),
      );

  Widget _stallCard(VendorModel vendor) {
    final selected = vendor.vendorId == _selectedVendorId;
    final distance = _distanceTo(vendor);
    final pricedMenu = _allDishes.where((dish) =>
        dish.vendorId == vendor.vendorId &&
        (!_availableOnly || dishIsAvailable(dish)) &&
        (_priceRange == null || _priceRange!.contains(dish)));
    final fromPrice = lowestDishPrice(pricedMenu, _searchQuery);

    return Material(
      color: selected ? AppColors.mint : AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _listOnly
            ? () => _openVendorDetails(vendor)
            : () => _selectVendor(vendor),
        onDoubleTap: () => _openVendorDetails(vendor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _stallPhoto(vendor, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.stallName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        vendor.categoryLabel,
                        _stallStatus(vendor),
                        if (distance != null) distance,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(children: [
                      Expanded(child: _ratingLine(vendor)),
                      if (fromPrice != null) ...[
                        const SizedBox(width: 6),
                        Text('From RM ${fromPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.primary)),
                      ],
                    ]),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          vendor.hasFreshLocation
                              ? Icons.circle
                              : Icons.history_rounded,
                          size: 11,
                          color: vendor.hasFreshLocation
                              ? AppColors.openGreen
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            vendor.hasFreshLocation
                                ? 'Location updated'
                                : 'Last known location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'View stall',
                onPressed: () => _openVendorDetails(vendor),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAllStalls(List<VendorModel> vendors) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<VendorModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * .6,
        child: Column(children: [
          const AppSheetHeader(
              title: Text('Stalls in this area'),
              subtitle: Text('Choose a stall to find it on the map')),
          const Divider(height: 1),
          Expanded(
              child: ListView.separated(
            itemCount: vendors.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _stallPhoto(vendor),
                  title: Text(vendor.stallName),
                  subtitle: Text([
                    vendor.categoryLabel,
                    _stallStatus(vendor),
                    if (_distanceTo(vendor) != null) _distanceTo(vendor)!
                  ].join(' · ')),
                  trailing: const Icon(Icons.near_me_outlined,
                      color: AppColors.primary),
                  onTap: () => Navigator.pop(context, vendor));
            },
          )),
        ]),
      ),
    );
    if (mounted && selected != null) {
      await _selectVendor(selected);
    }
  }

  Future<void> _showAllDishes(
      List<DishSearchEntry> dishes, Map<String, VendorModel> vendors) async {
    _searchFocus.unfocus();
    final selected = await showModalBottomSheet<DishSearchEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * .72,
        child: Column(children: [
          AppSheetHeader(
              title: Text('${dishes.length} nearby dish results'),
              subtitle: Text('Results for “${_searchController.text.trim()}”')),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: dishes.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 100),
              itemBuilder: (context, index) {
                final dish = dishes[index];
                final vendor = vendors[dish.vendorId]!;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _dishPhoto(dish),
                  title: Text(dish.item.name),
                  subtitle: Text([
                    dish.priceIsKnown
                        ? 'RM ${dish.item.price.toStringAsFixed(2)}'
                        : 'Price unavailable',
                    _stockLabel(dish.item.status),
                    vendor.stallName,
                    if (_distanceTo(vendor) != null) _distanceTo(vendor)!,
                    _stallStatus(vendor),
                  ].join(' · ')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, dish),
                );
              },
            ),
          ),
        ]),
      ),
    );
    if (mounted && selected != null) {
      _openVendorDetails(vendors[selected.vendorId]!,
          dishId: selected.item.itemId);
    }
  }

  void _openVendorDetails(VendorModel vendor, {String? dishId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              VendorDetailsScreen(vendor: vendor, initialDishId: dishId)),
    );
  }
}
````
