import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Plays a short "cards back into the deck, riffle, done" animation after a
/// mistake. It never blocks taps. With animations turned off only the label
/// is shown briefly.
class ReshuffleAnimation extends StatefulWidget {
  const ReshuffleAnimation({super.key});

  @override
  State<ReshuffleAnimation> createState() => _ReshuffleAnimationState();
}

class _ReshuffleAnimationState extends State<ReshuffleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  int? _seen;
  int _count = 0;
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _play(int count) {
    _count = count;
    final animate = context.read<SettingsProvider>().animationsEnabled;
    setState(() => _visible = true);
    if (animate) {
      _c.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _visible = false);
      });
    } else {
      _c.value = 0.5; // static, fully visible frame
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameProvider>();
    final returns = p.returnCount;
    if (_seen != null && returns > _seen! && p.lastReturnedCount > 0) {
      final n = p.lastReturnedCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play(n);
      });
    }
    _seen = returns;

    if (!_visible) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => _Frame(t: _c.value, count: _count),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  final double t; // 0 → 1
  final int count;

  const _Frame({required this.t, required this.count});

  static double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final cards = count.clamp(2, 7);
    final flyIn = Curves.easeOutCubic.transform(_seg(t, 0, 0.22));
    final riffle = _seg(t, 0.22, 0.78);
    final out = Curves.easeInCubic.transform(_seg(t, 0.8, 1));
    final opacity = (math.min(_seg(t, 0, 0.12), 1 - out)).clamp(0.0, 1.0);
    // Riffle amplitude rises and falls so the stack ends up square again.
    final amp = math.sin(riffle * math.pi) * 52;

    return Opacity(
      opacity: opacity,
      child: Container(
        color: AppColors.ink.withValues(alpha: 0.45 * opacity),
        alignment: Alignment.center,
        child: Transform.translate(
          // At the end the stack slides up towards the deck counter.
          offset: Offset(out * 120, -out * 220),
          child: Transform.scale(
            scale: 1 - 0.5 * out,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < cards; i++)
                        _placed(i, cards, flyIn, riffle, amp),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.raised,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shuffle,
                          size: 16, color: AppColors.amber),
                      const SizedBox(width: 8),
                      Text(AppStrings.cardsReturned(count),
                          style: AppText.body(13, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placed(int i, int n, double flyIn, double riffle, double amp) {
    // Start positions: spread out like the cleared row/column.
    final angle = (i / n) * 2 * math.pi;
    final start = Offset(math.cos(angle) * 140, math.sin(angle) * 90 - 40);
    final side = i.isEven ? 1.0 : -1.0;
    // Two riffle passes: halves split left/right and interleave.
    final wave = math.sin(riffle * math.pi * 4) * side;
    // Halves split apart, then cards interleave back towards the middle.
    final x = start.dx * (1 - flyIn) + side * amp * 0.7 + wave * amp * 0.3;
    final y = start.dy * (1 - flyIn) - i * 1.5;
    final rot = (1 - flyIn) * (side * 0.6) + wave * 0.08;
    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(angle: rot, child: const CardBack()),
    );
  }
}

/// Back side of a playing card in the app's colours.
class CardBack extends StatelessWidget {
  final double width;
  const CardBack({super.key, this.width = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(
        color: AppColors.raised,
        borderRadius: BorderRadius.circular(width * 0.14),
        border: Border.all(color: AppColors.amber, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: EdgeInsets.all(width * 0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.08),
        child: CustomPaint(painter: _BackPattern()),
      ),
    );
  }
}

class _BackPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.amber.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const step = 7.0;
    for (double d = -size.height; d < size.width; d += step) {
      canvas.drawLine(
          Offset(d, 0), Offset(d + size.height, size.height), paint);
      canvas.drawLine(
          Offset(d + size.height, 0), Offset(d, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_BackPattern oldDelegate) => false;
}
