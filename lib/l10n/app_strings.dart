/// Centralised string constants for the Matrix app.
///
/// All user-visible strings are defined here so they can be easily migrated
/// to `.arb` files and `flutter_localizations` in the future.
///
/// Usage:
/// ```dart
/// Text(AppStrings.appTitle)
/// Text(AppStrings.sips(3))
/// ```
class AppStrings {
  AppStrings._();

  // ── AppBar / Navigation ──────────────────────────────────────────────────

  static const String appTitle = 'Matrix';
  static const String noGameStarted = 'Kein Spiel gestartet';

  static const String endGameTitle = 'Spiel beenden?';
  static const String endGameContent =
      'Möchtest du wirklich zum Startmenü? Das laufende Spiel wird abgebrochen.';
  static const String cancel = 'Abbrechen';
  static const String yesEnd = 'Ja, beenden';

  static const String managePlayersTitle = 'Spieler verwalten';
  static const String settingsTitle = 'Einstellungen';

  // ── Player Info Bar ───────────────────────────────────────────────────────

  static String callsAndPenalty(int calls, int penalty) =>
      'Calls: $calls/3  |  Strafe: $penalty ';
  static String remainingCards(int n) => '$n Karten';

  // ── Guess Controls ────────────────────────────────────────────────────────

  static String neighborCount(int count) =>
      '$count Nachbar${count == 1 ? '' : 'n'}';
  static const String higher = '▲ Höher';
  static const String lower = '▼ Niedriger';
  static const String inside = 'Dazwischen';
  static const String outside = 'Außerhalb';
  static const String hasSuit = '✓ Hat Farbe';
  static const String doesNotHaveSuit = '✗ Hat nicht';
  static const String cancelSelection = 'Abbrechen';

  // ── Failure Banner ────────────────────────────────────────────────────────

  static String playerFailed(String name) => '$name hat verkackt!';
  static const String drawnCard = 'Gezogene Karte';
  static const String sip = 'Schluck';
  static const String sips = 'Schlücke';
  static String sipsLabel(int count) => count == 1 ? sip : AppStrings.sips;
  static const String rowColCleared = 'Zeile & Spalte werden abgeräumt';
  static const String confirmClear = 'Abräumen';

  // ── Decision Dialog ───────────────────────────────────────────────────────

  static String correctCallsCount(int count) => '$count richtige Tipps!';
  static String multiplierLabel(int m) => 'Multiplikator: ${m}x';
  static const String continuePlay = 'Weitermachen';
  static const String endTurn = 'Zug beenden';
  static const String decisionTitle = '🔥 Entscheidung!';
  static const String decisionSaveAndPass = 'Sichern & Weitergeben';
  static const String decisionContinue = 'Weitermachen';

  // ── Game Over ─────────────────────────────────────────────────────────────

  static const String gameOver = 'Spiel vorbei!';
  static const String showResult = 'Ergebnis anzeigen';

  // ── Matrix Full ───────────────────────────────────────────────────────────

  static const String matrixFull = 'MATRIX VOLL!';
  static const String matrixFullSubtitle =
      'Unglaublich! Ihr habt die gesamte Matrix gelegt!';
  static const String matrixFullLegend =
      'Das schafft fast niemand – ihr seid Legenden! 🌟';

  // ── Player Management Dialog ──────────────────────────────────────────────

  static const String addPlayerHint = 'Spieler hinzufügen';
  static const String add = 'Hinzufügen';
}
