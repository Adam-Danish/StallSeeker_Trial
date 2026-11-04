import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/models/vendor_model.dart';
import '../../core/services/moderation_service.dart';
import '../../core/utils/booking_request_key.dart';
import '../auth/screens/login_screen.dart';

class ReportStallScreen extends StatefulWidget {
  const ReportStallScreen({super.key, required this.vendor});
  final VendorModel vendor;
  @override
  State<ReportStallScreen> createState() => _ReportStallScreenState();
}

class _ReportStallScreenState extends State<ReportStallScreen> {
  final _form = GlobalKey<FormState>();
  final _details = TextEditingController();
  final _service = ModerationService();
  final _requestKey = newBookingRequestKey();
  String _reason = reportReasons.keys.first;
  DateTime _observedAt = DateTime.now();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _chooseTime() async {
    final now = DateTime.now();
    final day = await showDatePicker(
        context: context,
        initialDate: _observedAt,
        firstDate: now.subtract(const Duration(days: 29)),
        lastDate: now);
    if (day == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_observedAt));
    if (time == null || !mounted) return;
    setState(() => _observedAt =
        DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_observedAt.isAfter(DateTime.now())) {
      setState(() => _error = 'The observation time cannot be in the future.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.submitReport(
          vendorId: widget.vendor.vendorId,
          reason: _reason,
          details: _details.text.trim(),
          observedAt: _observedAt,
          requestKey: _requestKey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report sent for admin review.')));
      await Navigator.pushReplacement(context,
          MaterialPageRoute<void>(builder: (_) => const ModerationScreen()));
    } catch (error) {
      if (mounted) setState(() => _error = moderationError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final verified = user != null && !user.isAnonymous && user.emailVerified;
    return Scaffold(
      appBar: AppBar(title: const Text('Report this stall'), actions: [
        IconButton(
            tooltip: 'My reports',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const ModerationScreen()))),
      ]),
      body: !verified
          ? _AccessNotice(
              onLogin: user == null || user.isAnonymous
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen()))
                  : null)
          : Center(
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                  key: _form,
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    Text(widget.vendor.stallName,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    const Text(
                        'Tell the admin which information did not match your visit. Reports are private and checked before any warning is issued. Each customer can report a stall once every 30 days.'),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: _reason,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'Reason', border: OutlineInputBorder()),
                      items: reportReasons.entries
                          .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _reason = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _details,
                        enabled: !_saving,
                        maxLines: 5,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                            labelText: 'What was incorrect?',
                            hintText:
                                'Describe what the app showed and what you found.',
                            border: OutlineInputBorder()),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Please explain what was incorrect.'
                                : null),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('When did you notice this?'),
                        subtitle: Text(moderationTime(_observedAt)),
                        trailing: const Icon(Icons.edit_calendar),
                        onTap: _saving ? null : _chooseTime),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                              semanticsLabel: _error)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.flag_outlined),
                        label: Text(_saving ? 'Sending…' : 'Submit report')),
                  ])),
            )),
    );
  }
}

class VendorModerationBanner extends StatefulWidget {
  const VendorModerationBanner({super.key, required this.vendorId});
  final String vendorId;
  @override
  State<VendorModerationBanner> createState() => _VendorModerationBannerState();
}

class _VendorModerationBannerState extends State<VendorModerationBanner> {
  late Stream<List<ModerationRecord>> _cases;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(VendorModerationBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendorId != widget.vendorId) _listen();
  }

  void _listen() {
    _cases = ModerationService().vendorCases(widget.vendorId);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ModerationRecord>>(
      stream: _cases,
      builder: (context, snapshot) {
        final active =
            (snapshot.data ?? []).where((record) => record.active).toList();
        return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Icon(active.isEmpty
                  ? Icons.fact_check_outlined
                  : Icons.warning_amber_rounded),
              title: Text(snapshot.hasError
                  ? 'Could not load admin notices'
                  : active.isEmpty
                      ? 'Admin notices & warning history'
                      : active.first.status == 'suspended'
                          ? 'Your listing is suspended'
                          : 'Admin warning: correction required'),
              subtitle: snapshot.hasError
                  ? const Text(
                      'Open to retry. Notices may be unavailable while offline.')
                  : active.isEmpty
                      ? null
                      : Text(
                          'Deadline: ${moderationTime(active.first.date('dueAt'))}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const ModerationScreen(isVendor: true))),
            ));
      });
}

