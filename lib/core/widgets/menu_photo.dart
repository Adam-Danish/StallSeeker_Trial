import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import 'app_page_app_bar.dart';

/// The same photo entry point is used by customers and vendors.
class MenuPhotoThumbnail extends StatelessWidget {
  const MenuPhotoThumbnail({
    super.key,
    required this.imageUrl,
    required this.dishName,
  });

  final String imageUrl;
  final String dishName;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = imageUrl.isNotEmpty;
    return SizedBox.square(
      dimension: 88,
      child: Semantics(
        button: hasPhoto,
        label: hasPhoto ? 'View photo of $dishName' : 'No photo of $dishName',
        child: Tooltip(
          message: hasPhoto ? 'View larger photo' : 'No photo available',
          child: Material(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: !hasPhoto
                  ? null
                  : () => Navigator.of(context).push<void>(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => MenuPhotoViewer(
                            imageUrl: imageUrl, dishName: dishName),
                      )),
              child: ExcludeSemantics(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPhoto)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined),
                      )
                    else
                      const Icon(Icons.restaurant, size: 32),
                    if (hasPhoto)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Icon(Icons.open_in_full,
                                color: Colors.white, size: 16),
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
    );
  }
}

class MenuPhotoViewer extends StatefulWidget {
  const MenuPhotoViewer({
    super.key,
    required this.imageUrl,
    required this.dishName,
  });

  final String imageUrl;
  final String dishName;

  @override
  State<MenuPhotoViewer> createState() => _MenuPhotoViewerState();
}

class _MenuPhotoViewerState extends State<MenuPhotoViewer> {
  final _transform = TransformationController();
  final _focus = FocusNode();
  Size _viewport = Size.zero;
  Offset _doubleTapPosition = Offset.zero;
  int _imageAttempt = 0;
  static const _maxScale = 5.0;

  double get _scale => _transform.value.getMaxScaleOnAxis();

  @override
  void dispose() {
    _transform.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _reset() => _transform.value = Matrix4.identity();

  void _zoom(double factor, [Offset? focalPoint]) {
    final next = (_scale * factor).clamp(1.0, _maxScale);
    if (next == 1) {
      _reset();
      return;
    }
    final focal = focalPoint ?? _viewport.center(Offset.zero);
    final scene = _transform.toScene(focal);
    _transform.value = Matrix4.identity()
      ..setEntry(0, 0, next)
      ..setEntry(1, 1, next)
      ..setEntry(0, 3,
          (focal.dx - scene.dx * next).clamp(_viewport.width * (1 - next), 0.0))
      ..setEntry(
          1,
          3,
          (focal.dy - scene.dy * next)
              .clamp(_viewport.height * (1 - next), 0.0));
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(primary: AppColors.logoOrange),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.maybePop(context),
            const SingleActivator(LogicalKeyboardKey.equal): () => _zoom(1.5),
            const SingleActivator(LogicalKeyboardKey.equal, shift: true): () =>
                _zoom(1.5),
            const SingleActivator(LogicalKeyboardKey.numpadAdd): () =>
                _zoom(1.5),
            const SingleActivator(LogicalKeyboardKey.minus): () =>
                _zoom(1 / 1.5),
            const SingleActivator(LogicalKeyboardKey.numpadSubtract): () =>
                _zoom(1 / 1.5),
            const SingleActivator(LogicalKeyboardKey.digit0): _reset,
          },
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            child: Scaffold(
              appBar: AppPageAppBar(
                showBackButton: false,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(widget.dishName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: [
                  IconButton(
                    tooltip: 'Close photo',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                        final viewport = constraints.biggest;
                        if (_viewport != viewport) {
                          // Resizing a browser or rotating a phone returns to fit.
                          final hadViewport = _viewport != Size.zero;
                          _viewport = viewport;
                          if (hadViewport) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _reset();
                            });
                          }
                        }
                        return GestureDetector(
                          onTap: _focus.requestFocus,
                          onDoubleTapDown: (details) =>
                              _doubleTapPosition = details.localPosition,
                          onDoubleTap: () => _scale > 1
                              ? _reset()
                              : _zoom(2.5, _doubleTapPosition),
                          child: InteractiveViewer(
                            transformationController: _transform,
                            minScale: 1,
                            maxScale: _maxScale,
                            trackpadScrollCausesScale: true,
                            child: SizedBox.expand(
                              child: Image.network(
                                widget.imageUrl,
                                key: ValueKey(_imageAttempt),
                                fit: BoxFit.contain,
                                semanticLabel: 'Photo of ${widget.dishName}',
                                loadingBuilder: (_, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                            child: CircularProgressIndicator(
                                                color: Colors.white)),
                                errorBuilder: (_, __, ___) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.broken_image_outlined,
                                          size: 40),
                                      const SizedBox(height: 12),
                                      const Text('Could not load photo.'),
                                      TextButton.icon(
                                        onPressed: () {
                                          _reset();
                                          setState(() => _imageAttempt++);
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Pinch or scroll to zoom · Drag to move',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<Matrix4>(
                            valueListenable: _transform,
                            builder: (context, matrix, _) {
                              final scale = matrix.getMaxScaleOnAxis();
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'Zoom out',
                                    onPressed: scale <= 1.001
                                        ? null
                                        : () => _zoom(1 / 1.5),
                                    icon: const Icon(Icons.remove),
                                  ),
                                  SizedBox(
                                    width: 64,
                                    child: Text('${(scale * 100).round()}%',
                                        textAlign: TextAlign.center),
                                  ),
                                  IconButton(
                                    tooltip: 'Zoom in',
                                    onPressed: scale >= _maxScale - 0.001
                                        ? null
                                        : () => _zoom(1.5),
                                    icon: const Icon(Icons.add),
                                  ),
                                  TextButton(
                                    onPressed: _reset,
                                    child: const Text('Fit'),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
