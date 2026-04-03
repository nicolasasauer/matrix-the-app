import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/game_board.dart';
import '../widgets/guess_controls.dart';
import '../widgets/player_info_bar.dart';
import '../widgets/settings_dialog.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final engine = provider.engine;

    if (engine == null) {
      return const Scaffold(body: Center(child: Text('No game started')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF16213E),
                title: const Text(
                  'Spiel beenden?',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Möchtest du wirklich zum Startmenü? Das laufende Spiel wird abgebrochen.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Abbrechen'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Ja, beenden',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        title: const Text('Matrix', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.group, color: Colors.white),
            tooltip: 'Spieler verwalten',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _PlayerManagementDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/scoreboard'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Einstellungen',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const SettingsDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const PlayerInfoBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const GameBoard(),
                    const SizedBox(height: 8),
                    if (provider.phase == GamePhase.makingGuess &&
                        provider.selectedPosition != null)
                      GuessControls(position: provider.selectedPosition!),
                    if (provider.phase == GamePhase.showingFailure)
                      const _AnimatedBanner(
                          shake: true, child: _FailureBanner()),
                    if (provider.phase == GamePhase.awaitingDecision)
                      const _AnimatedBanner(child: _DecisionBanner()),
                    if (provider.phase == GamePhase.matrixFull)
                      const _AnimatedBanner(child: _MatrixFullBanner()),
                    if (provider.phase == GamePhase.gameOver)
                      const _AnimatedBanner(child: _GameOverBanner()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final card = provider.drawnCard;
    final penalty = provider.pendingPenalty;
    final playerName = provider.currentPlayer?.name ?? '';

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3D0000),
            Colors.red.shade900,
            const Color(0xFF3D0000),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💀', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  '$playerName hat verkackt!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('💀', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // Card display
                if (card != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.shade700,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Gezogene Karte',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.display,
                            style: TextStyle(
                              color: card.isRed
                                  ? Colors.red.shade200
                                  : Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (card != null) const SizedBox(width: 12),

                // Drink count badge
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.red.shade700,
                          Colors.red.shade900,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🍺',
                          style: TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$penalty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          penalty == 1 ? 'Schluck' : 'Schlücke',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline,
                    color: Colors.red.shade300, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Zeile & Spalte werden abgeräumt',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.confirmFailure,
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                label: const Text(
                  'Abräumen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: Colors.red.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionBanner extends StatelessWidget {
  const _DecisionBanner();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                '${provider.turnCalls} richtige Tipps!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Multiplikator: ${provider.globalMultiplier}x',
            style: const TextStyle(color: Colors.greenAccent, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: provider.continuePlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Weitermachen', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: provider.endTurn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Zug beenden', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameOverBanner extends StatelessWidget {
  const _GameOverBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF533483),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.celebration, color: Colors.yellow, size: 26),
              SizedBox(width: 8),
              Text(
                'Spiel vorbei!',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.celebration, color: Colors.yellow, size: 26),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/scoreboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ergebnis anzeigen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MatrixFullBanner extends StatelessWidget {
  const _MatrixFullBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0050),
            Color(0xFF6A0DAD),
            Color(0xFF1A0050),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFFFD700), width: 3),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFD700),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '🏆✨🎉',
              style: TextStyle(fontSize: 40),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'MATRIX VOLL!',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unglaublich! Ihr habt die gesamte Matrix gelegt!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Das schafft fast niemand – ihr seid Legenden! 🌟',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/scoreboard'),
              icon: const Icon(Icons.emoji_events,
                  color: Colors.black, size: 20),
              label: const Text(
                'Ergebnis anzeigen',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 6,
                shadowColor: const Color(0xFFFFD700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBanner extends StatefulWidget {
  final Widget child;
  final bool shake;

  const _AnimatedBanner({required this.child, this.shake = false});

  @override
  State<_AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<_AnimatedBanner>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final AnimationController _shakeController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _shakeAnim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnim =
        CurvedAnimation(parent: _slideController, curve: Curves.easeIn);
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final enabled = context.read<SettingsProvider>().animationsEnabled;
      if (enabled) {
        _slideController.forward();
        if (widget.shake) {
          _slideController.addStatusListener(_onSlideComplete);
        }
      } else {
        _slideController.value = 1.0;
      }
    }
  }

  void _onSlideComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _slideController.removeStatusListener(_onSlideComplete);
      _shakeController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _shakeController]),
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: child,
          ),
        ),
      ),
      child: widget.child,
    );
  }
}

class _PlayerManagementDialog extends StatefulWidget {
  const _PlayerManagementDialog();

  @override
  State<_PlayerManagementDialog> createState() =>
      _PlayerManagementDialogState();
}

class _PlayerManagementDialogState extends State<_PlayerManagementDialog> {
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
    final provider = context.watch<GameProvider>();
    final players = provider.players;

    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: const Text(
        'Spieler verwalten',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      player.name,
                      style: TextStyle(
                        color: player.active ? Colors.white : Colors.white38,
                      ),
                    ),
                    trailing: Switch(
                      value: player.active,
                      onChanged: (_) => provider.togglePlayerActive(index),
                      activeColor: Colors.greenAccent,
                      inactiveThumbColor: Colors.white38,
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24, height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Neuer Spieler...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F3460),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addPlayer(context),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addPlayer(context),
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF533483),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fertig', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
