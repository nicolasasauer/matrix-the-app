import '../domain/models.dart';

enum PlaceResult { correct, wrong, gameFinished }

class GameEngine {
  final List<List<Card?>> grid;
  final Deck deck;
  int successfulCalls;

  GameEngine._({
    required this.grid,
    required this.deck,
    required this.successfulCalls,
  });

  factory GameEngine.newGame() {
    final deck = Deck();
    final grid = List.generate(5, (_) => List<Card?>.filled(5, null));
    final nucleus = deck.draw()!;
    grid[2][2] = nucleus;
    return GameEngine._(grid: grid, deck: deck, successfulCalls: 0);
  }

  factory GameEngine.withDeck(Deck deck) {
    final grid = List.generate(5, (_) => List<Card?>.filled(5, null));
    final nucleus = deck.draw()!;
    grid[2][2] = nucleus;
    return GameEngine._(grid: grid, deck: deck, successfulCalls: 0);
  }

  Card? getCard(Position pos) => grid[pos.row][pos.col];

  List<Card> getOrthogonalNeighbors(Position pos) {
    final neighbors = <Card>[];
    final offsets = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (final (dr, dc) in offsets) {
      final r = pos.row + dr;
      final c = pos.col + dc;
      if (r >= 0 && r < 5 && c >= 0 && c < 5 && grid[r][c] != null) {
        neighbors.add(grid[r][c]!);
      }
    }
    return neighbors;
  }

  bool isValidPosition(Position pos) {
    if (grid[pos.row][pos.col] != null) return false;
    return getOrthogonalNeighbors(pos).isNotEmpty;
  }

  List<Position> get validPositions {
    final positions = <Position>[];
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        final pos = Position(r, c);
        if (isValidPosition(pos)) positions.add(pos);
      }
    }
    return positions;
  }

  bool evaluateGuess(Card card, List<Card> neighbors, Guess guess) {
    switch (neighbors.length) {
      case 1:
        final neighbor = neighbors[0];
        if (guess.type == GuessType.higher) {
          return card.rank.value > neighbor.rank.value;
        } else if (guess.type == GuessType.lower) {
          return card.rank.value < neighbor.rank.value;
        }
        return false;
      case 2:
        final a = neighbors[0].rank.value;
        final b = neighbors[1].rank.value;
        final lo = a < b ? a : b;
        final hi = a < b ? b : a;
        final v = card.rank.value;
        if (guess.type == GuessType.inside) {
          return v > lo && v < hi;
        } else if (guess.type == GuessType.outside) {
          return v < lo || v > hi;
        }
        return false;
      case 3:
        if (guess.type == GuessType.hasSuit) {
          return neighbors.any((n) => n.suit == card.suit);
        } else if (guess.type == GuessType.doesNotHaveSuit) {
          return neighbors.every((n) => n.suit != card.suit);
        }
        return false;
      case 4:
        if (guess.type == GuessType.exactSuit) {
          return guess.suit == card.suit;
        }
        return false;
      default:
        return false;
    }
  }

  /// Draws a card, places it at [pos], evaluates the guess against pre-placement
  /// neighbors, and returns the result. The drawn card remains on the grid so
  /// the UI can display it.
  PlaceResult placeCard(Position pos, Guess guess) {
    // Capture neighbors BEFORE placing the card
    final neighbors = getOrthogonalNeighbors(pos);

    final card = deck.draw();
    if (card == null) return PlaceResult.gameFinished;

    grid[pos.row][pos.col] = card;

    final correct = evaluateGuess(card, neighbors, guess);
    if (correct) {
      successfulCalls++;
      return PlaceResult.correct;
    } else {
      return PlaceResult.wrong;
    }
  }

  /// Clears the entire row and column of [pos], respawns the nucleus if needed,
  /// and resets [successfulCalls]. Returns the number of cards cleared.
  int applyFailure(Position pos) {
    int cleared = 0;
    final row = pos.row;
    final col = pos.col;

    for (int c = 0; c < 5; c++) {
      if (grid[row][c] != null) {
        grid[row][c] = null;
        cleared++;
      }
    }
    for (int r = 0; r < 5; r++) {
      if (r != row && grid[r][col] != null) {
        grid[r][col] = null;
        cleared++;
      }
    }

    // Respawn nucleus if it was cleared
    if (grid[2][2] == null) {
      final newNucleus = deck.draw();
      if (newNucleus != null) {
        grid[2][2] = newNucleus;
      }
    }

    successfulCalls = 0;
    return cleared;
  }

  /// Counts how many cards would be cleared by a failure at [pos] without
  /// modifying the grid. Used to preview the penalty before confirming.
  /// The row loop counts all cards in the row (including the intersection cell).
  /// The column loop skips the already-counted row to avoid double-counting.
  int countCardsToBeCleared(Position pos) {
    int count = 0;
    final row = pos.row;
    final col = pos.col;
    for (int c = 0; c < 5; c++) {
      if (grid[row][c] != null) count++;
    }
    for (int r = 0; r < 5; r++) {
      if (r != row && grid[r][col] != null) count++;
    }
    return count;
  }

  bool get isGameFinished => deck.isEmpty;

  bool get isMatrixFull {
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (grid[r][c] == null) return false;
      }
    }
    return true;
  }
}
