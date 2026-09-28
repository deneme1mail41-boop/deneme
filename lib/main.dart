import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'data/database.dart';
import 'models/draw.dart';
import 'models/generated_set.dart';
import 'models/game_rules.dart';
import 'models/game_type.dart';
import 'repositories/draw_repository.dart';
import 'services/column_generator.dart';

void main() => runApp(const LotoApp());

class AppState extends ChangeNotifier {
  final DrawRepository repo = DrawRepository();
  final ColumnGenerator generator = ColumnGenerator();
  bool busy = false;
  String? message;
  List<List<int>> columns = [];
  List<int> bonus = [];
  bool fallback = false;

  Future<void> sync(GameType game) async {
    busy = true; message = null; notifyListeners();
    try {
      final r = await repo.sync(game);
      message = r.added == 0 ? 'Veriler zaten güncel.' : '${r.added} yeni çekiliş eklendi.';
    } catch (e) {
      message = 'İnternet/veri kaynağına erişilemedi. Kayıtlı veriler kullanılacak.';
    } finally { busy = false; notifyListeners(); }
  }

  Future<String> generate(GameType game, int count) async {
    final pool = await repo.numberPool(game);
    final rules = gameRules[game]!;
    if (pool.length < rules.numbersPerColumn) return 'Yeterli geçmiş veri bulunamadı. Önce Verileri Güncelle seçeneğini kullan.';
    final bp = game == GameType.sansTopu ? await repo.bonusPool(game) : <int>{};
    final result = generator.generate(game: game, pool: pool, count: count, bonusPool: bp);
    columns = result.columns; bonus = result.bonusNumbers; fallback = result.hadFallback;
    await AppDatabase.instance.insertGeneratedSet(GeneratedSet(
      game: game, createdAt: DateTime.now(), columnCount: columns.length,
      algorithmVersion: '1.0-balanced-v1',
      columns: List.generate(columns.length, (i) => _format(game, columns[i], i < bonus.length ? bonus[i] : null)),
    ));
    notifyListeners();
    return '';
  }

  String _format(GameType game, List<int> nums, int? bonus) =>
      '${nums.map((n) => n.toString().padLeft(2, '0')).join(' - ')}${game == GameType.sansTopu && bonus != null ? ' + ${bonus.toString().padLeft(2, '0')}' : ''}';

  String formatColumn(GameType game, int index) => _format(game, columns[index], index < bonus.length ? bonus[index] : null);

  Future<List<GeneratedSet>> history() => AppDatabase.instance.generatedSets();
}

class LotoApp extends StatelessWidget {
  const LotoApp({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(create: (_) => AppState(), child: MaterialApp(
    debugShowCheckedModeBanner: false, title: 'Loto Kolon Üretici', themeMode: ThemeMode.system,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.light),
    darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
    home: const HomeScreen(),
  ));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final games = GameType.values;
    return Scaffold(
      appBar: AppBar(title: const Text('Loto Kolon Üretici')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: const Padding(padding: EdgeInsets.all(16), child: Text(
          'Geçmiş çekiliş verileriyle kurallara uygun kolonlar oluşturur. Gelecekte çıkacak sayıları tahmin etmez ve kazanma garantisi vermez.',
          style: TextStyle(fontWeight: FontWeight.w600)))),
        const SizedBox(height: 10),
        for (final game in games) _GameCard(game: game),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () => _syncAll(context), icon: const Icon(Icons.sync), label: const Text('VERİLERİ GÜNCELLE')),
        OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())), icon: const Icon(Icons.history), label: const Text('KOLON GEÇMİŞİM')),
        OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())), icon: const Icon(Icons.bar_chart), label: const Text('İSTATİSTİKLER')),
        const SizedBox(height: 16),
        const Text('Veri kaynağı: Milli Piyango Online resmi sonuç sayfaları.', style: TextStyle(fontSize: 12)),
      ]),
    );
  }

  Future<void> _syncAll(BuildContext context) async {
    final state = context.read<AppState>();
    for (final g in GameType.values) { await state.sync(g); }
    if (context.mounted && state.message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
  }
}

