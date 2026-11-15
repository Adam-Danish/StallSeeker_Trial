import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/demo_order.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/vendor_payout.dart';
import '../../../core/services/demo_order_service.dart';
import '../../../core/services/vendor_payout_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/widgets/app_page_app_bar.dart';

/// Vendor screen to configure payout bank details and request/track transfers.
class VendorPayoutDetailsScreen extends StatefulWidget {
  const VendorPayoutDetailsScreen({
    super.key,
    this.payoutService,
    this.orderService,
    this.vendorService,
    this.vendorIdOverride,
  });

  final VendorPayoutService? payoutService;
  final DemoOrderService? orderService;
  final VendorService? vendorService;
  final String? vendorIdOverride;

  @override
  State<VendorPayoutDetailsScreen> createState() =>
      _VendorPayoutDetailsScreenState();
}

class _VendorPayoutDetailsScreenState extends State<VendorPayoutDetailsScreen> {
  late final VendorPayoutService _payoutService =
      widget.payoutService ?? VendorPayoutService();
  late final DemoOrderService _orderService =
      widget.orderService ?? DemoOrderService();
  late final VendorService _vendorService =
      widget.vendorService ?? VendorService();

  late final String _uid =
      widget.vendorIdOverride ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  StreamSubscription<VendorPayoutDetails?>? _detailsSub;
  StreamSubscription<List<VendorPayoutRecord>>? _payoutsSub;
  StreamSubscription<List<DemoOrder>>? _ordersSub;
  StreamSubscription<VendorModel?>? _vendorSub;

  VendorPayoutDetails? _details;
  List<VendorPayoutRecord> _payouts = const [];
  List<DemoOrder> _orders = const [];
  VendorModel? _vendor;

  bool _loadingDetails = true;
  bool _loadingPayouts = true;
  bool _loadingOrders = true;
  bool _savingDetails = false;
  bool _requestingPayout = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _detailsSub?.cancel();
    _payoutsSub?.cancel();
    _ordersSub?.cancel();
    _vendorSub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    if (_uid.isEmpty) {
      setState(() {
        _loadingDetails = false;
        _loadingPayouts = false;
        _loadingOrders = false;
        _loadError = 'Sign in to your vendor account to manage payouts.';
      });
      return;
    }

    _detailsSub = _payoutService.watchPayoutDetails(_uid).listen((value) {
      if (!mounted) return;
      setState(() {
        _details = value;
        _loadingDetails = false;
        _loadError = null;
      });
    }, onError: (Object _) {
      if (!mounted) return;
      setState(() {
        _loadingDetails = false;
        _loadError =
            'Could not load your bank details. Check your connection and retry.';
      });
    });

    _payoutsSub = _payoutService.watchVendorPayouts(_uid).listen((value) {
      if (!mounted) return;
      setState(() {
        _payouts = value;
        _loadingPayouts = false;
      });
    }, onError: (Object _) {
      if (!mounted) return;
      setState(() => _loadingPayouts = false);
    });

    _ordersSub = _orderService.watchVendorOrders(_uid).listen((value) {
      if (!mounted) return;
      setState(() {
        _orders = value;
        _loadingOrders = false;
      });
    }, onError: (Object _) {
      if (!mounted) return;
      setState(() => _loadingOrders = false);
    });

