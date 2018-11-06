import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';

/// Tracks what level the hero reaches if they kill every monster in every
/// generated dungeon going down.
main() {
//  for (var race in createContent().races) {
//    print(race.name);
//    for (var i = 0; i < 100; i++) {
//      race.rollStats();
//    }
//  }
  Simulator().run();
}

class Simulator {
  static final content = createContent();
  final save = content.createHero("Fred", content.races[4], content.classes[1]);

  Game game;
  int depth;

  Hero get hero => game.hero;

  final Map<Breed, Kill> kills = {};

  void run() {
    for (depth = 1; depth <= Option.maxDepth; depth++) {
      _exploreDepth();
    }

    print("Breed                                    kills hits/kill");
    print("---------------------------------------- ----- ---------");
    var breeds = kills.keys.toList();
    breeds.sort((a, b) => a.experience.compareTo(b.experience));

    for (var breed in breeds) {
      var kill = kills[breed];
      print("${breed.name.padRight(40)} ${kill.kills.toString().padLeft(5)} "
          "${(kill.hits / kill.kills).toStringAsFixed(1).padLeft(9)}");
    }
  }

  void _exploreDepth() {
    game = Game(content, save, depth);

    for (var _ in game.generate());

    print("--- Depth $depth (hero level ${hero.level}) ---");

    var events = <Object>[];
    events.addAll(game.stage.actors);
    events.addAll(game.stage.allItems);
    rng.shuffle(events);

    for (var event in events) {
      if (event is Item) {
        _getItem(event);
      } else if (event is Monster) {
        _fightMonster(event);
      } else {
        assert(event is Hero);
      }
    }

    save.takeFrom(hero);
  }

  void _getItem(Item item) {
    if (item.type.weaponType != null) {
      _getWeapon(item);
    } else {
//      _log(item);
    }

    // TODO: Equip armor.
  }

  void _getWeapon(Item item) {
    // TODO: Use ranged weapons?
    if (item.attack.range > 0) return;

    if (hero.equipment.weapon != null &&
        hero.equipment.weapon.price >= item.price) {
//      _log("$item is not better than ${hero.equipment.weapon}");
      return;
    }

    if (item.heft > hero.strength.value) {
//      _log("$item is too heavy (${item.heft} heft, ${hero.strength.value} strength)");
      return;
    }

    if (hero.equipment.weapon != null) {
      hero.equipment.remove(hero.equipment.weapon);
    }

    hero.equipment.tryAdd(item);
    _log("wield $item");
  }

  void _fightMonster(Monster monster) {
//    _log(monster);
    hero.seeMonster(monster);

    var kill = kills.putIfAbsent(monster.breed, () => Kill());

    while (monster.health > 0) {
      var attack = AttackAction(monster);
      attack.bind(hero);
      attack.perform();
      kill.hits++;

      // TODO: Hit the hero back and track how much damage they take.
    }

    kill.kills++;

    monster.breed.drop.spawnDrop(depth, _getItem);
  }

  void _log(Object message) {
    print(message);
  }
}

class Kill {
  int kills = 0;
  int hits = 0;
}
