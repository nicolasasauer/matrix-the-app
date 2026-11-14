import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/game_record.dart';
import '../l10n/app_strings.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<GameRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = context.read<GameProvider>().storageService.loadHistory();
  }

  void _refresh() {
    setState(() {
      _historyFuture =
          context.read<GameProvider>().storageService.loadHistory();
    });
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.raised,
        title: Text('Verlauf löschen?', style: AppText.display(20)),
        content: Text(
          'Alle gespeicherten Spiele werden unwiderruflich gelöscht.',
          style: AppText.body(14, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel,
                style: AppText.body(14, color: AppColors.fg)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Löschen',
                style: AppText.body(14,
                    weight: FontWeight.w600, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<GameProvider>().storageService.clearHistory();
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.table,
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
        actions: [
          IconButton(
            onPressed: _confirmClear,
            tooltip: 'Verlauf löschen',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: FutureBuilder<List<GameRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return Center(
              child: Text('Noch keine Spiele gespielt',
                  style: AppText.body(15, color: AppColors.muted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _GameRecordCard(record: history[index]),
          );
        },
      ),
    );
  }
}

class _GameRecordCard extends StatelessWidget {
  final GameRecord record;

  const _GameRecordCard({required this.record});

  String _timeLabel() {
    final diff = DateTime.now().difference(record.playedAt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inHours < 1) return 'Vor ${diff.inMinutes} Min.';
    if (diff.inDays < 1) return 'Vor ${diff.inHours} Std.';
    if (diff.inDays == 1) return 'Gestern';
    final d = record.playedAt;
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Fewest sips first.
    final sorted = [...record.players]
      ..sort((a, b) => a.totalPenalty.compareTo(b.totalPenalty));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.raised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_timeLabel(), style: AppText.mono(11.5)),
              const Spacer(),
              if (record.matrixFull)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(AppStrings.matrixFull,
                      style: AppText.body(11,
                          weight: FontWeight.w600, color: AppColors.gold)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < sorted.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('${i + 1}', style: AppText.mono(12)),
                  ),
                  Expanded(
                    child: Text(sorted[i].name,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(14,
                            weight:
                                i == 0 ? FontWeight.w600 : FontWeight.w400)),
                  ),
                  Text(
                    '✓${sorted[i].correctGuesses} ✗${sorted[i].wrongGuesses}',
                    style: AppText.mono(11),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 36,
                    child: Text('${sorted[i].totalPenalty}',
                        textAlign: TextAlign.right,
                        style:
                            AppText.mono(14, weight: 700, color: AppColors.fg)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                context
                    .read<GameProvider>()
                    .setPlayers(record.players.map((p) => p.name).toList());
                Navigator.pop(context);
              },
              icon: const Icon(Icons.replay, size: 16, color: AppColors.amber),
              label: Text('Mit diesen Spielern',
                  style: AppText.body(13,
                      weight: FontWeight.w600, color: AppColors.amber)),
            ),
          ),
        ],
      ),
    );
  }
}
