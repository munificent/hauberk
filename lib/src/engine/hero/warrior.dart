library hauberk.engine.hero.warrior;

import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/bolt.dart';
import '../action/slash.dart';
import '../actor.dart';
import '../game.dart';
import '../melee.dart';
import '../monster.dart';
import '../command/archery.dart';
import '../command/slash.dart';
import '../command/stab.dart';
import 'command.dart';
import 'hero_class.dart';

/// A warrior is focused on combat. Players choosing them don't want to spend
/// a bunch of time fiddling with commands so almost all warrior abilities are
/// passive and increase in level automatically simply by doing something
/// related to the ability.
class Warrior extends HeroClass {
  String get name => "Warrior";

  final List<Command> commands = [
    new ArcheryCommand(),
    new SlashCommand(),
    new StabCommand()
  ];

  int get armor => toughness.level;

  /// Increases damage when unarmed. Trained by killing monsters while unarmed.
  final fighting = new TrainedStat(80, 60);

  /// Increases damage when armed. Trained by killing monsters while armed.
  final combat = new TrainedStat(100, 200);

  // Increases armor. Trained by taking damage.
  final toughness = new TrainedStat(400, 100);

  // Each mastery increases damage when wielding a weapon of a given category.
  final masteries = <String, TrainedStat>{};
  TrainedStat _newMasteryStat() => new TrainedStat(80, 160);

  Warrior();

  Warrior.load({int fighting, int combat, int toughness,
      Map<String, int> masteries}) {
    this.fighting.increment(fighting);
    this.combat.increment(combat);
    this.toughness.increment(toughness);

    masteries.forEach((category, count) {
      var stat = _newMasteryStat();
      stat.increment(count);
      this.masteries[category] = stat;
    });
  }

  Warrior clone() {
    var masteryCounts = {};
    masteries.forEach((category, stat) {
      masteryCounts[category] = stat.count;
    });

    return new Warrior.load(
      fighting: fighting.count,
      combat: combat.count,
      toughness: toughness.count,
      masteries: masteryCounts);
  }

  Attack modifyAttack(Attack attack, Actor defender) {
    var weapon = hero.equipment.weapon;
    if (weapon != null) {
      // TODO: Should combat apply to ranged attacks?
      attack = attack.addDamage(combat.level);

      var mastery = masteries[weapon.type.category];
      if (mastery != null) {
        attack = attack.multiplyDamage(1.0 + mastery.level * 0.1);
      }

      return attack;
    } else {
      return attack.addDamage(fighting.level);
    }
  }

  void tookDamage(Action action, Actor attacker, int damage) {
    // Indirect damage doesn't increase toughness.
    if (attacker == null) return;

    // Reduce damage by armor (again). This is so that toughness increases
    // much more slowly as the hero wears more armor.
    damage = (damage * getArmorMultiplier(hero.armor - toughness.level) * 10)
        .floor();
    if (toughness.increment(damage)) {
      action.game.log.gain('{1} [have|has] reached toughness level '
          '${toughness.level}.', hero);
    }
  }

  void killedMonster(Action action, Monster monster) {
    var weapon = hero.equipment.weapon;
    var stat;
    var name;
    if (weapon != null) {
      stat = combat;
      name = "combat";

      var mastery = masteries.putIfAbsent(weapon.type.category,
          _newMasteryStat);
      if (mastery.increment(monster.breed.maxHealth)) {
        action.game.log.gain("{1} [have|has] reached ${weapon.type.category} "
            "mastery level ${mastery.level}.", hero);
      }
    } else {
      stat = fighting;
      name = "fighting";
    }

    // Base it on the health of the monster to discourage the player from just
    // killing piles of weak monsters.
    if (stat.increment(monster.breed.maxHealth)) {
      action.game.log.gain("{1} [have|has] reached $name level "
          "${stat.level}.", hero);
    }
  }
}

/// A learned ability that can increase in level based on some occurrence
/// happening a certain number of times.
class TrainedStat {
  /// The current count of occurrences.
  int get count => _count;
  int _count = 0;

  /// How far into reaching the next level the stat is, as a percentage.
  int get percentUntilNext {
    var level = 0;
    var left = _count;
    var cost = _cost;

    while (left >= cost) {
      level++;
      left -= cost;
      cost += _increase;
    }

    return (100 * left / cost).floor();
  }

  /// The current level.
  ///
  /// Starts at zero and increases.
  int get level {
    var level = 0;
    var left = _count;
    var cost = _cost;

    while (left >= cost) {
      level++;
      left -= cost;
      cost += _increase;
    }

    return level;
  }

  /// The number of occurrences required to reach the next level.
  ///
  /// This will be the cost to reach level 1. After that, the cost per level is
  /// increased by [_increase], yielding a geometric progression. A higher cost
  /// makes it harder to gain levels.
  final int _cost;

  /// The amount the [_cost] increases at each level.
  final int _increase;

  TrainedStat(this._cost, this._increase);

  /// Add [count] occurrences to the count.
  ///
  /// Returns `true` if the level increased.
  bool increment(int count) {
    var oldLevel = level;
    _count += count;
    return level != oldLevel;
  }
}
