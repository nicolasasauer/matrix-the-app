import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Horizontal strip with every active player: the current one is highlighted,
/// the next one has a dashed-looking outline.
class PlayerStrip extends StatefulWidget {
  const PlayerStrip({super.key});

  @override
  State<PlayerStrip> createState() => _PlayerStripState();
}

class _PlayerStripState extends State<PlayerStrip> {
  final _keys = <Player, GlobalKey>{};
  Player? _lastCurrent;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final current = provider.currentPlayer;
    final next = provider.nextPlayer;
    final players = provider.players.where((p) => p.active).toList();

    if (current != _lastCurrent) {
      _lastCurrent = current;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[current]?.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(ctx,
              alignment: 0.1, duration: const Duration(milliseconds: 250));
        }
      });
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final p = players[i];
          final isNow = p == current;
          final isNext = p == next && !isNow;
          final key = _keys.putIfAbsent(p, () => GlobalKey());
          return Container(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isNow ? AppColors.fg : AppColors.raised,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isNext ? AppColors.muted : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.player(p.colorIndex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppText.body(12.5,
                          weight: FontWeight.w600,
                          color: isNow ? AppColors.table : AppColors.fg,
                          height: 1.1),
                    ),
                    Text(
                      AppStrings.sipsShort(p.totalPenalty),
                      style: AppText.mono(9.5,
                          color: isNow
                              ? AppColors.table.withValues(alpha: 0.7)
                              : AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Multiplier ("Pegel"), streak and deck status.
class GameHud extends StatelessWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final remaining = provider.engine?.deck.remaining ?? 0;
    final own = provider.inheritedMultiplier;
    final passOn = provider.passOnMultiplier;
    final streak = provider.streakRuleEnabled ? provider.cleanPasses : 0;
    final calls = provider.turnCalls;
    final dots = provider.phase == GamePhase.awaitingDecision ? 3 : calls % 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          Pegel(multiplier: own),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (streak > 0)
                  Text(AppStrings.streakLine(streak),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mono(10.5,
                          weight: 700, color: AppColors.amber)),
                if (passOn != own)
                  Text(AppStrings.passOnLine(passOn),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mono(10.5, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const ShuffleButton(),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$remaining',
                  style: AppText.mono(15, weight: 700, color: AppColors.fg)),
              Text(AppStrings.cardsInDeck,
                  style: AppText.body(10, color: AppColors.muted)),
              const SizedBox(height: 4),
              Semantics(
                label: AppStrings.callsProgress(dots),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: i < dots ? AppColors.ok : AppColors.line,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shuffles the remaining deck with one tap. Gives feedback in place (spin
/// + short label) so nothing covers the action sheet.
class ShuffleButton extends StatefulWidget {
  const ShuffleButton({super.key});

  @override
  State<ShuffleButton> createState() => _ShuffleButtonState();
}

class _ShuffleButtonState extends State<ShuffleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
  bool _justShuffled = false;
  int? _seenShuffles;
  Timer? _labelTimer;

  @override
  void dispose() {
    _labelTimer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  /// Plays the feedback whenever the deck was shuffled – by this button or
  /// automatically after a mistake.
  void _onShuffled() {
    if (context.read<SettingsProvider>().animationsEnabled) {
      _spin.forward(from: 0);
    }
    setState(() => _justShuffled = true);
    _labelTimer?.cancel();
    _labelTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _justShuffled = false);
    });
  }

  void _shuffle() => context.read<GameProvider>().shuffleDeck();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameProvider>();
    final shuffles = p.shuffleCount;
    if (_seenShuffles != null && shuffles > _seenShuffles!) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onShuffled();
      });
    }
    _seenShuffles = shuffles;
    final enabled = (p.engine?.deck.remaining ?? 0) > 1 &&
        p.phase != GamePhase.gameOver &&
        p.phase != GamePhase.matrixFull;
    return Tooltip(
      message: AppStrings.shuffleDeck,
      child: Material(
        color: AppColors.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? _shuffle : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: CurvedAnimation(parent: _spin, curve: Curves.easeOut),
                  child: Icon(Icons.shuffle,
                      size: 18,
                      color: enabled ? AppColors.fg : AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  _justShuffled ? AppStrings.shuffled : AppStrings.shuffle,
                  style: AppText.body(9.5,
                      weight: FontWeight.w600,
                      color: _justShuffled ? AppColors.ok : AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Beer-glass badge showing the multiplier the current player plays with.
class Pegel extends StatelessWidget {
  final int multiplier;
  final String label;

  const Pegel(
      {super.key, required this.multiplier, this.label = 'dein\nPegel'});

  @override
  Widget build(BuildContext context) {
    final fill = (multiplier / 5).clamp(0.2, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        border: Border.all(color: AppColors.amber),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 22,
            child: CustomPaint(painter: _GlassPainter(fill)),
          ),
          const SizedBox(width: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(end: multiplier.toDouble()),
            duration: const Duration(milliseconds: 300),
            builder: (_, v, __) => Text('${v.round()}x',
                style: AppText.display(22, color: AppColors.amber)),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: AppText.body(9.5, color: AppColors.muted, height: 1.15)),
        ],
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double fill;
  _GlassPainter(this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: const Radius.circular(2),
      topRight: const Radius.circular(2),
      bottomLeft: const Radius.circular(5),
      bottomRight: const Radius.circular(5),
    );
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * (1 - fill), size.width, size.height),
      Paint()..color = AppColors.amber,
    );
    canvas.restore();
    canvas.drawRRect(
      r.deflate(1),
      Paint()
        ..color = AppColors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.fill != fill;
}
