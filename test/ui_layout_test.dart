import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_the_app/domain/models.dart';
import 'package:matrix_the_app/engine/game_engine.dart';
import 'package:matrix_the_app/main.dart';
import 'package:matrix_the_app/providers/game_provider.dart';
import 'package:matrix_the_app/providers/settings_provider.dart';
import 'package:matrix_the_app/services/settings_service.dart';
import 'package:matrix_the_app/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the app around a game with a fixed deck. Cards are drawn from the
/// end of [order], i.e. `order.last` becomes the centre card.
Future<GameProvider> pumpGame(WidgetTester tester, List<Card> order,
    {bool streak = true, bool odds = false, bool animations = false}) async {
  SharedPreferences.setMockInitialValues({
    'animations_enabled': animations,
    'streak_multiplier_enabled': streak,
    'show_probabilities': odds,
  });
  final settings = SettingsProvider(SettingsService());
  await settings.load();
  final game = GameProvider(StorageService())
    ..streakRuleEnabled = settings.streakMultiplierEnabled;
  for (final n in ['Alice', 'Bob', 'Charlie', 'Diana']) {
    game.addPlayer(n);
  }
  game.startGame(engine: GameEngine.withDeck(Deck.fromCards(order)));

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: game),
      ChangeNotifierProvider.value(value: settings),
    ],
    child: const MatrixApp(),
  ));
  await tester.pump();
  // Jump straight to the game screen.
  final nav = tester.state<NavigatorState>(find.byType(Navigator));
  nav.pushReplacementNamed('/game');
  await tester.pumpAndSettle();
  return game;
}

const c7 = Card(Suit.club, Rank.seven);
const hK = Card(Suit.heart, Rank.king);
const d3 = Card(Suit.diamond, Rank.three);
const s5 = Card(Suit.spade, Rank.five);
const hA = Card(Suit.heart, Rank.ace);
const filler = Card(Suit.club, Rank.two);

/// Small, medium and large phones (logical pixels).
const sizes = <Size>[Size(320, 568), Size(360, 640), Size(412, 915)];

Future<void> loadTestFonts() async {
  Future<void> load(String family, String asset) async {
    final loader = FontLoader(family)..addFont(rootBundle.load(asset));
    await loader.load();
  }

  await load(
      'BricolageGrotesque', 'assets/fonts/BricolageGrotesque-Variable.ttf');
  await load('JetBrainsMono', 'assets/fonts/JetBrainsMono-Variable.ttf');
  await load('NotoSansSymbols2', 'assets/fonts/NotoSansSymbols2-Regular.ttf');
  // Stand-in for the system body font so text widths are realistic.
  await load('Roboto', 'assets/fonts/BricolageGrotesque-Variable.ttf');
}

void main() {
  setUpAll(loadTestFonts);
  for (final size in sizes) {
    group('Layout ${size.width.toInt()}×${size.height.toInt()}', () {
      testWidgets('guess sheet fits without scrolling', (tester) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        final game = await pumpGame(
            tester, [filler, filler, filler, hA, s5, d3, hK, c7]);
        game.selectPosition(const Position(2, 3));
        await tester.pumpAndSettle();
        expect(find.text('Höher'), findsOneWidget);
        expect(find.byType(Scrollable), findsWidgets); // only player strip
        expect(tester.takeException(), isNull);
      });

      testWidgets('player dialog fits and shows controls', (tester) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await pumpGame(tester, [filler, hK, c7]);
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spieler verwalten'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.drag_indicator), findsNWidgets(4));
        expect(find.byIcon(Icons.person_remove_outlined), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      });

      testWidgets('decision sheet fits', (tester) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        final game = await pumpGame(
            tester, [filler, filler, filler, hA, s5, d3, hK, c7]);
        // K > 7, 3 < 7, A > 5 → three correct calls.
        game.selectPosition(const Position(2, 3));
        game.makeGuess(const Guess(GuessType.higher));
        game.selectPosition(const Position(2, 1));
        game.makeGuess(const Guess(GuessType.lower));
        game.selectPosition(const Position(1, 2));
        game.makeGuess(const Guess(GuessType.lower)); // 5 < 7
        await tester.pumpAndSettle();
        expect(game.phase, GamePhase.awaitingDecision);
        expect(find.text('Sichern & weitergeben'), findsOneWidget);
        await tester.ensureVisible(find.text('Weiterspielen'));
        expect(tester.takeException(), isNull);
      });

      testWidgets('failure confirm button is visible without scrolling',
          (tester) async {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        final game = await pumpGame(
            tester, [filler, filler, filler, hA, s5, d3, hK, c7]);
        game.selectPosition(const Position(2, 3));
        game.makeGuess(const Guess(GuessType.lower)); // K is higher → wrong
        await tester.pumpAndSettle();
        expect(game.phase, GamePhase.showingFailure);

        final button = find.text('Abräumen');
        expect(button, findsOneWidget);
        final rect = tester.getRect(button);
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);

        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(game.phase, GamePhase.selectingPosition);
        expect(game.currentPlayer!.totalPenalty, 2); // 7 + K cleared × 1
      });
    });
  }

  testWidgets('odds are hidden unless enabled in the settings', (tester) async {
    tester.view.physicalSize = const Size(360, 640) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final game = await pumpGame(tester, [filler, hK, c7]);
    game.selectPosition(const Position(2, 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('%'), findsNothing);
  });

  test('odds setting defaults to off', () async {
    SharedPreferences.setMockInitialValues({});
    final s = SettingsProvider(SettingsService());
    await s.load();
    expect(s.showProbabilities, isFalse);
  });
}
