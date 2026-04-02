import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/models.dart';
import '../providers/game_provider.dart';

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
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _neighborInfo(List<Card> neighbors) {
    return Column(
      children: [
        Text(
          '${neighbors.length} Nachbar${neighbors.length == 1 ? "" : "n"}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          neighbors.map((c) => c.display).join('  '),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                label: '▲ Höher',
                guess: const Guess(GuessType.higher),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GuessButton(
                label: '▼ Niedriger',
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
                label: 'Dazwischen',
                guess: const Guess(GuessType.inside),
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GuessButton(
                label: 'Außerhalb',
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
                label: '✓ Hat Farbe',
                guess: const Guess(GuessType.hasSuit),
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GuessButton(
                label: '✗ Hat nicht',
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
                  label: '${suit.symbol} ${suit.name}',
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
