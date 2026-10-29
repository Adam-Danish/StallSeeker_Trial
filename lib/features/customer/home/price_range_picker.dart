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