class _GameCard extends StatelessWidget {
  final GameType game;
  const _GameCard({required this.game});
  @override
  Widget build(BuildContext context) => FutureBuilder<int>(
    future: context.read<AppState>().repo.count(game),
    builder: (_, snap) => Card(child: ListTile(
      leading: CircleAvatar(child: Text('${gameRules[game]!.numbersPerColumn}')),
      title: Text(game.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${snap.data ?? 0} kayıtlı çekiliş'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(game: game))),
    )),
  );
}

class GameScreen extends StatefulWidget { final GameType game; const GameScreen({super.key, required this.game});
  @override State<GameScreen> createState() => _GameScreenState(); }
class _GameScreenState extends State<GameScreen> {
  int count = 5; final custom = TextEditingController();
  @override void dispose(){custom.dispose(); super.dispose();}
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(appBar: AppBar(title: Text(widget.game.title)), body: ListView(padding: const EdgeInsets.all(16), children: [
      FutureBuilder<List<Draw>>(future: state.repo.local(widget.game), builder: (_, s) {
        final draws=s.data ?? const <Draw>[]; return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Geçmiş çekiliş: ${draws.length}'), if(draws.isNotEmpty) Text('Son çekiliş: ${DateFormat('dd.MM.yyyy').format(draws.first.drawDate)}'),
        ])));}),
      const SizedBox(height: 12), const Text('Kolon sayısı', style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: [1,2,5,10,20,50].map((n)=>ChoiceChip(label:Text('$n'), selected:count==n, onSelected:(_)=>setState(()=>count=n))).toList()),
      const SizedBox(height: 12),
      TextField(controller: custom, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Özel sayı', hintText:'Örn. 15', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: state.busy ? null : () async { final n=int.tryParse(custom.text) ?? count; final err=await context.read<AppState>().generate(widget.game,n); if(context.mounted && err.isNotEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(err))); }, icon: const Icon(Icons.casino), label: Text('$count KOLON OLUŞTUR')),
      OutlinedButton.icon(onPressed: state.busy ? null : () async { await context.read<AppState>().sync(widget.game); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(context.read<AppState>().message ?? 'İşlem tamamlandı.'))); }, icon: const Icon(Icons.cloud_download), label: const Text('VERİLERİ GÜNCELLE')),
      if(state.columns.isNotEmpty) ...[
        const SizedBox(height: 16), const Text('Üretilen kolonlar', style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold)),
        for(var i=0;i<state.columns.length;i++) Card(child: ListTile(title: Text('Kolon ${i+1}'), subtitle: Text(state.formatColumn(widget.game,i), style: const TextStyle(fontSize:16,fontWeight:FontWeight.w600)), trailing: IconButton(icon:const Icon(Icons.copy), onPressed:()=>_copy(context,state.formatColumn(widget.game,i))))),
        if(state.fallback) const Padding(padding:EdgeInsets.only(top:8), child:Text('İstenen kolon sayısı için tamamen tekrarsız dağılım mümkün olmadığı için en düşük tekrar seviyesine geçildi.')),
        FilledButton(onPressed:()=>_copy(context, List.generate(state.columns.length,(i)=>'Kolon ${i+1}: ${state.formatColumn(widget.game,i)}').join('\n')), child:const Text('TÜM KOLONLARI KOPYALA')),
      ],
    ]));
  }
  Future<void> _copy(BuildContext c,String s) async { await Clipboard.setData(ClipboardData(text:s)); if(c.mounted) ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('Kopyalandı.'))); }
}

class HistoryScreen extends StatelessWidget { const HistoryScreen({super.key}); @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Kolon Geçmişim')),body:FutureBuilder<List<GeneratedSet>>(future:c.read<AppState>().history(),builder:(_,s){final rows=s.data??[]; if(rows.isEmpty)return const Center(child:Text('Henüz kayıt yok.')); return ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(_,i){final r=rows[i];return Card(child:ExpansionTile(title:Text(r.game.title),subtitle:Text('${DateFormat('dd.MM.yyyy HH:mm').format(r.createdAt)} • ${r.columnCount} kolon'),children:r.columns.map((x)=>ListTile(title:Text(x))).toList()));});}));}

class StatisticsScreen extends StatelessWidget { const StatisticsScreen({super.key}); @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('İstatistikler')),body:ListView(padding:const EdgeInsets.all(12),children:[const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('İstatistikler yalnızca geçmiş çekilişlerin özetidir; gelecek çekilişler için tahmin veya garanti anlamına gelmez.'))),for(final g in GameType.values)_StatsCard(game:g)])); }
class _StatsCard extends StatelessWidget { final GameType game; const _StatsCard({required this.game}); @override Widget build(BuildContext c)=>FutureBuilder<List<Draw>>(future:c.read<AppState>().repo.local(game),builder:(_,s){final draws=s.data??[];final counts=<int,int>{};for(final d in draws){for(final n in d.numbers)counts[n]=(counts[n]??0)+1;}final top=counts.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));final rare=counts.entries.toList()..sort((a,b)=>a.value.compareTo(b.value));return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(game.title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),Text('Toplam çekiliş: ${draws.length}'),if(top.isNotEmpty)Text('En sık görülenler: ${top.take(10).map((e)=>'${e.key} (${e.value})').join(', ')}'),if(rare.isNotEmpty)Text('Daha az görülenler: ${rare.take(10).map((e)=>'${e.key} (${e.value})').join(', ')}')])));});}
