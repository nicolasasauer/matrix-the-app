import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../domain/models.dart';
import '../domain/game_record.dart';
import '../engine/game_engine.dart';
import '../services/storage_service.dart';

class Player {
  String name;
  List<int> penaltyLog;
  int maxReceivedMultiplier;
  int maxCreatedMultiplier;
  bool active;
  int correctGuesses;

  /// Stable index into the player colour palette.
  final int colorIndex;

  Player(this.name, {this.colorIndex = 0})
      : penaltyLog = [],
        maxReceivedMultiplier = 1,
        maxCreatedMultiplier = 0,
        active = true,
        correctGuesses = 0;

  int get totalPenalty => penaltyLog.fold(0, (sum, p) => sum + p);
  int get wrongGuesses => penaltyLog.length;
  int get maxSinglePenalty =>
      penaltyLog.isEmpty ? 0 : penaltyLog.reduce((a, b) => a > b ? a : b);
}

/// One mistake in the order it happened, for the result timeline.
class PenaltyEvent {
  final String playerName;
  final int colorIndex;
  final int penalty;
  const PenaltyEvent(this.playerName, this.colorIndex, this.penalty);
}

enum GamePhase {
  selectingPosition,
  makingGuess,
  showingFailure,
  awaitingDecision,
  matrixFull,
  gameOver,
}

class GameProvider extends ChangeNotifier {
  final StorageService _storage;

  GameProvider(this._storage);

  List<Player> _players = [];
  int _currentPlayerIndex = 0;
  GameEngine? _engine;
  GamePhase _phase = GamePhase.selectingPosition;

  int _turnCalls = 0;
  int _inheritedMultiplier = 1;
  int _globalMultiplier = 1;

  /// House rule (optional): each turn passed on without a mistake adds +1 to
  /// the multiplier handed to the next player (2x, 3x, 4x, ...). Resets on the
  /// next mistake.
  bool streakRuleEnabled = false;
  int _cleanPasses = 0;

  Position? _selectedPosition;
  Card? _drawnCard;
  int _clearedCards = 0;
  int _nextColorIndex = 0;

  Guess? _lastGuess;
  List<Card> _lastNeighbors = const [];
  int _pendingClearCount = 0;
  final List<PenaltyEvent> _penaltyTimeline = [];

  StorageService get storageService => _storage;

  List<Player> get players => List.unmodifiable(_players);
  int get currentPlayerIndex => _currentPlayerIndex;
  Player? get currentPlayer =>
      _players.isEmpty ? null : _players[_currentPlayerIndex];
  GameEngine? get engine => _engine;
  GamePhase get phase => _phase;
  int get turnCalls => _turnCalls;
  int get globalMultiplier => _globalMultiplier;
  int get inheritedMultiplier => _inheritedMultiplier;

  /// Number of consecutive turns passed on without a mistake.
  int get cleanPasses => _cleanPasses;

  /// The multiplier the next player receives if the current player ends the
  /// turn now.
  int get passOnMultiplier =>
      nextMultiplier(_globalMultiplier, streakRule: streakRuleEnabled);

  /// Pure helper so the pass-on rule can be unit-tested.
  static int nextMultiplier(int current, {required bool streakRule}) =>
      streakRule ? current + 1 : current;
  Position? get selectedPosition => _selectedPosition;
  Card? get drawnCard => _drawnCard;
  int get clearedCards => _clearedCards;

  /// The guess and the neighbours it was made against (for the failure screen).
  Guess? get lastGuess => _lastGuess;
  List<Card> get lastNeighbors => _lastNeighbors;

  /// Number of cards that [confirmFailure] will clear (incl. the drawn card).
  int get pendingClearCount => _pendingClearCount;

  List<PenaltyEvent> get penaltyTimeline => List.unmodifiable(_penaltyTimeline);

  /// The active player who comes after the current one.
  Player? get nextPlayer =>
      _players.isEmpty ? null : _players[_nextActiveIndex()];

  /// Cards a mistake at [pos] would clear: everything in its row and column
  /// plus the card that would be placed there.
  int previewClearCount(Position pos) {
    if (_engine == null) return 0;
    final existing = _engine!.countCardsToBeCleared(pos);
    return _engine!.getCard(pos) == null ? existing + 1 : existing;
  }

  /// Sips a mistake at [pos] would cost right now.
  int previewPenalty(Position pos) =>
      previewClearCount(pos) * _inheritedMultiplier;

  /// Chance that [guess] at [pos] is right, based on the cards not seen yet.
  /// Returns null when it cannot be computed.
  double? guessProbability(Position pos, Guess guess) {
    final engine = _engine;
    if (engine == null) return null;
    final unseen = engine.deck.cards;
    if (unseen.isEmpty) return null;
    final neighbors = engine.getOrthogonalNeighbors(pos);
    final hits =
        unseen.where((c) => engine.evaluateGuess(c, neighbors, guess)).length;
    return hits / unseen.length;
  }

