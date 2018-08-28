import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';

/// Tracks what level the hero reaches if they kill every monster in every
/// generated dungeon going down.
main() {
  var content = createContent();
  var save = content.createHero("Fred", content.races[4], content.classes[1]);
  for (var level = 1; level <= Option.maxDepth; level++) {
    var game = Game(content, save, level);
    for (var _ in game.generate());

    var hero = game.hero;
    for (var actor in game.stage.actors) {
      if (actor is Monster) {
        var attack = AttackAction(actor);
        attack.bind(hero);
        hero.seeMonster(actor);
        hero.onKilled(attack, actor);
      }
    }

    save.takeFrom(hero);
    var bar = "*" * hero.level;
    print("${level.toString().padLeft(3)} "
        "${hero.level.toString().padLeft(3)} $bar");
  }
}
