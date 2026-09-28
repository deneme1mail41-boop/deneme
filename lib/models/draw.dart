import 'dart:convert';
import 'game_type.dart';

class Draw {
  final int? id;
  final GameType game;
  final String drawId;
  final DateTime drawDate;
  final List<int> numbers;
  final List<int> bonusNumbers;
  final String source;

  const Draw({this.id, required this.game, required this.drawId, required this.drawDate,
    required this.numbers, this.bonusNumbers = const [], required this.source});

  Map<String, Object?> toMap() => {
    'id': id, 'game_type': game.key, 'draw_id': drawId,
    'draw_date': drawDate.toIso8601String(),
    'numbers_json': jsonEncode(numbers), 'bonus_json': jsonEncode(bonusNumbers),
    'source': source,
  };

  factory Draw.fromMap(Map<String, Object?> m) => Draw(
    id: m['id'] as int?, game: gameTypeFromKey(m['game_type'] as String),
    drawId: m['draw_id'] as String, drawDate: DateTime.parse(m['draw_date'] as String),
    numbers: (jsonDecode(m['numbers_json'] as String) as List).cast<int>(),
    bonusNumbers: (jsonDecode(m['bonus_json'] as String) as List).cast<int>(),
    source: m['source'] as String,
  );
}
