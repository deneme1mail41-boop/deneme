import 'dart:async';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../models/draw.dart';
import '../models/game_type.dart';
import '../models/game_rules.dart';

class SyncResult {
  final int added;
  final int scanned;
  final String? latestDate;
  const SyncResult({required this.added, required this.scanned, this.latestDate});
}

/// Milli Piyango Online'ın herkese açık sonuç sayfalarını okur.
/// Sayfa yapısı değişirse yalnızca bu adapter'ın güncellenmesi gerekir.
class OfficialDrawService {
  static const _base = 'https://www.millipiyangoonline.com';
  static const _landing = <GameType, String>{
    GameType.sayisalLoto: '$_base/sayisal-loto/sonuclar',
    GameType.superLoto: '$_base/super-loto/super-loto-cekilis-sonuclari',
    GameType.onNumara: '$_base/on-numara/cekilis-sonuclari',
    GameType.sansTopu: '$_base/sans-topu/sonuclar',
  };

  final http.Client client;
  OfficialDrawService({http.Client? client}) : client = client ?? http.Client();

  Future<List<Draw>> fetchRecent(GameType game, {int maxPages = 2000}) async {
    final first = await _discoverLatest(game);
    if (first == null) throw StateError('Resmi sonuç sayfasında güncel çekiliş bağlantısı bulunamadı.');
    final out = <Draw>[];
    final visited = <String>{};
    var url = first;
    for (var i = 0; i < maxPages && url != null && !visited.contains(url); i++) {
      visited.add(url);
      final response = await client.get(Uri.parse(url), headers: {
        'User-Agent': 'LotoKolonUretici/1.0 (Flutter; official results reader)'
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) break;
      final parsed = _parse(game, url, response.body);
      if (parsed != null) out.add(parsed);
      url = _previousUrl(game, response.body, url) ?? url;
    }
    return out;
  }

  Future<String?> _discoverLatest(GameType game) async {
    final uri = Uri.parse(_landing[game]!);
    final response = await client.get(uri, headers: {'User-Agent': 'LotoKolonUretici/1.0'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final doc = html_parser.parse(response.body);
    final links = doc.querySelectorAll('a').map((a) => a.attributes['href']).whereType<String>();
    final candidates = links.where((href) => href.contains(_pathPrefix(game)) && RegExp(r'\.\d+\.\d{4}').hasMatch(href)).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => _pageNo(b).compareTo(_pageNo(a)));
    return _absolute(candidates.first);
  }

  String _pathPrefix(GameType game) => switch (game) {
    GameType.sayisalLoto => '/sayisal-loto/cekilis-sonuclari.',
    GameType.superLoto => '/super-loto/cekilis-sonuclari.',
    GameType.onNumara => '/on-numara/cekilis-sonuclari.',
    GameType.sansTopu => '/sans-topu/cekilis-sonuclari.',
  };

  int _pageNo(String href) => int.tryParse(RegExp(r'\.([0-9]+)\.\d{4}').firstMatch(href)?.group(1) ?? '') ?? 0;

  String _absolute(String href) => href.startsWith('http') ? href : '$_base${href.startsWith('/') ? '' : '/'}$href';

  String? _previousUrl(GameType game, String body, String current) {
    final doc = html_parser.parse(body);
    for (final a in doc.querySelectorAll('a')) {
      final label = a.text.trim().toLowerCase();
      if (label.contains('önceki çekiliş') || label.contains('onceki cekilis')) {
        final href = a.attributes['href'];
        if (href != null && href.contains(_pathPrefix(game))) return _absolute(href);
      }
    }
    return null;
  }

  Draw? _parse(GameType game, String sourceUrl, String body) {
    final doc = html_parser.parse(body);
    final text = doc.body?.text.replaceAll('\u00a0', ' ') ?? '';
    final drawMatch = RegExp(r'Çekiliş no:\s*(\d+)', caseSensitive: false).firstMatch(text);
    final dateMatch = RegExp(r'(\d{1,2})\s+(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s+(\d{4})').firstMatch(text);
    if (drawMatch == null || dateMatch == null) return null;
    final drawId = drawMatch.group(1)!;
    final drawDate = _date(dateMatch);
    final start = text.indexOf('Kazanan Numaralar');
    final end = text.indexOf('Kazanan Kategoriler', start + 1);
    if (start < 0 || end < 0) return null;
    final segment = text.substring(start + 'Kazanan Numaralar'.length, end);
    final nums = RegExp(r'(?<!\d)(\d{1,2})(?!\d)').allMatches(segment)
        .map((m) => int.parse(m.group(1)!)).toList();
    final rules = gameRules[game]!;
    if (nums.length < rules.drawNumbers) return null;
    if (game == GameType.sansTopu) {
      final main = nums.take(5).where((n) => n >= 1 && n <= 34).toList();
      final bonus = nums.skip(5).take(1).where((n) => n >= 1 && n <= 14).toList();
      if (main.length != 5 || bonus.length != 1) return null;
      return Draw(game: game, drawId: drawId, drawDate: drawDate, numbers: main, bonusNumbers: bonus, source: sourceUrl);
    }
    final max = rules.maxNumber;
    final main = nums.where((n) => n >= 1 && n <= max).toList();
    // Sayısal Loto sayfasında 6 ana sayıdan sonra Joker/SüperStar gelir; yalnızca ana çekilişi havuza alıyoruz.
    if (main.length < rules.drawNumbers) return null;
    return Draw(game: game, drawId: drawId, drawDate: drawDate,
      numbers: main.take(rules.drawNumbers).toList(), source: sourceUrl);
  }

  DateTime _date(RegExpMatch m) {
    const months = {'Ocak':1,'Şubat':2,'Mart':3,'Nisan':4,'Mayıs':5,'Haziran':6,'Temmuz':7,'Ağustos':8,'Eylül':9,'Ekim':10,'Kasım':11,'Aralık':12};
    return DateTime(int.parse(m.group(3)!), months[m.group(2)!]!, int.parse(m.group(1)!));
  }
}
