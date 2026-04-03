import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'history_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addPlayer(BuildContext context) {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      context.read<GameProvider>().addPlayer(name);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          title: const Text(
            'Matrix – Das Kartentrinkspiel',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF533483),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Neues Spiel'),
              Tab(icon: Icon(Icons.history), text: 'Verlauf'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SetupContent(
              controller: _controller,
              onAddPlayer: _addPlayer,
            ),
            const HistoryScreen(),
          ],
        ),
      ),
    );
  }
}

class _SetupContent extends StatelessWidget {
  final TextEditingController controller;
  final void Function(BuildContext) onAddPlayer;

  const _SetupContent({
    required this.controller,
    required this.onAddPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Spieler hinzufügen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Spielername...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0F3460),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => onAddPlayer(context),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => onAddPlayer(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF533483),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '+',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: provider.players.length,
              itemBuilder: (context, index) {
                final player = provider.players[index];
                return Card(
                  color: const Color(0xFF0F3460),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(
                      player.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF533483),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle,
                          color: Colors.redAccent),
                      onPressed: () => provider.removePlayer(index),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: provider.players.isEmpty
                ? null
                : () {
                    provider.startGame();
                    Navigator.pushReplacementNamed(context, '/game');
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF533483),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
            child: const Text(
              'Spiel starten',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
