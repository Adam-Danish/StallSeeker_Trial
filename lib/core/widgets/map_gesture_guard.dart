import 'package:flutter/material.dart';

/// Platform maps can receive browser events behind Flutter routes and sheets.
/// Block both Flutter hit testing and the map's own gesture handling.
class MapGestureGuard extends StatelessWidget {
  const MapGestureGuard({
    super.key,
    required this.blocked,
    required this.builder,
  });

  final bool blocked;
  final Widget Function(BuildContext context, bool blocked) builder;

  @override
  Widget build(BuildContext context) {
    final gesturesBlocked = blocked || ModalRoute.isCurrentOf(context) == false;
    return AbsorbPointer(
      absorbing: gesturesBlocked,
      child: builder(context, gesturesBlocked),
    );
  }
}
