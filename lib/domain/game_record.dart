class PlayerRecord {
  final String name;
  final List<int> penaltyLog;
  final int maxReceivedMultiplier;
  final int maxCreatedMultiplier;

  const PlayerRecord({
    required this.name,
    required this.penaltyLog,
    this.maxReceivedMultiplier = 1,
    this.maxCreatedMultiplier = 0,
  });

  int get totalPenalty => penaltyLog.fold(0, (sum, p) => sum + p);

  Map<String, dynamic> toJson() => {
        'name': name,
        'penaltyLog': penaltyLog,
        'maxReceivedMultiplier': maxReceivedMultiplier,
        'maxCreatedMultiplier': maxCreatedMultiplier,
      };

  factory PlayerRecord.fromJson(Map<String, dynamic> json) => PlayerRecord(
        name: json['name'] as String,
        penaltyLog: (json['penaltyLog'] as List).cast<int>(),
        maxReceivedMultiplier:
            (json['maxReceivedMultiplier'] as int?) ?? (json['maxMultiplier'] as int?) ?? 1,
        maxCreatedMultiplier: (json['maxCreatedMultiplier'] as int?) ?? 0,
      );
}

class GameRecord {
  final DateTime playedAt;
  final List<PlayerRecord> players;
  final bool matrixFull;

  const GameRecord({
    required this.playedAt,
    required this.players,
    this.matrixFull = false,
  });

  Map<String, dynamic> toJson() => {
        'playedAt': playedAt.toIso8601String(),
        'players': players.map((p) => p.toJson()).toList(),
        'matrixFull': matrixFull,
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
        playedAt: DateTime.parse(json['playedAt'] as String),
        players: (json['players'] as List)
            .map((p) => PlayerRecord.fromJson(p as Map<String, dynamic>))
            .toList(),
        matrixFull: json['matrixFull'] as bool? ?? false,
      );
}
