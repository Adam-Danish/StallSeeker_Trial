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
