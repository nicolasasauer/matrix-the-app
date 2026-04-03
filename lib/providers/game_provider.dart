import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../engine/game_engine.dart';

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
  gameOver,
}

class GameProvider extends ChangeNotifier {
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
      notifyListeners();
      return;
    }

    if (result == PlaceResult.wrong) {
      _phase = GamePhase.showingFailure;
      notifyListeners();
      return;
    }

    // Correct guess
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
}
