import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final players = provider.players;
    final isMatrixFull = provider.phase == GamePhase.matrixFull;

    final sorted = [...players]..sort((a, b) => b.totalPenalty.compareTo(a.totalPenalty));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Scoreboard', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              provider.startGame();
              Navigator.pushReplacementNamed(context, '/game');
            },
            child: const Text('Neu', style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length + (isMatrixFull ? 1 : 0),
        itemBuilder: (context, index) {
          if (isMatrixFull && index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A0DAD), Color(0xFF1A0050)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFFFD700), width: 2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🏆', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Text(
                    'Matrix Voll – Legendenstatus!',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('🏆', style: TextStyle(fontSize: 24)),
                ],
              ),
            );
          }
          final player = sorted[index - (isMatrixFull ? 1 : 0)];
          final playerRank = index - (isMatrixFull ? 1 : 0);
          final rankColor = playerRank == 0
              ? const Color(0xFFFFD700)
              : playerRank == 1
                  ? const Color(0xFFC0C0C0)
                  : playerRank == 2
                      ? const Color(0xFFCD7F32)
                      : Colors.white;
          return Card(
            color: const Color(0xFF0F3460),
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${playerRank + 1}. ',
                        style: TextStyle(
                          color: rankColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${player.totalPenalty} ',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.local_bar, color: Colors.yellow, size: 20),
                    ],
                  ),
                  if (player.penaltyLog.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: player.penaltyLog
                          .asMap()
                          .entries
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF533483),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'R${e.key + 1}: ${e.value} ',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  const Icon(Icons.local_bar, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
