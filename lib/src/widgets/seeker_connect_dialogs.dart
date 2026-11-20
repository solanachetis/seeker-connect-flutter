import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../errors.dart';
import '../events.dart';
import '../seeker_connect.dart';
import '../strings.dart';

/// Shows the Seeker Connect progress and error cards over [child] while a
/// wallet interaction runs. Place it once around the app, e.g. in
/// `MaterialApp.builder`. Closing the progress card cancels the interaction.
///
/// Shows nothing when the config's `showDialogs` is false.
class SeekerConnectDialogs extends StatefulWidget {
  const SeekerConnectDialogs({
    super.key,
    required this.child,
    this.strings = const SeekerConnectStrings(),
    this.brightness,
  });

  final Widget child;
  final SeekerConnectStrings strings;

  /// Defaults to the ambient `MediaQuery` platform brightness.
  final Brightness? brightness;

  @override
  State<SeekerConnectDialogs> createState() => _SeekerConnectDialogsState();
}

class _SeekerConnectDialogsState extends State<SeekerConnectDialogs> {
  StreamSubscription<SeekerInteractionEvent>? _subscription;
  int? _progressId;
  SeekerConnectErrorCode? _error;

  @override
  void initState() {
    super.initState();
    _subscription = SeekerConnect.interactions.listen(_onEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onEvent(SeekerInteractionEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event) {
        case SeekerInteractionStarted(:final id):
          _progressId = id;
          _error = null;
        case SeekerInteractionSettled(:final id):
          if (_progressId == id) _progressId = null;
        case SeekerInteractionFailed(:final code):
          _progressId = null;
          _error = code;
      }
    });
  }

  void _close() {
    final id = _progressId;
    setState(() {
      _progressId = null;
      _error = null;
    });
    if (id != null) SeekerConnect.cancelInteraction(id);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = SeekerConnect.config?.showDialogs ?? true;
    final error = _error;
    final Widget? card;
    if (!enabled) {
      card = null;
    } else if (_progressId != null) {
      card = _Card(
        title: widget.strings.progressTitle,
        body: widget.strings.progressBody,
        closeLabel: widget.strings.close,
        dark: _dark(context),
        onClose: _close,
        icon: (color) => _Spinner(color: color),
      );
    } else if (error != null) {
      final (title, body) = widget.strings.error(error);
      card = _Card(
        title: title,
        body: body,
        closeLabel: widget.strings.close,
        dark: _dark(context),
        onClose: _close,
        icon: (color) => _ErrorMark(color: color),
      );
    } else {
      card = null;
    }

    return Stack(
      children: [
        widget.child,
        if (card != null) ...[
          const Positioned.fill(child: ColoredBox(color: Color(0x99000000))),
          Positioned.fill(
            child: Padding(
              padding: MediaQuery.maybePaddingOf(context) ?? EdgeInsets.zero,
              child: Center(child: Padding(padding: const EdgeInsets.all(24), child: card)),
            ),
          ),
        ],
      ],
    );
  }

  bool _dark(BuildContext context) =>
      (widget.brightness ?? MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light) == Brightness.dark;
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.body,
    required this.closeLabel,
    required this.dark,
    required this.onClose,
    required this.icon,
  });

  final String title;
  final String body;
  final String closeLabel;
  final bool dark;
  final VoidCallback onClose;
  final Widget Function(Color color) icon;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 352),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F6F6),
            border: Border.all(color: dark ? const Color(0xFF2D2D2D) : const Color(0xFFABACAC)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 96, child: Center(child: icon(foreground))),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: foreground, fontSize: 20, height: 1.3, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6C6C6C),
                        fontSize: 14,
                        height: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      onTap: onClose,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 160, minHeight: 42),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          border: Border.all(color: foreground),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          closeLabel,
                          style: TextStyle(color: foreground, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
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
}

class _Spinner extends StatefulWidget {
  const _Spinner({required this.color});
  final Color color;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _controller,
        child: CustomPaint(size: const Size(56, 56), painter: _ArcPainter(widget.color)),
      );
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Offset.zero & size, 0, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}

class _ErrorMark extends StatelessWidget {
  const _ErrorMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(56, 56), painter: _CrossPainter(color));
}

class _CrossPainter extends CustomPainter {
  _CrossPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawCircle(size.center(Offset.zero), size.width / 2 - 2, paint)
      ..drawLine(Offset(size.width * .35, size.height * .35), Offset(size.width * .65, size.height * .65), paint)
      ..drawLine(Offset(size.width * .65, size.height * .35), Offset(size.width * .35, size.height * .65), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter oldDelegate) => oldDelegate.color != color;
}
