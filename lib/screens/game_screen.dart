import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/card_face.dart';
import '../widgets/game_board.dart';
import '../widgets/guess_controls.dart';
import '../widgets/player_info_bar.dart';
import '../widgets/reshuffle_animation.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/sheet.dart';

/// The table. Layout is fixed: player strip and HUD on top, the board takes
/// whatever height is left, and all actions live in the bottom sheet. Nothing
/// on this screen needs scrolling.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  /// Home / back: end with scoring, discard, or stay.
  static Future<void> confirmLeave(BuildContext context) async {
    final provider = context.read<GameProvider>();
    final canEnd = provider.canEndGame;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.raised,
        title: Text(AppStrings.leaveTitle, style: AppText.display(20)),
        content: Text(
            canEnd ? AppStrings.leaveContent : AppStrings.leaveContentNoEnd,
            style: AppText.body(14, color: AppColors.muted)),
        actionsOverflowButtonSpacing: 4,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel,
                style: AppText.body(14, color: AppColors.fg)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: Text(AppStrings.discardGame,
                style: AppText.body(14,
                    weight: FontWeight.w600, color: AppColors.danger)),
          ),
          if (canEnd)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('end'),
              child: Text(AppStrings.endAndScore,
                  style: AppText.body(14,
                      weight: FontWeight.w600, color: AppColors.amber)),
            ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (choice == 'discard') {
      Navigator.pushReplacementNamed(context, '/');
    } else if (choice == 'end') {
      provider.endGame();
      Navigator.pushReplacementNamed(context, '/scoreboard');
    }
  }

  /// Menu: end the round now and show the result.
  static Future<void> confirmEnd(BuildContext context) async {
    final provider = context.read<GameProvider>();
    if (!provider.canEndGame) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.raised,
        title: Text(AppStrings.endGameTitle, style: AppText.display(20)),
        content: Text(AppStrings.endGameContent,
            style: AppText.body(14, color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel,
                style: AppText.body(14, color: AppColors.fg)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.endAndScore,
                style: AppText.body(14,
                    weight: FontWeight.w600, color: AppColors.amber)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      provider.endGame();
      Navigator.pushReplacementNamed(context, '/scoreboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    if (provider.engine == null) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: Text(AppStrings.backToMenu,
                style: AppText.body(15, color: AppColors.amber)),
          ),
        ),
      );
    }
    final phase = provider.phase;
    final animate = context.watch<SettingsProvider>().animationsEnabled;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) confirmLeave(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.table,
        body: Stack(
          children: [
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: _TopBar(onHome: () => confirmLeave(context)),
                ),
                const GameHud(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child:
                        GameBoard(dimmed: phase == GamePhase.awaitingDecision),
                  ),
                ),
                const SizedBox(height: 10),
                _FitSheet(
                  child: animate
                      ? AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          alignment: Alignment.bottomCenter,
                          child: _sheetFor(provider),
                        )
                      : _sheetFor(provider),
                ),
              ],
            ),
            const Positioned.fill(child: ReshuffleAnimation()),
            if (phase == GamePhase.showingFailure)
              Positioned.fill(
                child:
                    _ShakeIn(enabled: animate, child: const _FailureOverlay()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sheetFor(GameProvider provider) {
    switch (provider.phase) {
      case GamePhase.makingGuess:
        final pos = provider.selectedPosition;
        if (pos != null) {
          return GuessSheet(key: ValueKey('guess$pos'), position: pos);
        }
        return const _PickSheet();
      case GamePhase.awaitingDecision:
        return const _DecisionSheet();
      case GamePhase.gameOver:
        return const _EndSheet(matrixFull: false);
      case GamePhase.matrixFull:
        return const _EndSheet(matrixFull: true);
      case GamePhase.selectingPosition:
      case GamePhase.showingFailure:
        return const _PickSheet();
    }
  }
}

/// Keeps the action sheet at most 60 % of the screen high. On very small
/// phones the sheet is scaled down instead of becoming scrollable, so every
/// button stays reachable and the board keeps at least 40 %.
class _FitSheet extends StatelessWidget {
  final Widget child;
  const _FitSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height * 0.6),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: size.width, child: child),
      ),
    );
  }
}

// ── Top bar ─────────────────────────────────────────────────────────────────

enum _MenuAction { players, scoreboard, rules, settings, endGame }

