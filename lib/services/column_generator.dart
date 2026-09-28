import 'dart:math';
import '../models/game_rules.dart';
import '../models/game_type.dart';

class GeneratedColumns {
  final List<List<int>> columns;
  final List<int> bonusNumbers;
  final bool hadFallback;
  const GeneratedColumns(this.columns, {this.bonusNumbers = const [], this.hadFallback = false});
}

class ColumnGenerator {
  final Random _random;
  ColumnGenerator({Random? random}) : _random = random ?? Random.secure();

  GeneratedColumns generate({
    required GameType game,
    required Set<int> pool,
    required int count,
    Set<String> existingKeys = const {},
    Set<int>? bonusPool,
  }) {
    final rules = gameRules[game]!;
    if (pool.length < rules.numbersPerColumn) throw StateError('Sayı havuzu en az ${rules.numbersPerColumn} sayı içermeli.');
    if (count <= 0) return const GeneratedColumns([]);
    final maxCombinations = _safeCombinationLimit(pool.length, rules.numbersPerColumn);
    final target = min(count, maxCombinations);
    final usage = {for (final n in pool) n: 0};
    final result = <List<int>>[];
    final keys = <String>{...existingKeys};
    var attempts = 0;
    final maxAttempts = max(500, target * 1000);
    var fallback = false;

    while (result.length < target && attempts++ < maxAttempts) {
      final candidates = pool.toList()..shuffle(_random);
      candidates.sort((a, b) => usage[a]!.compareTo(usage[b]!));
      final selected = candidates.take(rules.numbersPerColumn).toList()..sort();
      final key = selected.map((n) => n.toString().padLeft(2, '0')).join('-');
      if (keys.contains(key)) continue;
      keys.add(key);
      for (final n in selected) usage[n] = usage[n]! + 1;
      result.add(selected);
    }

    if (result.length < target) {
      fallback = true;
      for (var i = result.length; i < target; i++) {
        var tries = 0;
        List<int> selected;
        do {
          final list = pool.toList()..shuffle(_random);
          selected = (list.take(rules.numbersPerColumn).toList()..sort());
          tries++;
        } while (keys.contains(_key(selected)) && tries < 5000);
        if (keys.contains(_key(selected))) break;
        keys.add(_key(selected));
        result.add(selected);
      }
    }

    final bonusNumbers = <int>[];
    if (game == GameType.sansTopu && bonusPool != null && bonusPool.isNotEmpty) {
      final bp = bonusPool.toList()..shuffle(_random);
      for (var i = 0; i < result.length; i++) {
        bonusNumbers.add(bp[i % bp.length]);
      }
    }
    return GeneratedColumns(result, bonusNumbers: bonusNumbers, hadFallback: fallback);
  }

  String _key(List<int> c) => c.map((n) => n.toString().padLeft(2, '0')).join('-');
  int _safeCombinationLimit(int n, int k) {
    if (k > n) return 0;
    var value = 1;
    for (var i = 1; i <= k; i++) {
      value = min(1000000000, (value * (n - i + 1)) ~/ i);
    }
    return value;
  }
}
