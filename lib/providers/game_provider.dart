import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../domain/game_record.dart';
import '../engine/game_engine.dart';
import '../services/storage_service.dart';

class Player {
  String name;
  List<int> penaltyLog;

  Player(this.name) : penaltyLog = [];

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
    notifyListeners();
  }

  void _updateMultiplier() {
    final bonusSets = (_turnCalls ~/ 3) - 1;
    _globalMultiplier = _inheritedMultiplier + (bonusSets < 0 ? 0 : bonusSets);
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

    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    final nextInherited = _globalMultiplier;

    _inheritedMultiplier = nextInherited;
    _globalMultiplier = nextInherited;
    _turnCalls = 0;
    _selectedPosition = null;
    _drawnCard = null;

    if (_engine!.isGameFinished) {
      _phase = GamePhase.gameOver;
      _saveGame(matrixFull: false);
    } else {
      _phase = GamePhase.selectingPosition;
    }
    notifyListeners();
  }

  List<Card> getNeighbors(Position pos) {
    if (_engine == null) return [];
    return _engine!.getOrthogonalNeighbors(pos);
  }

  int getNeighborCount(Position pos) => getNeighbors(pos).length;

  void _saveGame({required bool matrixFull}) {
    final record = GameRecord(
      playedAt: DateTime.now(),
      players: _players
          .map((p) => PlayerRecord(name: p.name, penaltyLog: List.of(p.penaltyLog)))
          .toList(),
      matrixFull: matrixFull,
    );
    _storage.saveGame(record);
  }
}
