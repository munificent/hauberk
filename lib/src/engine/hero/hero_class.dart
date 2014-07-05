library dngn.engine.hero.hero_class;

import '../action_base.dart';
import '../actor.dart';
import '../melee.dart';
import '../monster.dart';
import 'hero.dart';
import 'skill.dart';

/// Base class for a Hero's character class.
///
/// Each class has its own unique behavior and game mechanics. To support this,
/// there are a number of abstract methods here that will be called at
/// appropriate times during the game. Specific classes can then decide how to
/// handle that.
abstract class HeroClass {
  /// Gets the [Hero] that has this class.
  Hero get hero => _hero;
  Hero _hero;

  String get name;

  /// The [Skills] that the class enables.
  List<Skill> get skills;

  /// Gets the armor bonus conferred by this class.
  int get armor => 0;

  /// Attaches this class to a [hero].
  void bind(Hero hero) {
    assert(_hero == null);
    _hero = hero;
  }

  /// Gives the class a chance to modify the attack the hero is about to perform
  /// on [defender].
  Attack modifyAttack(Attack attack, Actor defender) => attack;

  /// Called when the [Hero] has taken [damage] from [attacker].
  void tookDamage(Action action, Actor attacker, int damage) {}

  /// Called when the [Hero] has killed [monster].
  void killedMonster(Action action, Monster monster) {}

  /// Clones this object.
  ///
  /// Called when the hero enters the level so that if they die, all changes
  /// can be discarded.
  HeroClass clone();
}
