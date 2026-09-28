enum GameType { sayisalLoto, superLoto, onNumara, sansTopu }

extension GameTypeX on GameType {
  String get key => switch (this) {
        GameType.sayisalLoto => 'sayisal_loto',
        GameType.superLoto => 'super_loto',
        GameType.onNumara => 'on_numara',
        GameType.sansTopu => 'sans_topu',
      };

  String get title => switch (this) {
        GameType.sayisalLoto => 'Çılgın Sayısal Loto',
        GameType.superLoto => 'Süper Loto',
        GameType.onNumara => 'On Numara',
        GameType.sansTopu => 'Şans Topu',
      };
}

GameType gameTypeFromKey(String key) => GameType.values.firstWhere((e) => e.key == key);
