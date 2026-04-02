import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_the_app/domain/models.dart';
import 'package:matrix_the_app/engine/game_engine.dart';

void main() {
  group('GameEngine', () {
    test('nucleus is placed at center [2][2] on init', () {
      final engine = GameEngine.newGame();
      expect(engine.grid[2][2], isNotNull);
    });

    test('deck has 51 cards after nucleus placement', () {
      final engine = GameEngine.newGame();
      expect(engine.deck.remaining, equals(51));
    });

    test('valid position must have at least one orthogonal neighbor', () {
      final engine = GameEngine.newGame();
      expect(engine.isValidPosition(const Position(2, 3)), isTrue);
      expect(engine.isValidPosition(const Position(1, 3)), isFalse);
      // Center itself is occupied, so not valid for placement
      expect(engine.isValidPosition(const Position(2, 2)), isFalse);
    });

    test('corner (0,0) is initially invalid', () {
      final engine = GameEngine.newGame();
      expect(engine.isValidPosition(const Position(0, 0)), isFalse);
    });

    test('row and column are cleared on failure', () {
      final engine = GameEngine.newGame();
      engine.grid[2][3] = const Card(Suit.heart, Rank.ace);
      engine.grid[2][4] = const Card(Suit.spade, Rank.king);
      engine.grid[1][3] = const Card(Suit.diamond, Rank.queen);

      engine.applyFailure(const Position(2, 3));

      // Row 2 should be cleared (nucleus at [2][2] will be respawned)
      expect(engine.grid[2][0], isNull);
      expect(engine.grid[2][1], isNull);
      expect(engine.grid[2][3], isNull);
      expect(engine.grid[2][4], isNull);
      // Column 3 should be cleared
      expect(engine.grid[1][3], isNull);
    });

    test('nucleus respawns after failure clears center', () {
      final engine = GameEngine.newGame();
      engine.applyFailure(const Position(2, 2));
      expect(engine.grid[2][2], isNotNull);
    });

    test('successfulCalls resets after failure', () {
      final engine = GameEngine.newGame();
      engine.successfulCalls = 5;
      engine.applyFailure(const Position(2, 2));
      expect(engine.successfulCalls, equals(0));
    });

    test('Higher guess: correct when drawn card rank is higher than neighbor', () {
      final engine = GameEngine.newGame();
      final neighbor = const Card(Suit.heart, Rank.two);
      final drawn = const Card(Suit.spade, Rank.ace);
      final result = engine.evaluateGuess(drawn, [neighbor], const Guess(GuessType.higher));
      expect(result, isTrue);
    });

    test('Lower guess: correct when drawn card rank is lower than neighbor', () {
      final engine = GameEngine.newGame();
      final neighbor = const Card(Suit.heart, Rank.ace);
      final drawn = const Card(Suit.spade, Rank.two);
      final result = engine.evaluateGuess(drawn, [neighbor], const Guess(GuessType.lower));
      expect(result, isTrue);
    });

    test('Inside guess: correct when rank is strictly between two neighbors', () {
      final engine = GameEngine.newGame();
      final neighbors = [const Card(Suit.heart, Rank.two), const Card(Suit.spade, Rank.ten)];
      final drawn = const Card(Suit.diamond, Rank.five);
      final result = engine.evaluateGuess(drawn, neighbors, const Guess(GuessType.inside));
      expect(result, isTrue);
    });

    test('Outside guess: correct when rank is outside two neighbors', () {
      final engine = GameEngine.newGame();
      final neighbors = [const Card(Suit.heart, Rank.five), const Card(Suit.spade, Rank.nine)];
      final drawn = const Card(Suit.diamond, Rank.king);
      final result = engine.evaluateGuess(drawn, neighbors, const Guess(GuessType.outside));
      expect(result, isTrue);
    });

    test('HasSuit guess: correct when at least one neighbor has same suit', () {
      final engine = GameEngine.newGame();
      final neighbors = [
        const Card(Suit.heart, Rank.two),
        const Card(Suit.spade, Rank.three),
        const Card(Suit.heart, Rank.king),
      ];
      final drawn = const Card(Suit.heart, Rank.ace);
      final result = engine.evaluateGuess(drawn, neighbors, const Guess(GuessType.hasSuit));
      expect(result, isTrue);
    });

    test('DoesNotHaveSuit guess: correct when no neighbor has the suit', () {
      final engine = GameEngine.newGame();
      final neighbors = [
        const Card(Suit.spade, Rank.two),
        const Card(Suit.diamond, Rank.three),
        const Card(Suit.club, Rank.king),
      ];
      final drawn = const Card(Suit.heart, Rank.ace);
      final result = engine.evaluateGuess(drawn, neighbors, const Guess(GuessType.doesNotHaveSuit));
      expect(result, isTrue);
    });

    test('ExactSuit guess: correct when suit matches exactly', () {
      final engine = GameEngine.newGame();
      final neighbors = [
        const Card(Suit.spade, Rank.two),
        const Card(Suit.diamond, Rank.three),
        const Card(Suit.club, Rank.king),
        const Card(Suit.heart, Rank.ace),
      ];
      final drawn = const Card(Suit.heart, Rank.jack);
      final result = engine.evaluateGuess(
        drawn,
        neighbors,
        const Guess(GuessType.exactSuit, suit: Suit.heart),
      );
      expect(result, isTrue);
    });
  });
}
