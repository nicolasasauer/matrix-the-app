import 'dart:math';

enum Suit {
  heart('♥', 'Herz'),
  spade('♠', 'Pik'),
  diamond('♦', 'Karo'),
  club('♣', 'Kreuz');

  final String symbol;
  final String name;
  const Suit(this.symbol, this.name);
}

enum Rank {
  two(2, '2'),
  three(3, '3'),
  four(4, '4'),
  five(5, '5'),
  six(6, '6'),
  seven(7, '7'),
  eight(8, '8'),
  nine(9, '9'),
  ten(10, '10'),
  jack(11, 'J'),
  queen(12, 'Q'),
  king(13, 'K'),
  ace(14, 'A');

  final int value;
  final String symbol;
  const Rank(this.value, this.symbol);
}

class Card {
  final Suit suit;
  final Rank rank;
  const Card(this.suit, this.rank);

  String get display => '${rank.symbol}${suit.symbol}';
  bool get isRed => suit == Suit.heart || suit == Suit.diamond;

  @override
  String toString() => display;
}

class Deck {
  final List<Card> _cards = [];

  Deck() {
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        _cards.add(Card(suit, rank));
      }
    }
    shuffle();
  }

  void shuffle([Random? rng]) {
    _cards.shuffle(rng ?? Random());
  }

  Card? draw() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }

  int get remaining => _cards.length;
  bool get isEmpty => _cards.isEmpty;
}

class Position {
  final int row;
  final int col;
  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => row * 5 + col;

  @override
  String toString() => '($row,$col)';
}

enum GuessType {
  higher,
  lower,
  inside,
  outside,
  hasSuit,
  doesNotHaveSuit,
  exactSuit,
}

class Guess {
  final GuessType type;
  final Suit? suit; // only for exactSuit

  const Guess(this.type, {this.suit});

  @override
  String toString() {
    if (type == GuessType.exactSuit && suit != null) {
      return 'ExactSuit(${suit!.name})';
    }
    return type.name;
  }
}
