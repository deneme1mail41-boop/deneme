import 'package:flutter_test/flutter_test.dart';
import 'package:loto_kolon_uretici/models/game_type.dart';
import 'package:loto_kolon_uretici/services/column_generator.dart';

void main() {
  test('50 kolon üretir ve kolon içi tekrar oluşturmaz', () {
    final g = ColumnGenerator();
    final r = g.generate(game: GameType.sayisalLoto, pool: {for (var i=1;i<=90;i++) i}, count: 50);
    expect(r.columns.length, 50);
    final keys = r.columns.map((e) => e.join('-')).toSet();
    expect(keys.length, 50);
    for (final c in r.columns) {
      expect(c.length, 6);
      expect(c.toSet().length, 6);
      expect(c.every((n) => n >= 1 && n <= 90), true);
    }
  });

  test('havuz yetersizse hata verir', () {
    final g = ColumnGenerator();
    expect(() => g.generate(game: GameType.superLoto, pool: {1,2,3}, count: 1), throwsStateError);
  });

  test('Şans Topu 5+1 biçimini üretir', () {
    final g = ColumnGenerator();
    final r = g.generate(game: GameType.sansTopu, pool: {for (var i=1;i<=34;i++) i}, bonusPool: {for (var i=1;i<=14;i++) i}, count: 10);
    expect(r.columns.length, 10);
    expect(r.bonusNumbers.length, 10);
    for (var i=0;i<10;i++) {
      expect(r.columns[i].length, 5);
      expect(r.columns[i].toSet().length, 5);
      expect(r.bonusNumbers[i], inInclusiveRange(1, 14));
    }
  });
}
