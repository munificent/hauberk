import '../../engine.dart';
import 'skills.dart';

abstract class MasterySkill extends Skill {
  @override
  Domain get domain => Domains.weaponry;

  String get weaponType;

  double _damageScale(int level) =>
      lerpDouble(level, 1, Skill.modifiedMax, 1.1, 4.0);

  @override
  void modifyHit(Hero hero, Monster? monster, Item? weapon, Hit hit) {
    // Only for weapons that this mastery applies to.
    if (weapon == null || weapon.type.weaponType != weaponType) return;

    var level = hero.save.skills.level(this);
    hit.scaleDamage(_damageScale(level), 'mastery');
  }

  @override
  String levelDescription(int level) {
    var damage = (_damageScale(level) - 1.0).fmtPercent();
    // TODO: Use Noun stuff for this?
    var a = "aeiou".contains(weaponType[0]) ? "an" : "a";
    return "Melee attacks inflict +$damage damage when using $a "
        "$weaponType.";
  }
}

class AxeMastery extends MasterySkill {
  static final AxeMastery instance = AxeMastery._();

  AxeMastery._();

  // TODO: Better name.
  @override
  String get name => "Axe Mastery";

  @override
  String get description =>
      "Axes are not just for woodcutting. In the hands of a skilled user, "
      "they can cut down a swath of nearby foes as well.";

  @override
  String get weaponType => "axe";

  @override
  String levelDescription(int level) {
    // TODO: Redo.
    return "TODO";
    // return "${super.levelDescription(level)} Sweep attacks inflict "
    //     "${_sweepScale(level).fmtPercent()} of the damage of a regular attack.";
  }
}

class Bludgeoning extends MasterySkill {
  static final Bludgeoning instance = Bludgeoning._();

  Bludgeoning._();

  @override
  String get name => "Bludgeoning";

  @override
  String get description =>
      "Bludgeons may not be the most sophisticated of weapons, but hitting "
      "someone really hard with a blunt object can often be an effective "
      "argument in your favor.";

  @override
  String get weaponType => "club";

  @override
  String levelDescription(int level) {
    // TODO: Describe scale.
    return "${super.levelDescription(level)} Bashes the enemy away.";
  }
}

class KnifeFighting extends MasterySkill {
  @override
  String get name => "Knife Fighting";

  @override
  String get description =>
      "Small and easily concealed, knives are deadly in the hand of a skilled "
      "practitioner.";

  @override
  String get weaponType => "knife";

  @override
  String levelDescription(int level) {
    // TODO: Should improve backstabbing.
    return "TODO";
  }
}

class SpearMastery extends MasterySkill {
  static final SpearMastery instance = SpearMastery._();

  SpearMastery._();

  // TODO: Better name.
  @override
  String get name => "Spear Mastery";

  @override
  String get description =>
      "Your diligent study of spears and polearms lets you attack at a "
      "distance when wielding one.";

  @override
  String get weaponType => "spear";

  @override
  String levelDescription(int level) {
    // TODO: Redo.
    return "TODO";
    // return "${super.levelDescription(level)} Distance spear attacks inflict "
    //     "${_spearScale(level).fmtPercent()} of the damage of a regular attack.";
  }
}

class Swordfighting extends MasterySkill {
  static int _parryDefense(int level) =>
      lerpInt(level, 1, Skill.modifiedMax, 5, 30);

  @override
  String get name => "Swordfighting";

  @override
  String get description =>
      "The most elegant tool for the most refined of martial arts.";

  @override
  String get weaponType => "sword";

  @override
  String levelDescription(int level) =>
      "${super.levelDescription(level)} Parrying increases dodge by "
      "${_parryDefense(level)}.";

  @override
  Iterable<Defense> defenses(Hero hero) sync* {
    var level = hero.save.skills.level(this);

    // The hero can parry with both swords if dual-wielding.
    for (var weapon in hero.equipment.weapons) {
      if (weapon.type.weaponType == "sword") {
        // TODO: Should the parrying ability depend on the sword's damage?
        yield Defense(_parryDefense(level), "{1} parr[y|ies] {2}.");
      }
    }
  }
}

class WhipMastery extends MasterySkill {
  static final WhipMastery instance = WhipMastery._();

  WhipMastery._();

  // TODO: Better name.
  @override
  String get name => "Whip Mastery";

  @override
  String get description =>
      "Whips and flails are difficult to use well, but deadly even at a "
      "distance when mastered.";

  @override
  String get weaponType => "whip";

  // @override
  // Ability? initializeAbility() => WhipCrackAbility(this);

  @override
  String levelDescription(int level) {
    // TODO: Redo.
    return "TODO";
  }
}