    _vendorSub = _vendorService.watchVendorProfile(_uid).listen((value) {
      if (!mounted) return;
      setState(() => _vendor = value);
    });
  }

  Future<void> _saveDetails(VendorPayoutDetails updated) async {
    setState(() => _savingDetails = true);
    try {
      await _payoutService.savePayoutDetails(
        VendorPayoutDetails(
          vendorId: _uid,
          bankName: updated.bankName,
          accountHolderName: updated.accountHolderName,
          accountNumber: updated.accountNumber,
          duitNowId: updated.duitNowId,
          notes: updated.notes,
        ),
      );
      _showMessage('Payout bank details saved.');
    } catch (error) {
      _showMessage(error is ArgumentError
          ? '${error.message}'
          : 'Could not save bank details. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  Future<void> _requestPayout({
    required int amountCents,
    required String vendorNote,
  }) async {
    final details = _details;
    if (details == null || !details.isComplete) {
      _showMessage('Save your bank details first before requesting a payout.');
      return;
    }
    setState(() => _requestingPayout = true);
    try {
      await _payoutService.requestPayout(
        vendorId: _uid,
        stallName: _vendor?.stallName ?? '',
        bankDetails: details,
        amountCents: amountCents,
        vendorNote: vendorNote,
      );
      _showMessage('Payout request sent to admin.');
    } catch (error) {
      _showMessage(error is ArgumentError
          ? '${error.message}'
          : 'Could not submit payout request. Please retry.');
    } finally {
      if (mounted) setState(() => _requestingPayout = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final summary = VendorPayoutBalanceSummary.compute(
      orders: _orders,
      payouts: _payouts,
      vendorId: _uid,
    );
    return VendorPayoutDetailsView(
      loading: _loadingDetails,
      loadingActivity: _loadingOrders || _loadingPayouts,
      savingDetails: _savingDetails,
      requestingPayout: _requestingPayout,
      errorMessage: _loadError,
      details: _details,
      summary: summary,
      payouts: _payouts,
      onRetry: () {
        _detailsSub?.cancel();
        _payoutsSub?.cancel();
        _ordersSub?.cancel();
        _vendorSub?.cancel();
        setState(() {
          _loadingDetails = true;
          _loadingPayouts = true;
          _loadingOrders = true;
          _loadError = null;
        });
        _subscribe();
      },
      onSaveDetails: _saveDetails,
      onRequestPayout: _requestPayout,
    );
  }
}

/// Presentation view for managing vendor bank details and requesting payouts.
class VendorPayoutDetailsView extends StatefulWidget {
  const VendorPayoutDetailsView({
    super.key,
    required this.loading,
    required this.savingDetails,
    required this.requestingPayout,
    required this.details,
    required this.summary,
    required this.payouts,
    required this.onSaveDetails,
    required this.onRequestPayout,
    this.loadingActivity = false,
    this.errorMessage,
    this.onRetry,
  });

  final bool loading;
  final bool loadingActivity;
  final bool savingDetails;
  final bool requestingPayout;
  final String? errorMessage;
  final VendorPayoutDetails? details;
  final VendorPayoutBalanceSummary summary;
  final List<VendorPayoutRecord> payouts;
  final VoidCallback? onRetry;
  final Future<void> Function(VendorPayoutDetails details) onSaveDetails;
  final Future<void> Function({
    required int amountCents,
    required String vendorNote,
  }) onRequestPayout;

  @override
  State<VendorPayoutDetailsView> createState() =>
      _VendorPayoutDetailsViewState();
}

class _VendorPayoutDetailsViewState extends State<VendorPayoutDetailsView> {
  final _formKey = GlobalKey<FormState>();
  final _customBankController = TextEditingController();
  final _holderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _duitNowController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedBank = malaysianPayoutBanks.first;
  String? _seededSnapshot;

  @override
  void initState() {
    super.initState();
    _syncControllersFromDetails();
  }

  @override
  void didUpdateWidget(covariant VendorPayoutDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.details != widget.details) {
      _syncControllersFromDetails();
    }
  }

  void _syncControllersFromDetails() {
    final details = widget.details;
    if (details == null) return;
    final signature = [
      details.bankName,
      details.accountHolderName,
      details.accountNumber,
      details.duitNowId,
      details.notes,
    ].join('|');
    if (_seededSnapshot == signature) return;
    _seededSnapshot = signature;

    if (malaysianPayoutBanks.contains(details.bankName) &&
        details.bankName != 'Other') {
      _selectedBank = details.bankName;
      _customBankController.clear();
    } else if (details.bankName.isNotEmpty) {
      _selectedBank = 'Other';
      _customBankController.text = details.bankName;
    }
    _holderController.text = details.accountHolderName;
    _accountNumberController.text = details.accountNumber;
    _duitNowController.text = details.duitNowId;
    _notesController.text = details.notes;
  }

  @override
  void dispose() {
    _customBankController.dispose();
    _holderController.dispose();
    _accountNumberController.dispose();
    _duitNowController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _effectiveBankName =>
      _selectedBank == 'Other' ? _customBankController.text.trim() : _selectedBank;

  Future<void> _submitBankForm() async {
    if (!_formKey.currentState!.validate()) return;
    final normalizedAccount =
        normalizeBankAccountNumber(_accountNumberController.text) ??
            _accountNumberController.text.trim();
    _accountNumberController.text = normalizedAccount;
    await widget.onSaveDetails(
      VendorPayoutDetails(
        vendorId: widget.details?.vendorId ?? '',
        bankName: _effectiveBankName,
        accountHolderName: _holderController.text.trim(),
        accountNumber: normalizedAccount,
        duitNowId: _duitNowController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  Future<void> _openRequestDialog() async {
    final details = widget.details;
    if (details == null || !details.isComplete) return;
    final availableCents = widget.summary.availableToRequestCents;
    if (availableCents < 100) return;

    final confirmed = await showDialog<({int amountCents, String note})>(
      context: context,
      builder: (_) => _RequestPayoutDialog(
        details: details,
        availableCents: availableCents,
      ),
    );

    if (confirmed != null && mounted) {
      await widget.onRequestPayout(
        amountCents: confirmed.amountCents,
        vendorNote: confirmed.note,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.details?.isComplete == true;
    final canRequest = saved &&
        widget.summary.canRequestPayout &&
        !widget.requestingPayout &&
        !widget.savingDetails;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppPageAppBar(title: Text('Bank & Payouts')),
      body: widget.loading
          ? const Center(child: CircularProgressIndicator())
          : widget.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.errorMessage!, textAlign: TextAlign.center),
                        if (widget.onRetry != null) ...[
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: widget.onRetry,
                            child: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _summaryCard(context, saved: saved, canRequest: canRequest),
                          const SizedBox(height: 16),
                          _bankFormCard(context, saved: saved),
                          const SizedBox(height: 16),
                          _historyCard(context),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required bool saved,
    required bool canRequest,
  }) {
    final s = widget.summary;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payout Balance',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _StatusPill(
                label: saved ? 'Bank Saved' : 'Bank Needed',
                color: saved ? AppColors.openGreen : const Color(0xFF946000),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Customer payments go into StallSeeker’s Stripe merchant account first. Save your bank details below so the platform admin can transfer your earnings via DuitNow or bank transfer.',
              style: TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          const SizedBox(height: 14),
          if (widget.loadingActivity)
            const LinearProgressIndicator()
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricTile(
                  'Live Stripe Sales',
                  formatRinggit(s.liveNetSalesCents),
                  subtitle: '${s.livePaidOrdersCount} paid orders',
                ),
                _metricTile('Paid Out', formatRinggit(s.paidOutCents)),
                _metricTile('Pending Transfer', formatRinggit(s.pendingCents)),
                _metricTile(
                  'Available to Request',
                  formatRinggit(s.availableToRequestCents),
                  highlight: true,
                ),
              ],
            ),
          if (s.testNetSalesCents > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Note: ${formatRinggit(s.testNetSalesCents)} from Stripe Test mode orders is not transferable.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: canRequest ? _openRequestDialog : null,
            icon: widget.requestingPayout
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(
              saved
                  ? s.canRequestPayout
                      ? 'Request Payout (${formatRinggit(s.availableToRequestCents)})'
                      : 'Minimum RM 1.00 needed to request'
                  : 'Save bank details to request payout',
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    String label,
    String value, {
    String? subtitle,
    bool highlight = false,
  }) =>
      Container(
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? AppColors.mint : AppColors.background,
          border: Border.all(
            color: highlight
                ? AppColors.primary.withValues(alpha: .35)
                : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.primary : AppColors.textDark,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ],
        ),
      );

  Widget _bankFormCard(BuildContext context, {required bool saved}) {
    final busy = widget.savingDetails || widget.requestingPayout;
    final updated = widget.details?.updatedAt;
    return _SectionCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payout Bank Account',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (saved && updated != null)
                        Text(
                          'Last updated ${_formatMalaysiaDate(updated)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedBank,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final bank in malaysianPayoutBanks)
                  DropdownMenuItem(
                    value: bank,
                    child: Text(bank, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value != null) setState(() => _selectedBank = value);
                    },
            ),
            if (_selectedBank == 'Other') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customBankController,
                enabled: !busy,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Specify Bank Name',
                  border: OutlineInputBorder(),
                ),
                validator: validateBankName,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _holderController,
              enabled: !busy,
              maxLength: 120,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Account Holder Name',
                hintText: 'Full name or registered business name',
                border: OutlineInputBorder(),
              ),
              validator: validateAccountHolderName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountNumberController,
              enabled: !busy,
              keyboardType: TextInputType.number,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: 'Bank Account Number',
                hintText: 'Digits only (6–24 digits)',
                border: OutlineInputBorder(),
              ),
              validator: validateBankAccountNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _duitNowController,
              enabled: !busy,
              maxLength: 64,
              decoration: const InputDecoration(
                labelText: 'DuitNow ID (Optional)',
                hintText: 'Phone, NRIC, or Business Reg. No.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              enabled: !busy,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes for Admin (Optional)',
                hintText: 'Any payout preference or bank branch reference',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Stored privately. Customers cannot see your bank account details.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: busy ? null : _submitBankForm,
              child: Text(
                widget.savingDetails
                    ? 'Saving…'
                    : saved
                        ? 'Update Bank Details'
                        : 'Save Bank Details',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyCard(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payout History',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.payouts.isEmpty)
            const Text(
              'No payout requests or transfers yet.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            for (final payout in widget.payouts) ...[
              _payoutTile(payout),
              if (payout != widget.payouts.last) const Divider(height: 18),
            ],
        ],
      ),
    );
  }

  Widget _payoutTile(VendorPayoutRecord payout) {
    final (label, color) = switch (payout.status) {
      'paid' => ('Paid', AppColors.openGreen),
      'rejected' => ('Rejected', AppColors.closedRed),
      _ => ('Pending', const Color(0xFF946000)),
    };
    final date = payout.sortTimestamp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                formatRinggit(payout.amountCents),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            _StatusPill(label: label, color: color),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${payout.bankName} · ${maskBankAccountNumber(payout.accountNumber)} (${payout.accountHolderName})',
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        ),
        if (date != null) ...[
          const SizedBox(height: 2),
          Text(
            _formatMalaysiaDate(date),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
        if (payout.transferReference.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Ref: ${payout.transferReference}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.openGreen,
            ),
          ),
        ],
        if (payout.adminNote.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'Admin note: ${payout.adminNote}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
        if (payout.vendorNote.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'Your note: ${payout.vendorNote}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }

  static String _formatMalaysiaDate(DateTime value) {
    final myt = value.toUtc().add(const Duration(hours: 8));
    final mm = myt.minute.toString().padLeft(2, '0');
    final hh = myt.hour.toString().padLeft(2, '0');
    return '${myt.day}/${myt.month}/${myt.year} $hh:$mm MYT';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: .75)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _RequestPayoutDialog extends StatefulWidget {
  const _RequestPayoutDialog({
    required this.details,
    required this.availableCents,
  });

  final VendorPayoutDetails details;
  final int availableCents;

  @override
  State<_RequestPayoutDialog> createState() => _RequestPayoutDialogState();
}

class _RequestPayoutDialogState extends State<_RequestPayoutDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.availableCents / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final availableCents = widget.availableCents;
    return AlertDialog(
      title: const Text('Request Payout'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Transfer to ${details.bankName} (${maskBankAccountNumber(details.accountNumber)}) — ${details.accountHolderName}.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (RM)',
                  helperText:
                      'Available: ${formatRinggit(availableCents)} (min RM 1.00)',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Enter a valid RM amount.';
                  final cents = (parsed * 100).round();
                  if (cents < 100) return 'Minimum payout is RM 1.00.';
                  if (cents > availableCents) {
                    return 'Exceeds available ${formatRinggit(availableCents)}.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLength: 240,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note for admin (optional)',
                  hintText: 'e.g. Daily settlement request',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final parsed = double.parse(_amountController.text.trim());
            Navigator.pop(context, (
              amountCents: (parsed * 100).round(),
              note: _noteController.text.trim(),
            ));
          },
          child: const Text('Send Request'),
        ),
      ],
    );
  }
}
