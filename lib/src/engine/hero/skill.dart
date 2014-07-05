library dngn.engine.hero.skill;

import '../../util.dart';
import '../action_base.dart';
import '../game.dart';
import '../item.dart';
import '../melee.dart';

/// A skill is a class-specific ability that the hero can perform in the game.
/// Unlike other passive capabilities from a class, a skill is selected by the
/// user and directly invoked.
abstract class Skill {
  String get name;

  /// Override this to return `true` if the skill can be used but needs a
  /// target to do so.
  bool get needsTarget => false;

  /// Override this to validate that the [Skill] can be used right now. For
  /// example, this is only `true` for the archery skill when the hero has a
  /// bow equipped.
  ///
  /// If this is overridden and returns `false`, it should also log an
  /// appropriate message so the user knows why it failed.
  bool canUse(Game game) => true;

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Skill]. If the skill needs a target, one will be passed in.
  /// Otherwise, it will be `null`.
  Action getUseAction(Game game, Vec target);
}