  /// The drink penalty that will be assigned when [confirmFailure] is called.
  /// Only meaningful during the [GamePhase.showingFailure] phase.
  int get pendingPenalty {
    if (_phase != GamePhase.showingFailure ||
        _engine == null ||
        _selectedPosition == null) {
      return 0;
    }
    return _engine!.countCardsToBeCleared(_selectedPosition!) *
        _inheritedMultiplier;
  }

  bool get canInteract =>
      _phase == GamePhase.selectingPosition || _phase == GamePhase.makingGuess;

  int get activePlayerCount => _players.where((p) => p.active).length;

  void addPlayer(String name) {
    if (name.trim().isEmpty) return;
    _players.add(Player(name.trim(), colorIndex: _nextColorIndex++));
    notifyListeners();
  }

  void reorderPlayers(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _players.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final current = currentPlayer;
    final p = _players.removeAt(oldIndex);
    _players.insert(newIndex.clamp(0, _players.length), p);
    if (current != null) _currentPlayerIndex = _players.indexOf(current);
    notifyListeners();
  }

  void removePlayer(int index) {
    if (index < 0 || index >= _players.length) return;
    _players.removeAt(index);
    if (_currentPlayerIndex >= _players.length) {
      _currentPlayerIndex = 0;
    }
    notifyListeners();
  }

  void togglePlayerActive(int index) {
    if (index < 0 || index >= _players.length) return;
    final player = _players[index];
    if (player.active && activePlayerCount <= 1) return;
    player.active = !player.active;
    notifyListeners();
  }

  void setPlayers(List<String> names) {
    _nextColorIndex = 0;
    _players =
        names.map((n) => Player(n, colorIndex: _nextColorIndex++)).toList();
    notifyListeners();
  }

  /// Starts a new round with the current players. [engine] can be injected
  /// (e.g. with a fixed deck in tests).
  void startGame({GameEngine? engine}) {
    if (_players.isEmpty) return;
    _engine = engine ?? GameEngine.newGame();
    _penaltyTimeline.clear();
    _lastGuess = null;
    _lastNeighbors = const [];
    _pendingClearCount = 0;
    _currentPlayerIndex = 0;
    _phase = GamePhase.selectingPosition;
    _turnCalls = 0;
    _inheritedMultiplier = 1;
    _globalMultiplier = 1;
    _cleanPasses = 0;
    _selectedPosition = null;
    _drawnCard = null;
    for (final p in _players) {
      p.penaltyLog.clear();
      p.maxReceivedMultiplier = 1;
      p.maxCreatedMultiplier = 0;
      p.active = true;
      p.correctGuesses = 0;
    }
    unawaited(_storage.clearCurrentGame().catchError((_) {}));
    notifyListeners();
  }

  /// Selects [pos] for the next guess. Tapping another valid cell while a
  /// guess is pending switches the selection; tapping the same cell cancels.
  void selectPosition(Position pos) {
    if (!canInteract) return;
    if (_engine == null) return;
    if (_phase == GamePhase.makingGuess && _selectedPosition == pos) {
      cancelSelection();
      return;
    }
    if (!_engine!.isValidPosition(pos)) return;
    _selectedPosition = pos;
    _phase = GamePhase.makingGuess;
    notifyListeners();
  }

  void cancelSelection() {
    if (_phase != GamePhase.makingGuess) return;
    _selectedPosition = null;
    _phase = GamePhase.selectingPosition;
    notifyListeners();
  }

  void makeGuess(Guess guess) {
    if (_phase != GamePhase.makingGuess) return;
    if (_engine == null || _selectedPosition == null) return;

    final pos = _selectedPosition!;
    _lastGuess = guess;
    _lastNeighbors = _engine!.getOrthogonalNeighbors(pos);
    final result = _engine!.placeCard(pos, guess);

    _drawnCard = _engine!.getCard(pos);

    if (result == PlaceResult.gameFinished) {
      _phase = GamePhase.gameOver;
      _saveGame(matrixFull: false);
      notifyListeners();
      return;
    }

    if (result == PlaceResult.wrong) {
      HapticFeedback.mediumImpact();
      _pendingClearCount = _engine!.countCardsToBeCleared(pos);
      _phase = GamePhase.showingFailure;
      notifyListeners();
      return;
    }

    // Correct guess – check if the matrix is now completely filled
    HapticFeedback.lightImpact();
    currentPlayer?.correctGuesses++;
    if (_engine!.isMatrixFull) {
      _phase = GamePhase.matrixFull;
      _saveGame(matrixFull: true);
      notifyListeners();
      return;
    }

    _turnCalls++;
    _updateMultiplier();

    if (_turnCalls % 3 == 0) {
      _phase = GamePhase.awaitingDecision;
    } else {
      _phase = GamePhase.selectingPosition;
    }
    _autoSave();
    notifyListeners();
  }

