import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/sheet.dart';

/// Start screen: players (sortable), house rules and the start button.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    context.read<GameProvider>().addPlayer(name);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final players = provider.players;

    return Scaffold(
      backgroundColor: AppColors.table,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.appTitle,
                              style: AppText.display(44, letterSpacing: -1)),
                          const SizedBox(height: 4),
                          Text(AppStrings.appTagline,
                              style: AppText.body(13, color: AppColors.muted)),
                          const SizedBox(height: 24),
                          Text(AppStrings.roundLabel(players.length),
                              style: AppText.eyebrow()),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverReorderableList(
                      itemCount: players.length,
                      onReorder: provider.reorderPlayers,
                      proxyDecorator: (child, _, __) =>
                          Material(color: Colors.transparent, child: child),
                      itemBuilder: (context, i) {
                        final p = players[i];
                        return Padding(
                          key: ObjectKey(p),
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _PlayerRow(
                            index: i,
                            player: p,
                            onRemove: () => provider.removePlayer(i),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AddPlayerField(
                            controller: _controller,
                            focusNode: _focus,
                            onSubmit: _addPlayer,
                          ),
                          const SizedBox(height: 28),
                          Text(AppStrings.houseRules, style: AppText.eyebrow()),
                          const SizedBox(height: 4),
                          const HouseRulesList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetButton(
                    label: AppStrings.startGame,
                    detail: players.isEmpty
                        ? AppStrings.needPlayers
                        : AppStrings.startsFirst(players.first.name),
                    primary: true,
                    onPressed: players.isEmpty
                        ? null
                        : () {
                            provider.startGame();
                            Navigator.pushReplacementNamed(context, '/game');
                          },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/rules'),
                        child: Text(AppStrings.rulesTitle,
                            style: AppText.body(13, color: AppColors.muted)),
                      ),
                      Text('·',
                          style: AppText.body(13, color: AppColors.muted)),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/history'),
                        child: Text(AppStrings.historyTitle,
                            style: AppText.body(13, color: AppColors.muted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final int index;
  final Player player;
  final VoidCallback onRemove;

  const _PlayerRow({
    required this.index,
    required this.player,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.raised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.player(player.colorIndex),
            child: Text(
              player.name.characters.first.toUpperCase(),
              style: AppText.display(14, weight: 700, color: AppColors.table),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(player.name,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(15, weight: FontWeight.w500)),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: AppStrings.removePlayer,
            icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Tooltip(
              message: AppStrings.reorderHint,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_indicator, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPlayerField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  const _AddPlayerField({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      style: AppText.body(15),
      decoration: InputDecoration(
        hintText: '+ ${AppStrings.addPlayerHint}',
        hintStyle: AppText.body(14, color: AppColors.muted),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: border,
        focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.amber, width: 1.5)),
        suffixIcon: IconButton(
          onPressed: onSubmit,
          tooltip: AppStrings.add,
          icon: const Icon(Icons.add, color: AppColors.amber),
        ),
      ),
      onSubmitted: (_) => onSubmit(),
    );
  }
}
