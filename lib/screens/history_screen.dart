import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/game_record.dart';
import '../providers/game_provider.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<GameRecord>> _historyFuture;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _historyFuture = StorageService().loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (_tabController != controller) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = controller;
      _tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (_tabController?.index == 1) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _historyFuture = StorageService().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GameRecord>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, color: Colors.white38, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Noch keine Spiele gespielt',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: history.length,
                itemBuilder: (context, index) =>
                    _GameRecordCard(record: history[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF16213E),
                      title: const Text(
                        'Verlauf löschen?',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Alle gespeicherten Spiele werden unwiderruflich gelöscht.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Abbrechen',
                              style: TextStyle(color: Colors.white54)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Löschen',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await StorageService().clearHistory();
                    _refresh();
                  }
                },
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text(
                  'Verlauf löschen',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GameRecordCard extends StatelessWidget {
  final GameRecord record;

  const _GameRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final sorted = [...record.players]
      ..sort((a, b) => a.totalPenalty.compareTo(b.totalPenalty));

    final now = DateTime.now();
    final diff = now.difference(record.playedAt);
    final String timeLabel;
    if (diff.inMinutes < 1) {
      timeLabel = 'Gerade eben';
    } else if (diff.inHours < 1) {
      timeLabel = 'Vor ${diff.inMinutes} Min.';
    } else if (diff.inDays < 1) {
      timeLabel = 'Vor ${diff.inHours} Std.';
    } else if (diff.inDays == 1) {
      timeLabel = 'Gestern';
    } else {
      final d = record.playedAt;
      timeLabel =
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    }

    return Card(
      color: const Color(0xFF0F3460),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  timeLabel,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                if (record.matrixFull)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🏆', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          'Matrix Voll!',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Players
            ...sorted.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final rankColor = i == 0
                  ? const Color(0xFFFFD700)
                  : i == 1
                      ? const Color(0xFFC0C0C0)
                      : i == 2
                          ? const Color(0xFFCD7F32)
                          : Colors.white70;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(
                      '${i + 1}.',
                      style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(color: rankColor, fontSize: 13),
                      ),
                    ),
                    Text(
                      '${p.totalPenalty} ',
                      style: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const Icon(Icons.local_bar,
                        color: Colors.yellow, size: 13),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final provider = context.read<GameProvider>();
                  provider.setPlayers(
                      record.players.map((p) => p.name).toList());
                  DefaultTabController.of(context).animateTo(0);
                },
                icon: const Icon(Icons.replay, size: 16, color: Colors.white),
                label: const Text(
                  'Nochmal spielen',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF533483),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
