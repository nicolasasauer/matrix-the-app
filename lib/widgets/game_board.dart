import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';

import '../domain/models.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'card_face.dart';

/// The 5×5 table. Cells are card-shaped and always sized so the whole board
/// fits into the available space – it never scrolls.
class GameBoard extends StatelessWidget {
  /// Dims the board, e.g. while the decision sheet is open.
  final bool dimmed;

  const GameBoard({super.key, this.dimmed = false});

  static const double _gap = 6;
  static const double _cardRatio = 1.25; // height / width

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final engine = provider.engine;
    if (engine == null) return const SizedBox();

    final validPositions = engine.validPositions.toSet();
    final selected = provider.selectedPosition;
    final phase = provider.phase;
    final canPick =
        phase == GamePhase.selectingPosition || phase == GamePhase.makingGuess;
    final showRisk = selected != null &&
        (phase == GamePhase.makingGuess || phase == GamePhase.showingFailure);

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final cellW = math.max(
          0.0, math.min((w - 4 * _gap) / 5, ((h - 4 * _gap) / 5) / _cardRatio));
      final cellH = cellW * _cardRatio;

      return Center(
        child: AnimatedOpacity(
          opacity: dimmed ? 0.35 : 1,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: cellW * 5 + _gap * 4,
            height: cellH * 5 + _gap * 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (col) {
                    final pos = Position(row, col);
                    final card = engine.getCard(pos);
                    final isSlot = canPick && validPositions.contains(pos);
                    final inRisk = showRisk &&
                        (row == selected.row || col == selected.col);
                    return SizedBox(
                      width: cellW,
                      height: cellH,
                      child: _Cell(
                        card: card,
                        isSlot: isSlot,
                        neighborCount: isSlot
                            ? engine.getOrthogonalNeighbors(pos).length
                            : 0,
                        isSelected:
                            selected == pos && phase == GamePhase.makingGuess,
                        isNucleus: row == 2 && col == 2,
                        inRisk: inRisk,
                        onTap:
                            isSlot ? () => provider.selectPosition(pos) : null,
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
      );
    });
  }
}

class _Cell extends StatefulWidget {
  final Card? card;
  final bool isSlot;
  final int neighborCount;
  final bool isSelected;
  final bool isNucleus;
  final bool inRisk;
  final VoidCallback? onTap;

  const _Cell({
    required this.card,
    required this.isSlot,
    required this.neighborCount,
    required this.isSelected,
    required this.isNucleus,
    required this.inRisk,
    this.onTap,
  });

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> with TickerProviderStateMixin {
  late final AnimationController _flip;
  late final AnimationController _pulse;

  /// Keeps the card visible while it fades out after being cleared.
  Card? _displayCard;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    if (widget.card != null) {
      _displayCard = widget.card;
      _flip.value = 1;
    }
    _syncPulse();
  }

  bool get _animations => context.read<SettingsProvider>().animationsEnabled;

  void _syncPulse() {
    if (widget.isSelected && _animations) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void didUpdateWidget(_Cell old) {
    super.didUpdateWidget(old);
    final anim = _animations;
    if (old.card == null && widget.card != null) {
      _displayCard = widget.card;
      anim ? _flip.forward(from: 0) : _flip.value = 1;
    } else if (old.card != null && widget.card == null) {
      if (anim) {
        _flip.reverse().whenComplete(() {
          if (mounted) setState(() => _displayCard = null);
        });
      } else {
        _flip.value = 0;
        _displayCard = null;
      }
    } else if (widget.card != null) {
      _displayCard = widget.card;
    }
    if (old.isSelected != widget.isSelected) _syncPulse();
  }

  @override
  void dispose() {
    _flip.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = _displayCard ?? widget.card;
    final radius = BorderRadius.circular(7);

    Widget child;
    if (card != null) {
      child = AnimatedBuilder(
        animation: _flip,
        builder: (context, child) {
          final t = _flip.value.clamp(0.0, 1.0);
          final angle = (1 - Curves.easeOut.transform(t)) * (math.pi / 2);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Opacity(opacity: t, child: child),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: radius,
            boxShadow: [
              if (widget.inRisk)
                const BoxShadow(color: AppColors.danger, spreadRadius: 2.5)
              else if (widget.isNucleus)
                const BoxShadow(color: AppColors.amber, spreadRadius: 2),
              const BoxShadow(color: Colors.black38, offset: Offset(0, 2)),
            ],
          ),
          child: CardFace(card: card),
        ),
      );
    } else if (widget.isSelected) {
      child = AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.fg.withValues(alpha: 0.08 + 0.12 * _pulse.value),
            borderRadius: radius,
            border: Border.all(color: AppColors.fg, width: 2),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text('?', style: AppText.display(26)),
            ),
          ),
        ),
      );
    } else if (widget.isSlot) {
      child = CustomPaint(
        painter: _DashedRectPainter(
          color: widget.inRisk ? Colors.transparent : AppColors.line,
          fill: widget.inRisk ? AppColors.dangerSoft : null,
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text('${widget.neighborCount}',
                style: AppText.mono(9, color: AppColors.muted)),
          ),
        ),
      );
    } else {
      child = DecoratedBox(
        decoration: BoxDecoration(
          color: widget.inRisk
              ? AppColors.dangerSoft
              : AppColors.raised.withValues(alpha: 0.25),
          borderRadius: radius,
        ),
      );
    }

    return Semantics(
      button: widget.onTap != null,
      label: card != null
          ? cardName(card)
          : widget.isSlot
              ? 'Freies Feld, ${widget.neighborCount} Nachbarn'
              : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final Color? fill;

  _DashedRectPainter({required this.color, this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7));
    if (fill != null) {
      canvas.drawRRect(rrect, Paint()..color = fill!);
    }
    if (color.a == 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect.deflate(0.75));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color || old.fill != fill;
}
