import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/draw.dart';
import '../models/generated_set.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'loto_kolon_uretici.db');
    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''CREATE TABLE draws(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_type TEXT NOT NULL,
        draw_id TEXT NOT NULL,
        draw_date TEXT NOT NULL,
        numbers_json TEXT NOT NULL,
        bonus_json TEXT NOT NULL,
        source TEXT NOT NULL,
        UNIQUE(game_type, draw_id)
      )''');
      await db.execute('''CREATE TABLE generated_sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        column_count INTEGER NOT NULL,
        algorithm_version TEXT NOT NULL,
        columns_json TEXT NOT NULL
      )''');
      await db.execute('''CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL)''');
    });
  }

  Future<int> insertDraw(Draw draw, DatabaseExecutor executor) async =>
      executor.insert('draws', draw.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);

  Future<List<Draw>> draws(String gameKey) async {
    final d = await db;
    final rows = await d.query('draws', where: 'game_type=?', whereArgs: [gameKey], orderBy: 'draw_date DESC');
    return rows.map((e) => Draw.fromMap(e)).toList();
  }

  Future<int> drawCount(String gameKey) async {
    final d = await db;
    final r = await d.rawQuery('SELECT COUNT(*) c FROM draws WHERE game_type=?', [gameKey]);
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> insertGeneratedSet(GeneratedSet set) async {
    final d = await db;
    await d.insert('generated_sets', set.toMap());
  }

  Future<List<GeneratedSet>> generatedSets() async {
    final d = await db;
    final rows = await d.query('generated_sets', orderBy: 'created_at DESC');
    return rows.map(GeneratedSet.fromMap).toList();
  }

  Future<void> setMeta(String key, String value) async {
    final d = await db;
    await d.insert('metadata', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMeta(String key) async {
    final d = await db;
    final rows = await d.query('metadata', where: 'key=?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }
}
