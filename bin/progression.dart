import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';

/// Tracks how much experience the hero gains if they kill every monster in
/// every generated dungeon going down.
void main() {
  var content = createContent();
  var save = content.createHero(
    "Fred",
    race: content.races[4],
    heroClass: content.classes[1],
  );
  for (var depth = 1; depth <= Option.maxDepth; depth++) {
    var game = Game(content, depth, save);
    for (var _ in game.generate()) {}

    var hero = game.hero;
    for (var actor in game.stage.actors) {
      if (actor is Monster) {
        var attack = AttackAction(actor);
        attack.bind(game, hero);
        hero.seeMonster(actor);
        hero.onKilled(attack, actor);
      }
    }

    var mostSlainCount = 0;
    var mostSlainBreed = '?';
    for (var breed in hero.lore.slainBreeds) {
      var slain = hero.lore.slain(breed);
      if (slain > mostSlainCount) {
        mostSlainCount = slain;
        mostSlainBreed = breed.name;
      }
    }

    print(
      "${depth.toString().padLeft(3)} "
      "${hero.experience.toString().padLeft(10)} "
      "${mostSlainCount.toString().padLeft(4)} $mostSlainBreed",
    );
  }
}
