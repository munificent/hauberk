import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';

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

      var line = race.name.fmt(w: 5);

      for (var stat in [
        hero.strength,
        hero.agility,
        hero.vitality,
        hero.intellect,
      ]) {
        var bar = '*' * (stat.value);
        line += '  ${stat.value.fmt(w: 2)} ${bar.fmt(w: 20)}';
      }

      print(line);
    }
  }
}
