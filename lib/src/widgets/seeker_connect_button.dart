import 'package:flutter/widgets.dart';

import 'brand_glyph.dart';

/// Which label [SeekerConnectButton] shows.
enum SeekerConnectButtonVariant {
  connect('Connect with Seeker'),
  signIn('Sign in with Seeker');

  const SeekerConnectButtonVariant(this.label);
  final String label;
}

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);
const _disabledAlpha = 0.4;

/// The "Connect with Seeker" / "Sign in with Seeker" button, matching the
/// official Seeker Connect button: 56 high, up to 368 wide, 16 corner radius,
/// black on a light screen and white on a dark one.
class SeekerConnectButton extends StatelessWidget {
  const SeekerConnectButton({
    super.key,
    required this.onPressed,
    this.variant = SeekerConnectButtonVariant.connect,
    this.enabled = true,
    this.brightness,
  });

  final VoidCallback? onPressed;
  final SeekerConnectButtonVariant variant;
  final bool enabled;

  /// The screen's scheme; defaults to the ambient `MediaQuery` platform brightness.
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final dark = (brightness ?? MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light) == Brightness.dark;
    final active = enabled && onPressed != null;
    var background = dark ? _white : _black;
    var foreground = dark ? _black : _white;
    if (!active) {
      background = background.withValues(alpha: _disabledAlpha);
      foreground = foreground.withValues(alpha: _disabledAlpha);
    }

    return Semantics(
      button: true,
      enabled: active,
      label: variant.label,
      onTap: active ? onPressed : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: active,
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onPressed?.call())},
        child: GestureDetector(
          onTap: active ? onPressed : null,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 368, minHeight: 56, maxHeight: 56),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 19),
                      child: CustomPaint(size: const Size(18.2, 24), painter: _GlyphPainter(foreground)),
                    ),
                    Flexible(
                      child: Text(
                        variant.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: foreground, fontSize: 20, fontWeight: FontWeight.w500),
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

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.color);

  final Color color;
  static final Path _path = sGlyphPath();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / sGlyphViewBox.width, size.height / sGlyphViewBox.height)
      ..translate(-sGlyphViewBox.left, -sGlyphViewBox.top)
      ..drawPath(_path, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.color != color;
}
