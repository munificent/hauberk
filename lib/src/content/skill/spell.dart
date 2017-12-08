import 'package:piecemeal/src/vec.dart';

import '../../engine.dart';

/// Base class for spell school skills.
abstract class SchoolSkill extends Skill {
  // TODO: Tune.
  static double focusScale(int level) {
    if (level == 0) return 1.0;
    return lerpDouble(level, 1, 20, 1.0, 0.2);
  }

  // TODO: Tune.
  int get maxLevel => 20;

  Skill get prerequisite => Skill.education;

  @override
  String levelDescription(int level) {
    var percent = ((1.0 - focusScale(level)) * 100).toInt();
    return "Reduce the focus cost of $name spells by $percent%.";
  }
}

/// Mixin for a spell skill.
abstract class SpellSkill implements Skill {
  /// The amount of [Intellect] the hero must possess to use this spell
  /// effectively.
  int get complexity;

  int get focusCost;

  Skill get _school {
    // It should be a direct or indirect prerequisite of this one.
    var skill = prerequisite;
    while (skill != null) {
      if (skill is SchoolSkill) return skill;
      skill = skill.prerequisite;
    }

    throw "Spell skill does not have a school as a prerequisite.";
  }

  int adjustedFocusCost(Hero hero) {
    return (focusCost * SchoolSkill.focusScale(hero.skills[_school])).toInt();
  }

  double effectiveness(Game game) =>
      game.hero.intellect.effectivenessScale(complexity);

  int failureChance(Game game) => game.hero.intellect.failureChance(complexity);

  Action getTargetAction(Game game, int level, Vec target) {
    var action = onGetTargetAction(game, level, target);
    return new FocusAction(adjustedFocusCost(game.hero), action);
  }

  Action onGetTargetAction(Game game, int level, Vec target) => null;

  Action getAction(Game game, int level) {
    var action = onGetAction(game, level);
    return new FocusAction(adjustedFocusCost(game.hero), action);
  }

  Action onGetAction(Game game, int level) => null;
}