class _TopBar extends StatelessWidget {
  final VoidCallback onHome;
  const _TopBar({required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onHome,
            tooltip: AppStrings.backToMenu,
            icon: const Icon(Icons.home_outlined, color: AppColors.fg),
          ),
          const Expanded(child: PlayerStrip()),
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert, color: AppColors.fg),
            color: AppColors.raised,
            onSelected: (a) {
              switch (a) {
                case _MenuAction.players:
                  showDialog(
                      context: context,
                      builder: (_) => const _PlayerManagementDialog());
                case _MenuAction.scoreboard:
                  Navigator.pushNamed(context, '/scoreboard');
                case _MenuAction.rules:
                  Navigator.pushNamed(context, '/rules');
                case _MenuAction.settings:
                  showDialog(
                      context: context, builder: (_) => const SettingsDialog());
                case _MenuAction.endGame:
                  GameScreen.confirmEnd(context);
              }
            },
            itemBuilder: (_) => [
              _item(_MenuAction.scoreboard, Icons.leaderboard_outlined,
                  AppStrings.scoreboardTitle),
              _item(_MenuAction.players, Icons.group_outlined,
                  AppStrings.managePlayersTitle),
              _item(_MenuAction.rules, Icons.menu_book_outlined,
                  AppStrings.rulesTitle),
              _item(_MenuAction.settings, Icons.tune, AppStrings.settingsTitle),
              const PopupMenuDivider(),
              _item(_MenuAction.endGame, Icons.flag_outlined,
                  AppStrings.endGameMenu,
                  enabled: context.read<GameProvider>().canEndGame),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_MenuAction> _item(_MenuAction a, IconData icon, String text,
          {bool enabled = true}) =>
      PopupMenuItem(
        value: a,
        enabled: enabled,
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 12),
          Text(text, style: AppText.body(14)),
        ]),
      );
}

// ── Sheets ──────────────────────────────────────────────────────────────────

class _PickSheet extends StatelessWidget {
  const _PickSheet();

  @override
  Widget build(BuildContext context) {
    final name = context.watch<GameProvider>().currentPlayer?.name ?? '';
    return GameSheet(
      key: const ValueKey('pick'),
      children: [
        Text('$name: ${AppStrings.pickCell}',
            textAlign: TextAlign.center,
            style: AppText.display(17, weight: 700)),
        Text(AppStrings.pickCellHint,
            textAlign: TextAlign.center,
            style: AppText.body(11.5, color: AppColors.muted, height: 1.3)),
      ],
    );
  }
}

class _DecisionSheet extends StatelessWidget {
  const _DecisionSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameProvider>();
    final next = p.nextPlayer?.name ?? '';
    final continueTarget = GameProvider.nextMultiplier(p.globalMultiplier + 1,
        streakRule: p.streakRuleEnabled);

    return GameSheet(
      key: const ValueKey('decision'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (_) => Container(
              width: 26,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppColors.ok,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        Text(AppStrings.correctInARow(p.turnCalls),
            textAlign: TextAlign.center, style: AppText.display(22)),
        ChoiceTile(
          title: AppStrings.decisionSaveAndPass,
          subtitle: AppStrings.decisionSaveSubtitle(next),
          tag: '${p.passOnMultiplier}x',
          accent: AppColors.amber,
          highlighted: true,
          onPressed: p.endTurn,
        ),
        ChoiceTile(
          title: AppStrings.decisionContinue,
          subtitle: AppStrings.decisionContinueSubtitle(
              p.inheritedMultiplier, continueTarget),
          tag: '→ ${continueTarget}x',
          accent: AppColors.ok,
          onPressed: p.continuePlay,
        ),
      ],
    );
  }
}

class _EndSheet extends StatelessWidget {
  final bool matrixFull;
  const _EndSheet({required this.matrixFull});

  @override
  Widget build(BuildContext context) {
    return GameSheet(
      key: ValueKey('end$matrixFull'),
      children: [
        if (matrixFull) ...[
          Text(AppStrings.matrixFull,
              textAlign: TextAlign.center,
              style: AppText.display(30, color: AppColors.gold)),
          Text(AppStrings.matrixFullSubtitle,
              textAlign: TextAlign.center,
              style: AppText.body(13, color: AppColors.muted)),
        ] else
          Text(AppStrings.gameOver,
              textAlign: TextAlign.center, style: AppText.display(22)),
        SheetButton(
          label: AppStrings.showResult,
          primary: true,
          background: matrixFull ? AppColors.gold : null,
          labelColor: matrixFull ? AppColors.amberInk : null,
          icon: Icons.emoji_events_outlined,
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/scoreboard'),
        ),
      ],
    );
  }
}

// ── Failure overlay ─────────────────────────────────────────────────────────

class _FailureOverlay extends StatelessWidget {
  const _FailureOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameProvider>();
    final name = p.currentPlayer?.name ?? '';
    final card = p.drawnCard;
    final guess = p.lastGuess;
    final penalty = p.pendingPenalty;
    final mult = p.inheritedMultiplier;

