import 'dart:async';
import 'package:flutter/foundation.dart';
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

  Player(this.name)
      : penaltyLog = [],
        maxReceivedMultiplier = 1,
        maxCreatedMultiplier = 0,
        active = true,
        correctGuesses = 0;

  int get totalPenalty => penaltyLog.fold(0, (sum, p) => sum + p);
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

  Position? _selectedPosition;
  Card? _drawnCard;
  int _clearedCards = 0;

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
  Position? get selectedPosition => _selectedPosition;
  Card? get drawnCard => _drawnCard;
  int get clearedCards => _clearedCards;

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
      _phase == GamePhase.selectingPosition ||
      _phase == GamePhase.makingGuess;

  int get activePlayerCount => _players.where((p) => p.active).length;

  void addPlayer(String name) {
    if (name.trim().isEmpty) return;
    _players.add(Player(name.trim()));
    notifyListeners();
  }

  void removePlayer(int index) {
    if (_players.length <= 1) return;
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
    _players = names.map((n) => Player(n)).toList();
    notifyListeners();
  }

  void startGame() {
    if (_players.isEmpty) return;
    _engine = GameEngine.newGame();
    _currentPlayerIndex = 0;
    _phase = GamePhase.selectingPosition;
    _turnCalls = 0;
    _inheritedMultiplier = 1;
    _globalMultiplier = 1;
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

  void selectPosition(Position pos) {
    if (!canInteract) return;
    if (_engine == null) return;
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
    final result = _engine!.placeCard(pos, guess);

    _drawnCard = _engine!.getCard(pos);

    if (result == PlaceResult.gameFinished) {
      _phase = GamePhase.gameOver;
      _saveGame(matrixFull: false);
      notifyListeners();
      return;
    }

    if (result == PlaceResult.wrong) {
      _phase = GamePhase.showingFailure;
      notifyListeners();
      return;
    }

    // Correct guess – check if the matrix is now completely filled
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
    currentPlayer?.penaltyLog.add(penalty);

    _globalMultiplier = 1;
    _inheritedMultiplier = 1;
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

    // Find next active player
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
    _currentPlayerIndex = next;

    final nextInherited = _globalMultiplier;

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