class ModerationScreen extends StatefulWidget {
  const ModerationScreen(
      {super.key, this.isVendor = false, this.initialCaseId});
  final bool isVendor;
  final String? initialCaseId;
  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  final _service = ModerationService();
  Stream<List<ModerationRecord>>? _stream;
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    _listen();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _listen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) {
      return;
    }
    _stream = widget.isVendor
        ? _service.vendorCases(user.uid)
        : _service.customerReports(user.uid);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.isVendor ? 'Admin notices' : 'My reports')),
        body: _stream == null
            ? const _AccessNotice()
            : StreamBuilder<List<ModerationRecord>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          'Could not load records. Check your connection.'),
                      TextButton(
                          onPressed: () => setState(_listen),
                          child: const Text('Retry')),
                    ]));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final records = [...snapshot.data!];
                  records.sort((a, b) {
                    if (a.id == widget.initialCaseId) {
                      return -1;
                    }
                    if (b.id == widget.initialCaseId) {
                      return 1;
                    }
                    return (b.date('createdAt') ?? DateTime(1970))
                        .compareTo(a.date('createdAt') ?? DateTime(1970));
                  });
                  if (records.isEmpty) {
                    return Center(
                        child: Text(widget.isVendor
                            ? 'No admin notices.'
                            : 'No reports submitted.'));
                  }
                  return Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text(
                                        'Showing the latest 100 records.')),
                                for (final record in records)
                                  ModerationRecordCard(
                                      record: record,
                                      isVendor: widget.isVendor),
                              ])));
                }),
      );
}

class ModerationRecordCard extends StatelessWidget {
  const ModerationRecordCard(
      {super.key, required this.record, required this.isVendor});
  final ModerationRecord record;
  final bool isVendor;
  @override
  Widget build(BuildContext context) {
    final data = record.data;
    final status =
        record.overdue ? 'Overdue — admin review required' : record.status;
    return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.stallName,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(status.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Created: ${moderationTime(record.date('createdAt'))}'),
              if (isVendor) ...[
                Text(
                    'Correction deadline: ${moderationTime(record.date('dueAt'))}'),
                const SizedBox(height: 12),
                for (final summary in (data['summaries'] as List? ?? []))
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                          '${reportReasons[summary['reason']] ?? summary['reason']}: ${summary['details']}')),
                if (record.status == 'suspended')
                  const Text(
                      'Your stall is hidden and cannot receive new bookings. You can still edit details and manage existing orders.'),
                if (data['vendorResponse'] != null) ...[
                  const Divider(),
                  Text('Your response: ${data['vendorResponse']}'),
                  Text('Review status: ${data['responseStatus']}'),
                ],
              ] else ...[
                const SizedBox(height: 8),
                Text(reportReasons[data['reason']] ?? 'Report'),
                Text(data['details'] as String? ?? ''),
                Text('Observed: ${moderationTime(record.date('observedAt'))}'),
              ],
              if (data['adminReason'] != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Admin: ${data['adminReason']}')),
              if (isVendor && record.active) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Submit correction or dispute'),
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _CorrectionDialog(caseId: record.id))),
              ],
            ])));
  }
}

class _CorrectionDialog extends StatefulWidget {
  const _CorrectionDialog({required this.caseId});
  final String caseId;
  @override
  State<_CorrectionDialog> createState() => _CorrectionDialogState();
}

class _CorrectionDialogState extends State<_CorrectionDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  final _requestKey = newBookingRequestKey();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ModerationService()
          .submitCorrection(widget.caseId, _note.text.trim(), _requestKey);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = moderationError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Correction or dispute'),
        content: SingleChildScrollView(
            child: Form(
                key: _form,
                child: SizedBox(
                    width: 480,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'Update your stall details first, then explain the correction or why you disagree. An admin must approve it. The original deadline remains in effect.'),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: _note,
                              enabled: !_saving,
                              maxLength: 1000,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                  labelText: 'Your response',
                                  border: OutlineInputBorder()),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Please enter a response.'
                                      : null),
                          if (_error != null)
                            Text(_error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                        ])))),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Sending…' : 'Submit for review')),
        ],
      );
}

class _AccessNotice extends StatelessWidget {
  const _AccessNotice({this.onLogin});
  final VoidCallback? onLogin;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
                'Sign in with a verified account to view or submit reports.',
                textAlign: TextAlign.center),
            if (onLogin != null)
              TextButton(onPressed: onLogin, child: const Text('Sign in')),
          ])));
}
