import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/game.dart';
import 'hero_save.dart';
import 'skill.dart';

/// A behavior the [Hero] can perform granted by a [Skill].
abstract class Ability {
  /// The name shown when using the ability.
  String get name;

  /// The skill that granted this ability.
  Skill get skill;

  /// The focus cost to use the skill, with proficiency applied.
  int focusCost(HeroSave hero, int level) => 0;

  /// If the skill cannot currently be used (for example Archery when a bow is
  /// not equipped), returns the reason why. Otherwise, returns `null` to
  /// indicate the skill is usable.
  String? unusableReason(Game game) => null;

  /// If this skill has a focus cost, wraps [action] in an appropriate action
  /// to spend that.
  Action _wrapFocusCost(HeroSave hero, int level, Action action) {
    if (focusCost(hero, level) > 0) {
      return FocusAction(focusCost(hero, level), action);
    }

    return action;
  }
}

/// An [Ability] that can be directly used to perform an action.
abstract class ActionAbility extends Ability {
  Action getAction(Game game, int skillLevel) {
    return _wrapFocusCost(
      game.hero.save,
      skillLevel,
      onGetAction(game, skillLevel),
    );
  }

  Action onGetAction(Game game, int skillLevel);
}

/// A skill that requires a target position to perform.
abstract class TargetAbility extends Ability {
  bool get canTargetSelf => false;

  /// The maximum range of the target from the hero.
  int getRange(Game game);

  Action getTargetAction(Game game, int skillLevel, Vec target) {
    return _wrapFocusCost(
      game.hero.save,
      skillLevel,
      onGetTargetAction(game, skillLevel, target),
    );
  }

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Ability].
  Action onGetTargetAction(Game game, int skillLevel, Vec target);
}

/// A skill that requires a direction to perform.
abstract class DirectionAbility extends Ability {
  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Ability].
  Action getDirectionAction(Game game, int skillLevel, Direction dir) {
    return _wrapFocusCost(
      game.hero.save,
      skillLevel,
      onGetDirectionAction(game, skillLevel, dir),
    );
  }

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Ability].
  Action onGetDirectionAction(Game game, int skillLevel, Direction dir);
}