    return Material(
      color: AppColors.table,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.1,
            colors: [Color(0xFF5A1418), Color(0xFF2A0B10), AppColors.table],
            stops: [0, 0.6, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Everything above the button scales down on small screens,
                // so the button is always visible without scrolling.
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 300,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppStrings.playerDrinks(name),
                                textAlign: TextAlign.center,
                                style: AppText.display(30)),
                            if (guess != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                AppStrings.guessed(
                                    describeGuess(guess, p.lastNeighbors)),
                                textAlign: TextAlign.center,
                                style: AppText.body(13,
                                    color: AppColors.dangerText),
                              ),
                            ],
                            if (card != null) ...[
                              const SizedBox(height: 22),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  BigCard(card: card, width: 64),
                                  const SizedBox(width: 18),
                                  Text('${AppStrings.drawn}\n${cardName(card)}',
                                      style: AppText.body(13,
                                          color: AppColors.dangerText,
                                          height: 1.35)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),
                            Text('$penalty',
                                style: AppText.display(110,
                                    height: 0.95, letterSpacing: -4)),
                            Text(AppStrings.sipsLabel(penalty).toUpperCase(),
                                style: AppText.mono(12,
                                    color: AppColors.dangerText,
                                    letterSpacing: 2)),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  AppStrings.failureCalc(
                                      p.pendingClearCount, mult),
                                  style:
                                      AppText.mono(12.5, color: AppColors.fg)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: SizedBox(
                      width: double.infinity,
                      child: SheetButton(
                        label: AppStrings.confirmClear,
                        detail: AppStrings.afterFailure(name, mult > 1),
                        background: AppColors.danger,
                        icon: Icons.delete_sweep_outlined,
                        onPressed: p.confirmFailure,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades/slides the child in and shakes it once.
class _ShakeIn extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const _ShakeIn({required this.child, required this.enabled});

  @override
  State<_ShakeIn> createState() => _ShakeInState();
}

class _ShakeInState extends State<_ShakeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: const Interval(0, 0.35));
  late final Animation<double> _shake = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 10),
    TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 15),
    TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 25),
  ]).animate(_c);

  @override
  void initState() {
    super.initState();
    widget.enabled ? _c.forward() : _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(_shake.value, 0),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ── Player management dialog ────────────────────────────────────────────────

/// Add, remove, sort and pause players while the game is running.
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

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      context.read<GameProvider>().addPlayer(name);
      _controller.clear();
    }
  }

  Future<void> _remove(int index) async {
    final provider = context.read<GameProvider>();
    final player = provider.players[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.raised,
        title: Text(AppStrings.removeTitle(player.name),
            style: AppText.display(20)),
        content: Text(AppStrings.removeContent,
            style: AppText.body(14, color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel,
                style: AppText.body(14, color: AppColors.fg)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.removeConfirm,
                style: AppText.body(14,
                    weight: FontWeight.w600, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      // Look the player up again – the list may have changed meanwhile.
      final i = provider.players.indexOf(player);
      if (i >= 0) provider.removePlayer(i, inGame: true);
    }
  }

  String? _blockReason(GameProvider p, int index) {
    if (p.canRemovePlayer(index, inGame: true)) return null;
    return index == p.currentPlayerIndex && p.phase == GamePhase.showingFailure
        ? AppStrings.cantRemoveDuringFailure
        : AppStrings.cantRemoveLast;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final players = provider.players;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.45;

    return AlertDialog(
      backgroundColor: AppColors.raised,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.managePlayersTitle, style: AppText.display(20)),
          const SizedBox(height: 4),
          Text(AppStrings.managePlayersHint,
              style: AppText.body(12, color: AppColors.muted)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: players.length,
                onReorder: provider.reorderPlayers,
                proxyDecorator: (child, _, __) => Material(
                    color: Colors.transparent, elevation: 6, child: child),
                itemBuilder: (context, index) {
                  final player = players[index];
                  final isTurn = index == provider.currentPlayerIndex;
                  final block = _blockReason(provider, index);
                  return Container(
                    key: ObjectKey(player),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: AppColors.table,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isTurn ? AppColors.fg : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.player(player.colorIndex),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(player.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(15,
                                      weight: FontWeight.w500,
                                      color: player.active
                                          ? AppColors.fg
                                          : AppColors.muted)),
                              Text(
                                isTurn
                                    ? AppStrings.isTurn
                                    : player.active
                                        ? AppStrings.sipsShort(
                                            player.totalPenalty)
                                        : AppStrings.sitsOut,
                                style: AppText.mono(10,
                                    color: isTurn
                                        ? AppColors.amber
                                        : AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: block ?? AppStrings.sitOutToggle,
                          child: Switch(
                            value: player.active,
                            onChanged: player.active && block != null
                                ? null
                                : (_) => provider.togglePlayerActive(index),
                          ),
                        ),
                        IconButton(
                          tooltip: block ?? AppStrings.removePlayer,
                          onPressed:
                              block == null ? () => _remove(index) : null,
                          icon: const Icon(Icons.person_remove_outlined,
                              size: 20),
                          color: AppColors.muted,
                          disabledColor: AppColors.line,
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(2, 12, 10, 12),
                            child: Icon(Icons.drag_indicator,
                                color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.words,
                    style: AppText.body(15),
                    decoration: InputDecoration(
                      hintText: AppStrings.newPlayerHint,
                      hintStyle: AppText.body(15, color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.table,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addPlayer,
                  tooltip: AppStrings.add,
                  icon: const Icon(Icons.person_add_alt_1),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.done,
              style: AppText.body(14,
                  weight: FontWeight.w600, color: AppColors.amber)),
        ),
      ],
    );
  }
}
