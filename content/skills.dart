library content.skills;

import '../engine.dart';
import '../util.dart';
import 'builder.dart';

final Map<String, Skill> skills = {};

/// Builder class for defining [Skill]s.
class SkillBuilder extends ContentBuilder {
  void build() {
    skill(new ArcherySkill());
    skill(new CombatSkill());
    skill(new StaminaSkill());
    skill(new WeaponSkill('Club'));
    skill(new WeaponSkill('Dagger'));
    skill(new WeaponSkill('Spear'));
    skill(new WeaponSkill('Sword'));
    skill(new DropSkill('Hunting', 'animals'));
    skill(new DropSkill('Botany', 'plants and fungi'));
  }

  void skill(Skill skill) {
    skills[skill.name] = skill;
  }
}

class ArcherySkill extends Skill {
  String get name => 'Archery';
  String getHelpText(int level) =>
      'Allows using missile weapons at a cost of ${getFocusCost(level)} focus.';

  bool get hasUse => true;
  bool get needsTarget => true;

  bool canUse(int level, Game game) {
    // Get the equipped bow, if any.
    var bow = game.hero.equipment.find('Bow');
    if (bow == null) {
      game.log.error('You do not have a bow equipped.');
      return false;
    }

    // Make sure the hero is focused.
    if (game.hero.focus < getFocusCost(level)) {
      game.log.error('You are too unfocused!');
      return false;
    }

    return true;
  }

  Action getUseAction(int level, Game game, Vec target) {
    var bow = game.hero.equipment.find('Bow');
    return new BoltAction(game.hero.pos, target, bow.attack,
        -getFocusCost(level));
  }

  int getFocusCost(int level) => 30 - level * 4;
}

class CombatSkill extends Skill {
  String get name => 'Combat';
  String getHelpText(int level) => 'Increase damage by $level.';

  num getAttackAddBonus(int level, Item weapon, Attack attack) => level;
}

class WeaponSkill extends Skill {
  final String _category;

  WeaponSkill(this._category);

  String get name => '$_category Mastery';
  String getHelpText(int level) =>
      'Increase damage by ${level * 5}% when wielding a $_category.';

  num getAttackMultiplyBonus(int level, Item weapon, Attack attack) {
    if (weapon == null || weapon.type.category != _category) return 0;
    return level * 5 / 100;
  }
}

class StaminaSkill extends Skill {
  String get name => 'Stamina';
  String getHelpText(int level) => 'Increase max health by ${level * 2}.';

  int modifyHealth(int level) => level * 2;
}

/// A skill that enables monsters to drop certain items.
class DropSkill extends Skill {
  final String name;
  final String monster;

  DropSkill(this.name, this.monster);

  String getHelpText(int level) => '${level * 10}% chance of drop from $monster.';

  int getDropChance(int level) => level * 10;
}
