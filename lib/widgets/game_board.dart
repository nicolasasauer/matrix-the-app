import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import '../domain/models.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';

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
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    // Card already on grid at init (e.g. game resumed) — show immediately
    if (widget.card != null) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_CardCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card == null && widget.card != null) {
      final enabled = context.read<SettingsProvider>().animationsEnabled;
      if (enabled) {
        _controller.forward(from: 0.0);
      } else {
        _controller.value = 1.0;
      }
    } else if (oldWidget.card != null && widget.card == null) {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;

    if (widget.isFailureOrigin) {
      bgColor = Colors.red.shade900;
      borderColor = Colors.red;
    } else if (widget.isFailureCell) {
      bgColor = const Color(0xFF5C1010);
      borderColor = Colors.red.shade700;
    } else if (widget.card != null) {
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
        child: widget.card != null
            ? Center(
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Text(
                    widget.card!.display,
                    style: TextStyle(
                      color: widget.isFailureCell
                          ? Colors.red.shade200
                          : widget.card!.isRed
                              ? Colors.red.shade300
                              : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : widget.isValid
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
