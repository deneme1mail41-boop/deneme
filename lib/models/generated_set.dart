import 'dart:convert';
import 'game_type.dart';

class GeneratedSet {
  final int? id;
  final GameType game;
  final DateTime createdAt;
  final int columnCount;
  final String algorithmVersion;
  final List<String> columns;

  const GeneratedSet({this.id, required this.game, required this.createdAt,
    required this.columnCount, required this.algorithmVersion, required this.columns});

  Map<String, Object?> toMap() => {
    'id': id, 'game_type': game.key, 'created_at': createdAt.toIso8601String(),
    'column_count': columnCount, 'algorithm_version': algorithmVersion,
    'columns_json': jsonEncode(columns),
  };

  factory GeneratedSet.fromMap(Map<String, Object?> m) => GeneratedSet(
    id: m['id'] as int?, game: gameTypeFromKey(m['game_type'] as String),
    createdAt: DateTime.parse(m['created_at'] as String), columnCount: m['column_count'] as int,
    algorithmVersion: m['algorithm_version'] as String,
    columns: (jsonDecode(m['columns_json'] as String) as List).cast<String>(),
  );
}
