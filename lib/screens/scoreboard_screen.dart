import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sheet.dart';

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final isMatrixFull = provider.phase == GamePhase.matrixFull;
    final isOver = provider.phase == GamePhase.gameOver || isMatrixFull;

    // Fewest sips wins.
    final sorted = [...provider.players]
      ..sort((a, b) => a.totalPenalty.compareTo(b.totalPenalty));
    final maxSips =
        sorted.fold<int>(1, (m, p) => p.totalPenalty > m ? p.totalPenalty : m);
    final timeline = provider.penaltyTimeline;

    return Scaffold(
      backgroundColor: AppColors.table,
      appBar: AppBar(
        automaticallyImplyLeading: !isOver,
        title: Text(AppStrings.scoreboardTitle),
        actions: [
          if (!isOver && provider.engine != null)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: AppStrings.saveProgress,
              onPressed: () {
                provider.saveToHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.saved),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  Text(
                      isOver ? AppStrings.gameFinished : AppStrings.gameRunning,
                      style: AppText.body(13, color: AppColors.muted)),
                  if (isMatrixFull) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gold, width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(AppStrings.matrixFull,
                              style:
                                  AppText.display(24, color: AppColors.gold)),
                          const SizedBox(height: 4),
                          Text(AppStrings.matrixFullSubtitle,
                              textAlign: TextAlign.center,
                              style:
                                  AppText.body(12.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(AppStrings.ranking, style: AppText.eyebrow()),
                  const SizedBox(height: 10),
                  for (var i = 0; i < sorted.length; i++)
                    _RankRow(
                      position: i + 1,
                      player: sorted[i],
                      fraction: sorted[i].totalPenalty / maxSips,
                      isWinner: isOver &&
                          i == 0 &&
                          (sorted.length == 1 ||
                              sorted[0].totalPenalty < sorted[1].totalPenalty),
                    ),
                  const SizedBox(height: 18),
                  Text(AppStrings.timeline, style: AppText.eyebrow()),
                  const SizedBox(height: 10),
                  if (timeline.isEmpty)
                    Text(AppStrings.noMistakes,
                        style: AppText.body(13, color: AppColors.muted))
                  else
                    _Timeline(events: timeline),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SheetButton(
                      label: isOver
                          ? AppStrings.backToMenu
                          : AppStrings.backToGame,
                      onPressed: () => isOver
                          ? Navigator.pushReplacementNamed(context, '/')
                          : Navigator.pop(context),
                    ),
                  ),
                  if (isOver) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: SheetButton(
                        label: AppStrings.rematch,
                        primary: true,
                        icon: Icons.replay,
                        onPressed: () {
                          provider.startGame();
                          Navigator.pushReplacementNamed(context, '/game');
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int position;
  final Player player;
  final double fraction;
  final bool isWinner;

  const _RankRow({
    required this.position,
    required this.player,
    required this.fraction,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      AppStrings.hits(player.correctGuesses),
      AppStrings.misses(player.wrongGuesses),
      if (player.maxReceivedMultiplier > 1)
        AppStrings.receivedMax(player.maxReceivedMultiplier),
      if (player.maxCreatedMultiplier > 0)
        AppStrings.createdMax(player.maxCreatedMultiplier),
      if (player.maxSinglePenalty > 0)
        AppStrings.worstMiss(player.maxSinglePenalty),
    ];
    final color = AppColors.player(player.colorIndex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text('$position',
                style: AppText.mono(13, color: AppColors.muted)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text.rich(
                        style: DefaultTextStyle.of(context)
                            .style
                            .merge(AppText.body(15, weight: FontWeight.w600)),
                        TextSpan(children: [
                          TextSpan(text: player.name),
                          if (isWinner)
                            TextSpan(
                                text: '   ${AppStrings.fewestSips}',
                                style: AppText.body(11,
                                    weight: FontWeight.w500,
                                    color: AppColors.ok)),
                        ]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${player.totalPenalty}',
                        style:
                            AppText.mono(16, weight: 700, color: AppColors.fg)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(height: 6, color: AppColors.line),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.0, 1.0),
                        child: Container(height: 6, color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(meta.join(' · '),
                    style: AppText.body(11.5, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bars for every mistake in the order it happened, coloured per player.
class _Timeline extends StatelessWidget {
  final List<PenaltyEvent> events;
  const _Timeline({required this.events});

  @override
  Widget build(BuildContext context) {
    final max = events.fold<int>(1, (m, e) => e.penalty > m ? e.penalty : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: LayoutBuilder(builder: (context, c) {
            // Bars are at most 18 px wide so a short game doesn't look like
            // one giant block.
            final slot = (c.maxWidth / events.length).clamp(2.0, 21.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final e in events)
                  Tooltip(
                    message: '${e.playerName}: ${e.penalty}',
                    child: Container(
                      width: slot - (slot > 6 ? 3 : 1),
                      margin: EdgeInsets.only(right: slot > 6 ? 3 : 1),
                      height: 4 + 60 * e.penalty / max,
                      decoration: BoxDecoration(
                        color: AppColors.player(e.colorIndex),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2)),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
        Container(height: 1, color: AppColors.line),
        const SizedBox(height: 6),
        Text('${events.length} Fehler · teuerster: $max',
            style: AppText.body(11.5, color: AppColors.muted)),
      ],
    );
  }
}
