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
                  menuPadding: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(
                      color: Color(0xFFE5E7EB),
                    ),
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
                        height: 48,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        child: Text(
                          option.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: selected ? _accent : AppColors.textDark,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
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
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    _open ? _accent : const Color(0xFFB8B8B8),
                                width: _open ? 1.5 : 1,
                              ),
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
                                      color: AppColors.textMuted,
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
