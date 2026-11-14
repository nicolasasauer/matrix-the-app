/// Centralised string constants for the Matrix app.
///
/// All user-visible strings are defined here so they can be easily migrated
/// to `.arb` files and `flutter_localizations` in the future.
class AppStrings {
  AppStrings._();

  // ── App / Navigation ─────────────────────────────────────────────────────

  static const String appTitle = 'Matrix';
  static const String appTagline = '5 × 5 Karten. Wer falsch tippt, trinkt.';
  static const String noGameStarted = 'Kein Spiel gestartet';

  static const String endGameTitle = 'Spiel beenden?';
  static const String endGameContent =
      'Möchtest du wirklich zum Startmenü? Das laufende Spiel wird abgebrochen.';
  static const String cancel = 'Abbrechen';
  static const String yesEnd = 'Ja, beenden';

  static const String managePlayersTitle = 'Spieler verwalten';
  static const String settingsTitle = 'Einstellungen';
  static const String scoreboardTitle = 'Auswertung';
  static const String rulesTitle = 'Regeln';
  static const String historyTitle = 'Verlauf';
  static const String backToMenu = 'Zum Startmenü';

  // ── Setup ────────────────────────────────────────────────────────────────

  static String roundLabel(int players) => 'RUNDE · $players SPIELER';
  static const String houseRules = 'HAUSREGELN';
  static const String addPlayerHint = 'Spieler hinzufügen';
  static const String startGame = 'Spiel starten';
  static String startsFirst(String name) => '$name beginnt';
  static const String needPlayers = 'Füge mindestens einen Spieler hinzu';
  static const String removePlayer = 'Spieler entfernen';
  static const String reorderHint = 'Ziehen zum Sortieren';

  // ── Settings / house rules ───────────────────────────────────────────────

  static const String animations = 'Animationen';
  static const String animationsDescription = 'Kartenflip und Wackeln';
  static const String streakRuleTitle = 'Streak-Multiplikator';
  static const String streakRuleDescription =
      'Jede fehlerfreie Weitergabe: +1x (2x, 3x, 4x …), bis jemand '
      'einen Fehler macht.';
  static const String probabilitiesTitle = 'Trefferchancen zeigen';
  static const String probabilitiesDescription =
      'Prozente auf den Tipp-Knöpfen, berechnet aus den noch nicht '
      'gezogenen Karten.';

  // ── HUD ──────────────────────────────────────────────────────────────────

  static String sipsShort(int n) => '$n Schl.';
  static const String cardsInDeck = 'im Stapel';
  static String streakLine(int passes) =>
      '$passes ${passes == 1 ? 'Zug' : 'Züge'} fehlerfrei';
  static String passOnLine(int m) => 'Weitergabe: ${m}x';
  static String callsProgress(int n) => '$n von 3 Tipps';
  static String streakTooltip(int passes) =>
      '$passes Zug${passes == 1 ? '' : 'e'} ohne Fehler weitergegeben';

  // ── Guess sheet ──────────────────────────────────────────────────────────

  static const String pickCell = 'Tippe auf ein freies Feld';
  static const String pickCellHint =
      'Die Zahl im Feld zeigt, wie viele Nachbarn es hat. '
      'Davon hängt die Frage ab.';
  static String neighborCount(int count) =>
      '$count Nachbar${count == 1 ? '' : 'n'}';
  static String guessQuestion(int neighbors) => switch (neighbors) {
        1 => 'Höher oder niedriger?',
        2 => 'Liegt die Karte dazwischen?',
        3 => 'Hat sie eine dieser Farben?',
        4 => 'Welche Farbe kommt?',
        _ => '',
      };
  static String riskCalc(int cards, int m) =>
      'Fehler: $cards ${cards == 1 ? 'Karte' : 'Karten'} × ${m}x';
  static String sipsCount(int n) => '$n ${sipsLabel(n)}';
  static const String switchCellHint = 'Anderes Feld antippen zum Wechseln';
  static const String impossible = 'unmöglich';
  static const String higher = 'Höher';
  static const String lower = 'Niedriger';
  static const String inside = 'Dazwischen';
  static const String outside = 'Außerhalb';
  static const String hasSuit = 'Hat Farbe';
  static const String doesNotHaveSuit = 'Hat nicht';

  // ── Failure screen ───────────────────────────────────────────────────────

  static String playerDrinks(String name) => '$name, trink!';
  static String guessed(String what) => 'Getippt: $what';
  static const String drawn = 'Gezogen:';
  static const String sip = 'Schluck';
  static const String sips = 'Schlücke';
  static String sipsLabel(int count) => count == 1 ? sip : sips;
  static String failureCalc(int cards, int m) =>
      '$cards ${cards == 1 ? 'Karte' : 'Karten'} × Pegel ${m}x';
  static const String confirmClear = 'Abräumen';
  static String afterFailure(String name, bool resetsLevel) => resetsLevel
      ? 'Pegel fällt auf 1x · $name spielt weiter'
      : '$name spielt weiter';

  // ── Decision ─────────────────────────────────────────────────────────────

  static String correctInARow(int count) => '$count richtig in Folge';
  static const String decisionSaveAndPass = 'Sichern & weitergeben';
  static String decisionSaveSubtitle(String next) =>
      '$next startet mit diesem Pegel';
  static const String decisionContinue = 'Weiterspielen';
  static String decisionContinueSubtitle(int own, int target) =>
      'Dein Fehler kostet weiter ${own}x pro Karte. '
      '3 weitere Treffer erhöhen auf ${target}x.';

  // ── End of game ──────────────────────────────────────────────────────────

  static const String gameOver = 'Stapel leer – Spiel vorbei';
  static const String showResult = 'Auswertung ansehen';
  static const String matrixFull = 'Matrix voll!';
  static const String matrixFullSubtitle =
      'Ihr habt alle 25 Felder gelegt. Das schafft fast niemand.';

  // ── Scoreboard ───────────────────────────────────────────────────────────

  static const String ranking = 'RANGLISTE';
  static const String timeline = 'FEHLER IM SPIELVERLAUF';
  static const String fewestSips = 'wenigste Schlücke';
  static String hits(int n) => '$n Treffer';
  static String misses(int n) => '$n ${n == 1 ? 'Fehler' : 'Fehler'}';
  static String receivedMax(int m) => 'höchster Pegel bekommen ${m}x';
  static String createdMax(int m) => '+${m}x erzeugt';
  static String worstMiss(int n) => 'teuerster Fehler: $n';
  static const String rematch = 'Revanche';
  static const String backToGame = 'Zurück zum Spiel';
  static const String saveProgress = 'Zwischenspeichern';
  static const String saved = 'Spielstand gespeichert';
  static const String gameRunning = 'Spiel läuft noch';
  static const String gameFinished = 'Spiel beendet';
  static const String noMistakes = 'Noch keine Fehler – Respekt.';

  // ── Player management ────────────────────────────────────────────────────

  static const String newPlayerHint = 'Neuer Spieler…';
  static const String add = 'Hinzufügen';
  static const String done = 'Fertig';
}
