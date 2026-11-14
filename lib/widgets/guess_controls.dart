import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';

import '../domain/models.dart';
import '../l10n/app_strings.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'card_face.dart';
import 'sheet.dart';

/// Bottom sheet with the guesses for the selected cell, the neighbour cards
/// and what a mistake would cost.
class GuessSheet extends StatelessWidget {
  final Position position;
  const GuessSheet({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final showOdds = context.watch<SettingsProvider>().showProbabilities;
    final neighbors = provider.getNeighbors(position);
    final options = guessOptions(neighbors);
    final clear = provider.previewClearCount(position);
    final mult = provider.inheritedMultiplier;
    final penalty = provider.previewPenalty(position);

    return GameSheet(
      children: [
        Row(
          children: [
            Text(AppStrings.neighborCount(neighbors.length),
                style: AppText.body(11.5, color: AppColors.muted)),
            const SizedBox(width: 8),
            for (final c in neighbors) ...[
              MiniCard(card: c, width: 22),
              const SizedBox(width: 4),
            ],
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                AppStrings.guessQuestion(neighbors.length),
                style: AppText.body(11.5, color: AppColors.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(AppStrings.riskCalc(clear, mult),
                    style: AppText.body(12, color: AppColors.dangerText)),
              ),
              Text(AppStrings.sipsCount(penalty),
                  style: AppText.display(17, color: const Color(0xFFFF8B8E))),
            ],
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: SheetButton(
                  label: options[i].label,
                  detail: _detail(
                      options[i],
                      showOdds
                          ? provider.guessProbability(
                              position, options[i].guess)
                          : null),
                  labelColor: options[i].color,
                  compact: options.length > 2,
                  onPressed: () => provider.makeGuess(options[i].guess),
                ),
              ),
            ],
          ],
        ),
        Text(AppStrings.switchCellHint,
            textAlign: TextAlign.center,
            style: AppText.body(10.5, color: AppColors.muted)),
      ],
    );
  }

  String? _detail(GuessOption o, double? p) {
    final odds = p == null ? null : '${(p * 100).round()} %';
    if (o.detail == null) return odds;
    if (odds == null) return o.detail;
    return '${o.detail} · $odds';
  }
}

class GuessOption {
  final Guess guess;
  final String label;
  final String? detail;
  final Color? color;
  const GuessOption(this.guess, this.label, {this.detail, this.color});
}

String _r(int v) => Rank.fromValue(v).symbol;

String _range(int from, int to) {
  if (from > to) return AppStrings.impossible;
  if (from == to) return _r(from);
  return '${_r(from)} – ${_r(to)}';
}

/// The guesses available for a cell with [neighbors], with a short
/// explanation of which cards win.
List<GuessOption> guessOptions(List<Card> neighbors) {
  switch (neighbors.length) {
    case 1:
      final v = neighbors[0].rank.value;
      return [
        GuessOption(const Guess(GuessType.higher), AppStrings.higher,
            detail: _range(v + 1, 14)),
        GuessOption(const Guess(GuessType.lower), AppStrings.lower,
            detail: _range(2, v - 1)),
      ];
    case 2:
      final a = neighbors[0].rank.value;
      final b = neighbors[1].rank.value;
      final lo = a < b ? a : b;
      final hi = a < b ? b : a;
      final below = lo > 2 ? _range(2, lo - 1) : null;
      final above = hi < 14 ? _range(hi + 1, 14) : null;
      return [
        GuessOption(const Guess(GuessType.inside), AppStrings.inside,
            detail: _range(lo + 1, hi - 1)),
        GuessOption(const Guess(GuessType.outside), AppStrings.outside,
            detail: [below, above].whereType<String>().join(', ')),
      ];
    case 3:
      final suits = neighbors.map((n) => n.suit).toSet();
      final others = Suit.values.where((s) => !suits.contains(s));
      return [
        GuessOption(const Guess(GuessType.hasSuit), AppStrings.hasSuit,
            detail: Suit.values
                .where(suits.contains)
                .map((s) => s.symbol)
                .join(' ')),
        GuessOption(
            const Guess(GuessType.doesNotHaveSuit), AppStrings.doesNotHaveSuit,
            detail: others.isEmpty
                ? AppStrings.impossible
                : others.map((s) => s.symbol).join(' ')),
      ];
    case 4:
      return [
        for (final s in Suit.values)
          GuessOption(Guess(GuessType.exactSuit, suit: s), s.symbol,
              detail: s.name, color: suitInkOnDark(s)),
      ];
    default:
      return const [];
  }
}

/// Suit colour for use on the dark table.
Color suitInkOnDark(Suit s) => (s == Suit.heart || s == Suit.diamond)
    ? const Color(0xFFFF6B7A)
    : AppColors.fg;

/// Short description of a guess, e.g. "Dazwischen (5 – Q)".
String describeGuess(Guess guess, List<Card> neighbors) {
  final opt = guessOptions(neighbors)
      .where((o) =>
          o.guess.type == guess.type &&
          (guess.type != GuessType.exactSuit || o.guess.suit == guess.suit))
      .firstOrNull;
  if (opt == null) return guess.toString();
  final label =
      guess.type == GuessType.exactSuit ? guess.suit!.name : opt.label;
  final ref = neighbors.map((c) => c.display).join(', ');
  return ref.isEmpty ? label : '$label ($ref)';
}
