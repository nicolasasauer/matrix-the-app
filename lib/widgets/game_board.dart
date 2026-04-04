import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import '../domain/models.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import 'card_face.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final engine = provider.engine;
    if (engine == null) return const SizedBox();

    final validPositions = engine.validPositions;
    final selectedPos = provider.selectedPosition;
    final isFailure = provider.phase == GamePhase.showingFailure;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Square board that always fits the available space without scrolling.
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                final row = index ~/ 5;
                final col = index % 5;
                final pos = Position(row, col);
                final card = engine.getCard(pos);
                final isValid =
                    validPositions.contains(pos) && provider.canInteract;
                final isSelected = selectedPos == pos;
                final isNucleus = row == 2 && col == 2;
                final isFailureCell = isFailure &&
                    selectedPos != null &&
                    (row == selectedPos.row || col == selectedPos.col);

                return _CardCell(
                  card: card,
                  isValid: isValid,
                  isSelected: isSelected,
                  isNucleus: isNucleus,
                  isFailureCell: isFailureCell,
                  isFailureOrigin: isFailure && pos == selectedPos,
                  onTap: isValid &&
                          provider.phase == GamePhase.selectingPosition
                      ? () => provider.selectPosition(pos)
                      : null,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CardCell extends StatefulWidget {
  final Card? card;
  final bool isValid;
  final bool isSelected;
  final bool isNucleus;
  final bool isFailureCell;
  final bool isFailureOrigin;
  final VoidCallback? onTap;

  const _CardCell({
    required this.card,
    required this.isValid,
    required this.isSelected,
    required this.isNucleus,
    this.isFailureCell = false,
    this.isFailureOrigin = false,
    this.onTap,
  });

  @override
  State<_CardCell> createState() => _CardCellState();
}

class _CardCellState extends State<_CardCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Retains the card reference during the fade-out so it can still be
  /// rendered while the removal animation is playing.
  Card? _displayCard;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.card != null) {
      _displayCard = widget.card;
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_CardCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final animEnabled =
        context.read<SettingsProvider>().animationsEnabled;

    if (oldWidget.card == null && widget.card != null) {
      // A new card was placed: flip in.
      _displayCard = widget.card;
      if (animEnabled) {
        _controller.forward(from: 0.0);
      } else {
        _controller.value = 1.0;
      }
    } else if (oldWidget.card != null && widget.card == null) {
      // Card was removed (row/column cleared): fade out.
      if (animEnabled) {
        _controller.reverse().whenComplete(() {
          if (mounted) setState(() => _displayCard = null);
        });
      } else {
        _controller.value = 0.0;
        _displayCard = null;
      }
    } else if (widget.card != null) {
      _displayCard = widget.card;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use _displayCard so the cell can still render during fade-out.
    final hasCard = _displayCard != null || widget.card != null;

    final Color bgColor;
    final Color borderColor;

    if (widget.isFailureOrigin) {
      bgColor = Colors.red.shade900;
      borderColor = Colors.red;
    } else if (widget.isFailureCell) {
      bgColor = const Color(0xFF5C1010);
      borderColor = Colors.red.shade700;
    } else if (hasCard) {
      bgColor = widget.isNucleus
          ? const Color(0xFF533483)
          : const Color(0xFF0F3460);
      borderColor = widget.isNucleus ? Colors.purple : Colors.blueGrey;
    } else if (widget.isSelected) {
      bgColor = Colors.blue.shade800;
      borderColor = Colors.blue;
    } else if (widget.isValid) {
      bgColor = Colors.blue.shade900.withValues(alpha: 0.5);
      borderColor = Colors.blue.shade400;
    } else {
      bgColor = const Color(0xFF16213E);
      borderColor = Colors.blueGrey.shade800;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width:
                widget.isValid || widget.isSelected || widget.isFailureCell
                    ? 2
                    : 1,
          ),
          boxShadow: widget.isFailureOrigin
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final card = _displayCard ?? widget.card;

    if (card != null) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value; // 0 → 1
          // Card-flip: rotate from 90° → 0° (appear from the side).
          final angle =
              (1.0 - Curves.easeOut.transform(t.clamp(0.0, 1.0))) *
                  (math.pi / 2);
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: CardFace(
          card: card,
          failure: widget.isFailureCell,
        ),
      );
    }

    if (widget.isValid) {
      return const Center(
        child: Icon(
          Icons.add_circle_outline,
          color: Colors.blue,
          size: 20,
        ),
      );
    }

    return const SizedBox();
  }
}
