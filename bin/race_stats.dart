import 'package:hauberk/src/content.dart';

/// Roll new heroes for each race and show the starting stats.
void main() {
  var content = createContent();
  for (var race in content.races) {
    for (var i = 0; i < 20; i++) {
      var hero = content.createHero(
        "Fred",
        race: race,
        heroClass: content.classes.first,
      );

      var line = race.name.padRight(5);

      for (var stat in [
        hero.strength,
        hero.agility,
        hero.vitality,
        hero.intellect,
      ]) {
        var bar = '*' * (stat.value);
        line += '  ${stat.value.toString().padLeft(2)} ${bar.padRight(20)}';
      }

      print(line);
    }
  }
}
