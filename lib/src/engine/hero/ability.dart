import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/game.dart';
import 'hero_save.dart';
import 'skill.dart';

/// A behavior the [Hero] can perform granted by a [Skill].
abstract class Ability {
  /// The name shown when using the ability.
  String get name;

  // TODO: Make this abstract and make the subclasses fill it in.
  String get description => 'TODO';

  /// The skill that granted this ability.
  Skill get skill;

  // TODO: Don't pass in hero and skill level and make this constant?
  /// The focus cost to use the ability when its skill is at [skillLevel].
  int focusCost(HeroSave hero, int skillLevel) => 0;

  /// If the ability cannot currently be used (for example Archery when a bow
  /// is not equipped), returns the reason why. Otherwise, returns `null` to
  /// indicate the ability is usable.
  String? unusableReason(Game game) => null;

  /// If this skill has a focus cost, wraps [action] in an appropriate action
  /// to spend that.
  Action _wrapFocusCost(HeroSave hero, int skillLevel, Action action) {
    if (focusCost(hero, skillLevel) > 0) {
      return FocusAction(focusCost(hero, skillLevel), action);
    }

    return action;
  }
}

abstract class Spell extends Ability {
  /// How difficult the spell is to cast.
  int get spellLevel;

  @override
  String? unusableReason(Game game) {
    return switch (game.hero.save.spellStatus(this)) {
      SpellStatus.learnable ||
      SpellStatus.learnable ||
      SpellStatus.notEnoughIntellect ||
      SpellStatus.notEnoughSchool => "You don't know this spell",
      SpellStatus.known => null,
      SpellStatus.forgotten => "You forgot this spell",
    };
  }
}

/// An [Ability] that can be directly used to perform an action.
mixin ActionAbility on Ability {
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
mixin TargetAbility on Ability {
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
mixin DirectionAbility on Ability {
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
