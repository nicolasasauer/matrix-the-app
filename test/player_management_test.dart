import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_the_app/domain/models.dart';
import 'package:matrix_the_app/engine/game_engine.dart';
import 'package:matrix_the_app/providers/game_provider.dart';
import 'package:matrix_the_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const c7 = Card(Suit.club, Rank.seven);
const hK = Card(Suit.heart, Rank.king);
const d3 = Card(Suit.diamond, Rank.three);
const s5 = Card(Suit.spade, Rank.five);

GameProvider newGame(List<String> names, {List<Card>? deck}) {
  final g = GameProvider(StorageService());
  for (final n in names) {
    g.addPlayer(n);
  }
  g.startGame(
      engine: deck == null ? null : GameEngine.withDeck(Deck.fromCards(deck)));
  return g;
}

List<String> names(GameProvider g) => g.players.map((p) => p.name).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Reorder during a game', () {
    test('current player stays on turn after moving', () {
      final g = newGame(['A', 'B', 'C']);
      expect(g.currentPlayer!.name, 'A');
      g.reorderPlayers(0, 3); // A to the end
      expect(names(g), ['B', 'C', 'A']);
      expect(g.currentPlayer!.name, 'A');
      expect(g.nextPlayer!.name, 'B');
    });
  });

  group('Add / remove during a game', () {
    test('added player joins the rotation', () {
      final g = newGame(['A', 'B']);
      g.addPlayer('C');
      expect(names(g), ['A', 'B', 'C']);
      expect(g.currentPlayer!.name, 'A');
    });

    test('removing someone before the current player keeps the turn', () {
      final g = newGame(['A', 'B', 'C'], deck: [s5, s5, s5, d3, hK, c7]);
      // Make it B's turn: three correct calls by A, then pass.
      g.selectPosition(const Position(2, 3));
      g.makeGuess(const Guess(GuessType.higher)); // K > 7
      g.selectPosition(const Position(2, 1));
      g.makeGuess(const Guess(GuessType.lower)); // 3 < 7
      g.selectPosition(const Position(1, 2));
      g.makeGuess(const Guess(GuessType.lower)); // 5 < 7
      g.endTurn();
      expect(g.currentPlayer!.name, 'B');
      g.removePlayer(0, inGame: true);
      expect(names(g), ['B', 'C']);
      expect(g.currentPlayer!.name, 'B');
    });

    test('removing the current player hands the turn to the next one', () {
      final g = newGame(['A', 'B', 'C'], deck: [s5, s5, hK, c7]);
      g.selectPosition(const Position(2, 3));
      g.makeGuess(const Guess(GuessType.higher)); // correct, 1 call
      g.selectPosition(const Position(2, 1));
      expect(g.phase, GamePhase.makingGuess);

      g.removePlayer(0, inGame: true);
      expect(g.currentPlayer!.name, 'B');
      expect(g.turnCalls, 0);
      expect(g.selectedPosition, isNull);
      expect(g.phase, GamePhase.selectingPosition);
    });

    test('last active player cannot be removed or paused', () {
      final g = newGame(['A', 'B']);
      g.togglePlayerActive(1); // B sits out
      expect(g.canRemovePlayer(0, inGame: true), isFalse);
      g.removePlayer(0, inGame: true);
      g.togglePlayerActive(0);
      expect(names(g), ['A', 'B']);
      expect(g.players[0].active, isTrue);
    });

    test('current player cannot leave while the failure is shown', () {
      final g = newGame(['A', 'B'], deck: [s5, hK, c7]);
      g.selectPosition(const Position(2, 3));
      g.makeGuess(const Guess(GuessType.lower)); // K is higher → wrong
      expect(g.phase, GamePhase.showingFailure);
      expect(g.canRemovePlayer(0, inGame: true), isFalse);
      expect(g.canRemovePlayer(1, inGame: true), isTrue);
    });

    test('pausing the current player passes the turn', () {
      final g = newGame(['A', 'B', 'C']);
      g.togglePlayerActive(0);
      expect(g.currentPlayer!.name, 'B');
    });
  });

  group('Shuffle', () {
    test('keeps the same cards and a fixed order until shuffled again', () {
      final g = newGame(['A']);
      final before = g.engine!.deck.cards;
      expect(g.engine!.deck.cards, before, reason: 'order is stable');

      g.shuffleDeck(Random(42));
      final after = g.engine!.deck.cards;
      expect(after.length, before.length);
      expect(after.toSet(), before.toSet());
      expect(after, isNot(equals(before)));
      expect(g.engine!.deck.cards, after, reason: 'stable after shuffling');
      expect(g.shuffleCount, 1);
    });

    test('next drawn card follows the shuffled order', () {
      final g = newGame(['A']);
      g.shuffleDeck(Random(7));
      final top = g.engine!.deck.cards.last;
      g.selectPosition(const Position(2, 3));
      g.makeGuess(const Guess(GuessType.higher));
      expect(g.drawnCard, top);
    });
  });

  group('Mistakes return cards', () {
    test('cleared cards go back into the deck, which is shuffled', () {
      final g = newGame(['A', 'B']);
      final before = g.engine!.deck.remaining; // 51
      g.selectPosition(const Position(2, 3));
      // Force a wrong guess: pick the guess that loses for the top card.
      final top = g.engine!.deck.cards.last;
      final nucleus = g.engine!.getCard(const Position(2, 2))!;
      final guess = top.rank.value > nucleus.rank.value
          ? const Guess(GuessType.lower)
          : const Guess(GuessType.higher);
      g.makeGuess(guess);
      expect(g.phase, GamePhase.showingFailure);
      g.confirmFailure();

      // Row 2 held the nucleus and the drawn card → both back, new nucleus
      // drawn: 51 - 1 (drawn) + 2 (returned) - 1 (new nucleus) = 51.
      expect(g.engine!.deck.remaining, before);
      expect(g.lastReturnedCount, 2);
      expect(g.returnCount, 1);
      expect(g.shuffleCount, 1);

      final onTable = [
        for (final row in g.engine!.grid)
          for (final c in row)
            if (c != null) c
      ];
      final all = {...g.engine!.deck.cards, ...onTable};
      expect(all.length, 52, reason: 'no card lost or duplicated');
      expect(g.engine!.deck.cards.length + onTable.length, 52);
    });

    test('game does not end because of the deck', () {
      final g = newGame(['A']);
      expect(g.engine!.isGameFinished, isFalse);
    });

    test('game can be ended by hand, but not while sips are shown', () {
      final g = newGame(['A'], deck: [s5, hK, c7]);
      g.selectPosition(const Position(2, 3));
      g.makeGuess(const Guess(GuessType.lower)); // wrong
      expect(g.canEndGame, isFalse);
      g.endGame();
      expect(g.phase, GamePhase.showingFailure);
      g.confirmFailure();
      expect(g.canEndGame, isTrue);
      g.endGame();
      expect(g.phase, GamePhase.gameOver);
    });
  });
}