  void _updateMultiplier() {
    final bonusSets = (_turnCalls ~/ 3) - 1;
    _globalMultiplier = _inheritedMultiplier + (bonusSets < 0 ? 0 : bonusSets);
    final bonus = _globalMultiplier - _inheritedMultiplier;
    final p = currentPlayer;
    if (p != null && bonus > p.maxCreatedMultiplier) {
      p.maxCreatedMultiplier = bonus;
    }
  }

  void confirmFailure() {
    if (_phase != GamePhase.showingFailure) return;
    if (_engine == null || _selectedPosition == null) return;

    final pos = _selectedPosition!;
    _clearedCards = _engine!.applyFailure(pos);

    final penalty = _clearedCards * _inheritedMultiplier;
    final p = currentPlayer;
    if (p != null) {
      p.penaltyLog.add(penalty);
      _penaltyTimeline.add(PenaltyEvent(p.name, p.colorIndex, penalty));
    }
    _pendingClearCount = 0;

    _globalMultiplier = 1;
    _inheritedMultiplier = 1;
    _cleanPasses = 0;
    _turnCalls = 0;
    _selectedPosition = null;
    _drawnCard = null;

    if (_engine!.isGameFinished) {
      _phase = GamePhase.gameOver;
      _saveGame(matrixFull: false);
    } else {
      _phase = GamePhase.selectingPosition;
      _autoSave();
    }
    notifyListeners();
  }

  void continuePlay() {
    if (_phase != GamePhase.awaitingDecision) return;
    _phase = GamePhase.selectingPosition;
    notifyListeners();
  }

  void endTurn() {
    if (_phase != GamePhase.awaitingDecision) return;

    _currentPlayerIndex = _nextActiveIndex();

    final nextInherited = passOnMultiplier;
    if (streakRuleEnabled) _cleanPasses++;

    _inheritedMultiplier = nextInherited;
    _globalMultiplier = nextInherited;
    _turnCalls = 0;
    _selectedPosition = null;
    _drawnCard = null;

    // Track received multiplier for the next player
    final nextPlayer = _players[_currentPlayerIndex];
    if (nextInherited > nextPlayer.maxReceivedMultiplier) {
      nextPlayer.maxReceivedMultiplier = nextInherited;
    }

    if (_engine!.isGameFinished) {
      _phase = GamePhase.gameOver;
      _saveGame(matrixFull: false);
    } else {
      _phase = GamePhase.selectingPosition;
      _autoSave();
    }
    notifyListeners();
  }

  int _nextActiveIndex() {
    if (_players.isEmpty) return 0;
    int next = (_currentPlayerIndex + 1) % _players.length;
    int attempts = 0;
    while (!_players[next].active && attempts < _players.length) {
      next = (next + 1) % _players.length;
      attempts++;
    }
    // Fall back to next index if no active player found (safety guard)
    if (!_players[next].active) {
      next = (_currentPlayerIndex + 1) % _players.length;
    }
    return next;
  }

  List<Card> getNeighbors(Position pos) {
    if (_engine == null) return [];
    return _engine!.getOrthogonalNeighbors(pos);
  }

  int getNeighborCount(Position pos) => getNeighbors(pos).length;

  void _autoSave() {
    final record = _buildRecord(matrixFull: _phase == GamePhase.matrixFull);
    unawaited(_storage.saveCurrentGame(record).catchError((_) {}));
  }

  void saveToHistory() {
    _saveGame(matrixFull: _phase == GamePhase.matrixFull);
  }

  GameRecord _buildRecord({required bool matrixFull}) {
    return GameRecord(
      playedAt: DateTime.now(),
      players: _players
          .map((p) => PlayerRecord(
                name: p.name,
                penaltyLog: List.of(p.penaltyLog),
                maxReceivedMultiplier: p.maxReceivedMultiplier,
                maxCreatedMultiplier: p.maxCreatedMultiplier,
                correctGuesses: p.correctGuesses,
              ))
          .toList(),
      matrixFull: matrixFull,
    );
  }

  void _saveGame({required bool matrixFull}) {
    final record = _buildRecord(matrixFull: matrixFull);
    unawaited(_storage.saveGame(record).catchError((_) {}));
    unawaited(_storage.clearCurrentGame().catchError((_) {}));
  }
}
