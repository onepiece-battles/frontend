import 'individual_bar.dart';

class CharacterData {
  final int attackMax = 1000;
  final int defenseMax = 1000;
  final int intelligenceMax = 260;
  final int speedMax = 200;
  final int bloodMax = 10000;
  final int energyMax = 50;
  final int attack;
  final int defense;
  final int intelligence;
  final int speed;
  final int blood;
  final int energy;

  CharacterData(this.attack, this.defense, this.intelligence, this.speed,
      this.blood, this.energy);

  List<IndividualBar> barData = [];

  void initBarData() {
    barData = [
      IndividualBar(x: 0, y: attack, yMax: attackMax),
      IndividualBar(x: 1, y: defense, yMax: defenseMax),
      IndividualBar(x: 2, y: intelligence, yMax: intelligenceMax),
      IndividualBar(x: 3, y: speed, yMax: speedMax),
      IndividualBar(x: 4, y: blood, yMax: bloodMax),
      IndividualBar(x: 5, y: energy, yMax: energyMax),
    ];
  }
}