import 'package:flutter/material.dart';

import '../domain/models.dart' as domain;
import '../theme/app_theme.dart';

/// Ink colour of a suit on a light card face.
Color suitInk(domain.Suit suit) =>
    (suit == domain.Suit.heart || suit == domain.Suit.diamond)
        ? AppColors.suitRed
        : AppColors.cardInk;

String _rank(domain.Card c) => c.rank.symbol;

/// Card face used inside the 5×5 grid. Scales with the cell size.
class CardFace extends StatelessWidget {
  final domain.Card card;

  const CardFace({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final color = suitInk(card.suit);
    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight.isFinite ? c.maxHeight : 60.0;
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_rank(card),
                  style: AppText.display(h * 0.34, weight: 700, color: color)),
              Text(card.suit.symbol,
                  style: TextStyle(
                    fontFamily: AppFonts.symbols,
                    fontSize: h * 0.30,
                    color: color,
                    height: 1.0,
                  )),
            ],
          ),
        ),
      );
    });
  }
}

/// Small card chip, e.g. for the neighbour cards in the guess sheet.
class MiniCard extends StatelessWidget {
  final domain.Card card;
  final double width;

  const MiniCard({super.key, required this.card, this.width = 26});

  @override
  Widget build(BuildContext context) {
    final color = suitInk(card.suit);
    return Container(
      width: width,
      height: width * 1.36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(width * 0.18),
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_rank(card),
                  style:
                      AppText.display(width * 0.46, weight: 700, color: color)),
              Text(card.suit.symbol,
                  style: TextStyle(
                    fontFamily: AppFonts.symbols,
                    fontSize: width * 0.40,
                    color: color,
                    height: 1.0,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large, slightly tilted card for the failure screen.
class BigCard extends StatelessWidget {
  final domain.Card card;
  final double width;

  const BigCard({super.key, required this.card, this.width = 72});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.10,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.14),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 24, offset: Offset(0, 10)),
          ],
        ),
        child: MiniCard(card: card, width: width),
      ),
    );
  }
}

/// Human-readable name of a card, e.g. "König Herz".
String cardName(domain.Card c) {
  const names = {
    domain.Rank.jack: 'Bube',
    domain.Rank.queen: 'Dame',
    domain.Rank.king: 'König',
    domain.Rank.ace: 'Ass',
  };
  return '${names[c.rank] ?? c.rank.symbol} ${c.suit.name}';
}
