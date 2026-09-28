import 'game_type.dart';

class GameRules {
  final GameType game;
  final int minNumber;
  final int maxNumber;
  final int numbersPerColumn;
  final bool hasBonus;
  final int? bonusMin;
  final int? bonusMax;
  final int? bonusNumbersPerColumn;
  final int drawNumbers;
  final int maxSystemSelection;

  const GameRules({
    required this.game,
    required this.minNumber,
    required this.maxNumber,
    required this.numbersPerColumn,
    this.hasBonus = false,
    this.bonusMin,
    this.bonusMax,
    this.bonusNumbersPerColumn,
    required this.drawNumbers,
    required this.maxSystemSelection,
  });
}

const gameRules = <GameType, GameRules>{
  GameType.sayisalLoto: GameRules(
    game: GameType.sayisalLoto, minNumber: 1, maxNumber: 90,
    numbersPerColumn: 6, hasBonus: true, bonusMin: 1, bonusMax: 90,
    bonusNumbersPerColumn: 1, drawNumbers: 6, maxSystemSelection: 19,
  ),
  GameType.superLoto: GameRules(
    game: GameType.superLoto, minNumber: 1, maxNumber: 60,
    numbersPerColumn: 6, drawNumbers: 6, maxSystemSelection: 60,
  ),
  GameType.onNumara: GameRules(
    game: GameType.onNumara, minNumber: 1, maxNumber: 80,
    numbersPerColumn: 10, drawNumbers: 22, maxSystemSelection: 15,
  ),
  GameType.sansTopu: GameRules(
    game: GameType.sansTopu, minNumber: 1, maxNumber: 34,
    numbersPerColumn: 5, hasBonus: true, bonusMin: 1, bonusMax: 14,
    bonusNumbersPerColumn: 1, drawNumbers: 5, maxSystemSelection: 10,
  ),
};
