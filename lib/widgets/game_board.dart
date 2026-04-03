import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import '../domain/models.dart';
import '../providers/game_provider.dart';

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

    return AspectRatio(
      aspectRatio: 1,
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
          final isValid = validPositions.contains(pos) && provider.canInteract;
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
            onTap: isValid && provider.phase == GamePhase.selectingPosition
                ? () => provider.selectPosition(pos)
                : null,
          );
        },
      ),
    );
  }
}

class _CardCell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;

    if (isFailureOrigin) {
      bgColor = Colors.red.shade900;
      borderColor = Colors.red;
    } else if (isFailureCell) {
      bgColor = const Color(0xFF5C1010);
      borderColor = Colors.red.shade700;
    } else if (card != null) {
      bgColor = isNucleus ? const Color(0xFF533483) : const Color(0xFF0F3460);
      borderColor = isNucleus ? Colors.purple : Colors.blueGrey;
    } else if (isSelected) {
      bgColor = Colors.blue.shade800;
      borderColor = Colors.blue;
    } else if (isValid) {
      bgColor = Colors.blue.shade900.withValues(alpha: 0.5);
      borderColor = Colors.blue.shade400;
    } else {
      bgColor = const Color(0xFF16213E);
      borderColor = Colors.blueGrey.shade800;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isValid || isSelected || isFailureCell ? 2 : 1,
          ),
          boxShadow: isFailureOrigin
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: card != null
            ? Center(
                child: Text(
                  card!.display,
                  style: TextStyle(
                    color: isFailureCell
                        ? Colors.red.shade200
                        : card!.isRed
                            ? Colors.red.shade300
                            : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : isValid
                ? const Center(
                    child: Icon(
                      Icons.add_circle_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                  )
                : null,
      ),
    );
  }
}
