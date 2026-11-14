import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_the_app/providers/game_provider.dart';

void main() {
  group('Streak multiplier rule', () {
    test('disabled: multiplier is passed on unchanged', () {
      expect(GameProvider.nextMultiplier(1, streakRule: false), 1);
      expect(GameProvider.nextMultiplier(3, streakRule: false), 3);
    });

    test('enabled: each clean pass adds +1 (2x, 3x, 4x)', () {
      var m = 1;
      final seen = <int>[];
      for (var i = 0; i < 3; i++) {
        m = GameProvider.nextMultiplier(m, streakRule: true);
        seen.add(m);
      }
      expect(seen, [2, 3, 4]);
    });

    test('enabled: stacks with the existing continue-bonus', () {
      // Player inherited 2x and raised it to 3x by continuing → next gets 4x.
      expect(GameProvider.nextMultiplier(3, streakRule: true), 4);
    });
  });
}
