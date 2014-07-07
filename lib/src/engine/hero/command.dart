library dngn.engine.hero.command;

import '../../util.dart';
import '../action_base.dart';
import '../game.dart';
import '../item.dart';
import '../melee.dart';

/// A command is a specific ability that the player can select for the hero to
/// perform.
abstract class Command {
  String get name;

  /// Override this to return `true` if the command can be used but needs a
  /// target to do so.
  bool get needsTarget => false;

  /// Override this to validate that the [Command] can be used right now. For
  /// example, this is only `true` for the archery command when the hero has a
  /// ranged weapon equipped.
  ///
  /// If this is overridden and returns `false`, it should also log an
  /// appropriate message so the user knows why it failed.
  bool canUse(Game game) => true;

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Command]. If the command needs a target, one will be passed
  /// in. Otherwise, it will be `null`.
  Action getUseAction(Game game, Vec target);
}
