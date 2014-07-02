library dngn.engine.hero.warrior;

import '../action_base.dart';
import '../actor.dart';
import '../melee.dart';
import '../monster.dart';
import 'hero.dart';
import 'hero_class.dart';

/// A warrior is focused on combat. Players choosing them don't want to spend
/// a bunch of time fiddling with skills so almost all warrior skills are
/// passive and increase in level automatically simply by doing something
/// related to the skill.
class Warrior extends HeroClass {
  int get armor => toughness.level;

  /// Increases damage. Trained by killing monsters.
  final combat = new TrainedStat(10, 10);

  // Increases armor. Trained by taking damage.
  final toughness = new TrainedStat(400, 100);

  Warrior();

  Warrior.load({int combat, int toughness}) {
    this.combat.increment(combat);
    this.toughness.increment(toughness);
  }

  Warrior clone() => new Warrior.load(
      combat: combat.count,
      toughness: toughness.count);

  Attack modifyAttack(Attack attack, Actor defender) {
    return attack.addDamage(combat.level);
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
    if (combat.increment(1)) {
      action.game.log.gain('{1} [have|has] reached combat level '
          '${combat.level}.', hero);
    }
  }
}

/// A skill that can increase in level based on some occurrence happening a
/// certain number of times.
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
