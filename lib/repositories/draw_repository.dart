import '../data/database.dart';
import '../models/draw.dart';
import '../models/game_type.dart';
import '../services/official_draw_service.dart';

class DrawRepository {
  final AppDatabase db;
  final OfficialDrawService remote;
  DrawRepository({AppDatabase? db, OfficialDrawService? remote}) : db = db ?? AppDatabase.instance, remote = remote ?? OfficialDrawService();

  Future<List<Draw>> local(GameType game) => db.draws(game.key);

  Future<SyncResult> sync(GameType game) async {
    final remoteDraws = await remote.fetchRecent(game);
    final database = await db.db;
    var added = 0;
    await database.transaction((txn) async {
      for (final draw in remoteDraws) {
        added += await db.insertDraw(draw, txn);
      }
    });
    if (remoteDraws.isNotEmpty) await db.setMeta('last_sync_${game.key}', DateTime.now().toIso8601String());
    return SyncResult(added: added, scanned: remoteDraws.length,
      latestDate: remoteDraws.isEmpty ? null : remoteDraws.first.drawDate.toIso8601String());
  }

  Future<Set<int>> numberPool(GameType game) async {
    final rows = await local(game);
    final pool = <int>{};
    for (final d in rows) pool.addAll(d.numbers);
    return pool;
  }

  Future<Set<int>> bonusPool(GameType game) async {
    final rows = await local(game);
    final pool = <int>{};
    for (final d in rows) pool.addAll(d.bonusNumbers);
    return pool;
  }

  Future<int> count(GameType game) => db.drawCount(game.key);
  Future<String?> lastSync(GameType game) => db.getMeta('last_sync_${game.key}');
}
