import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class PlayerInfoBar extends StatelessWidget {
  const PlayerInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final player = provider.currentPlayer;
    if (player == null) return const SizedBox();

    final engine = provider.engine;
    final remaining = engine?.deck.remaining ?? 0;
    final calls = provider.turnCalls;
    final callsInSet = calls % 3;
    final multiplier = provider.globalMultiplier;

    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Calls: $callsInSet/3  |  Strafe: ${player.totalPenalty} ',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Icon(Icons.local_bar, color: Colors.white70, size: 13),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$remaining Karten',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: multiplier > 1 ? Colors.orange.shade800 : const Color(0xFF533483),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${multiplier}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
