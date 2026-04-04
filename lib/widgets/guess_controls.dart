import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import '../domain/models.dart';
import '../l10n/app_strings.dart';
import '../providers/game_provider.dart';
import 'card_face.dart';

class GuessControls extends StatelessWidget {
  final Position position;
  const GuessControls({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final neighbors = provider.getNeighbors(position);
    final count = neighbors.length;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade700, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _neighborInfo(neighbors),
          const SizedBox(height: 10),
          _buildButtons(context, count),
          const SizedBox(height: 6),
          TextButton(
            onPressed: provider.cancelSelection,
            child: const Text(AppStrings.cancelSelection,
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _neighborInfo(List<Card> neighbors) {
    return Column(
      children: [
        Text(
          AppStrings.neighborCount(neighbors.length),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          children: neighbors
              .map((c) => CardInline(card: c, fontSize: 18))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, int count) {
    switch (count) {
      case 1:
        return Row(
          children: [
            Expanded(
              child: _GuessButton(
                label: AppStrings.higher,
                guess: const Guess(GuessType.higher),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GuessButton(
                label: AppStrings.lower,
                guess: const Guess(GuessType.lower),
                color: Colors.red,
              ),
            ),
          ],
        );
      case 2:
        return Row(
          children: [
            Expanded(
              child: _GuessButton(
                label: AppStrings.inside,
                guess: const Guess(GuessType.inside),
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GuessButton(
                label: AppStrings.outside,
                guess: const Guess(GuessType.outside),
                color: Colors.orange,
              ),
            ),
          ],
        );
      case 3:
        return Row(
          children: [
            Expanded(
              child: _GuessButton(
                label: AppStrings.hasSuit,
                guess: const Guess(GuessType.hasSuit),
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GuessButton(
                label: AppStrings.doesNotHaveSuit,
                guess: const Guess(GuessType.doesNotHaveSuit),
                color: Colors.deepOrange,
              ),
            ),
          ],
        );
      case 4:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: Suit.values
              .map(
                (suit) => _GuessButton(
                  label: suit.name,
                  guess: Guess(GuessType.exactSuit, suit: suit),
                  color: suit == Suit.heart || suit == Suit.diamond
                      ? Colors.red.shade700
                      : Colors.blueGrey.shade700,
                ),
              )
              .toList(),
        );
      default:
        return const SizedBox();
    }
  }
}

class _GuessButton extends StatelessWidget {
  final String label;
  final Guess guess;
  final Color color;

  const _GuessButton({
    required this.label,
    required this.guess,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    return ElevatedButton(
      onPressed: () => provider.makeGuess(guess),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
