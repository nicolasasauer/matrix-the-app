import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../domain/models.dart' hide Card;
import '../domain/models.dart' as domain;

/// The font family that guarantees ♥ ♠ ♦ ♣ are rendered correctly on every
/// device, including old Android versions that lack those glyphs in the system
/// font.  The .ttf is bundled in assets/fonts/ and registered in pubspec.yaml.
const _kSymbolFont = 'NotoSansSymbols2';

/// Returns the color for a [Suit] used throughout the card-rendering widgets.
Color suitColor(domain.Suit suit, {bool failure = false}) {
  if (failure) return Colors.red.shade200;
  return (suit == domain.Suit.heart || suit == domain.Suit.diamond)
      ? Colors.red.shade300
      : Colors.white;
}

/// A compact inline representation of a card, e.g. used in the neighbor list:
/// "A♠  K♥".  The suit glyph is rendered with [_kSymbolFont].
class CardInline extends StatelessWidget {
  final domain.Card card;
  final double fontSize;
  final bool failure;

  const CardInline({
    super.key,
    required this.card,
    this.fontSize = 18,
    this.failure = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = suitColor(card.suit, failure: failure);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: card.rank.symbol,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: card.suit.symbol,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: _kSymbolFont,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full card face used inside the 5×5 grid cells.  Shows the rank in the
/// top-left corner and a large suit symbol centred in the cell.
class CardFace extends StatelessWidget {
  final domain.Card card;
  final bool failure;

  const CardFace({super.key, required this.card, this.failure = false});

  @override
  Widget build(BuildContext context) {
    final color = suitColor(card.suit, failure: failure);
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Stack(
        children: [
          // Top-left rank label
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              card.rank.symbol,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ),
          // Bottom-right rank label (upside-down mirror – classic card look)
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: math.pi,
              child: Text(
                card.rank.symbol,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
          // Centre suit symbol
          Center(
            child: Text(
              card.suit.symbol,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontFamily: _kSymbolFont,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Large card display used in the "current card" panel in the game screen.
class CardLarge extends StatelessWidget {
  final domain.Card card;

  const CardLarge({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final color = card.isRed ? Colors.red.shade200 : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.rank.symbol,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        Text(
          card.suit.symbol,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontFamily: _kSymbolFont,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
