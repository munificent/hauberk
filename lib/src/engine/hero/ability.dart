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

  /// The focus cost to use the ability.
  int focusCost(HeroSave hero) => 0;

  /// If the ability cannot currently be used (for example Archery when a bow
  /// is not equipped), returns the reason why. Otherwise, returns `null` to
  /// indicate the ability is usable.
  String? unusableReason(Game game) {
    var reasons = [
      for (var requirement in requirements) ?requirement.check(game),
    ];

    if (reasons.isEmpty) return null;
    return reasons.join(' ');
  }

  /// The conditions that must be met before this ability is available.
  List<Requirement> get requirements;

  /// If this skill has a focus cost, wraps [action] in an appropriate action
  /// to spend that.
  Action _wrapFocusCost(HeroSave hero, Action action) {
    var cost = focusCost(hero);
    if (cost <= 0) return action;
    return FocusAction(cost, action);
  }
}

/// A condition that must be met before an [Ability] can be used.
abstract class Requirement {
  /// Describes the requirement to the user.
  String get description;

  /// If the requirement is met, returns `null`. Otherwise returns a string
  /// describing why it is not met.
  String? check(Game game);
}

class SkillLevelRequirement extends Requirement {
  final Skill _skill;
  final int _level;

  SkillLevelRequirement(this._skill, this._level);

  @override
  String get description =>
      "You must be at level $_level or higher in ${_skill.name}.";

  @override
  String? check(Game game) {
    if (game.hero.skills.level(_skill) >= _level) return null;
    return "Not enough ${_skill.name}";
  }
}

class IntellectRequirement extends Requirement {
  final int _intellect;

  IntellectRequirement(this._intellect);

  @override
  String get description => "You need at least $_intellect intellect.";

  @override
  String? check(Game game) {
    if (game.hero.save.intellect.value >= _intellect) return null;
    return "You aren't smart enough.";
  }
}

/// An [Ability] that can be directly used to perform an action.
mixin ActionAbility on Ability {
  Action getAction(Game game) {
    return _wrapFocusCost(game.hero.save, onGetAction(game));
  }

  Action onGetAction(Game game);
}

/// A skill that requires a target position to perform.
mixin TargetAbility on Ability {
  bool get canTargetSelf => false;

  /// The maximum range of the target from the hero.
  int getRange(Game game);

  Action getTargetAction(Game game, Vec target) {
    return _wrapFocusCost(game.hero.save, onGetTargetAction(game, target));
  }

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Ability].
  Action onGetTargetAction(Game game, Vec target);
}

/// A skill that requires a direction to perform.
mixin DirectionAbility on Ability {
  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Ability].
  Action getDirectionAction(Game game, Direction dir) {
    return _wrapFocusCost(game.hero.save, onGetDirectionAction(game, dir));
  }

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Ability].
  Action onGetDirectionAction(Game game, Direction dir);
}
