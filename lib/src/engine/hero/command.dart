import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/game.dart';

/// A command is a specific ability that the player can select for the hero to
/// perform.
///
/// Some commands require additional data to be performed -- a target position
/// or a direction. Those will implement one of the subclasses, [TargetCommand]
/// or [DirectionCommand].
abstract class Command {
  /// The name of the command.
  String get name;

  /// Override this to validate that the [Command] can be used right now. For
  /// example, this is only `true` for the archery command when the hero has a
  /// ranged weapon equipped.
  bool canUse(Game game) => true;

  // TODO: Add getAction() here when there are commands that don't require a
  // target or direction.
}

/// A command that requires a target position to perform.
abstract class TargetCommand extends Command {
  /// The maximum range of the target from the hero.
  num getRange(Game game) => 0;

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Command].
  Action getTargetAction(Game game, Vec target);
}

/// A command that requires a direction to perform.
abstract class DirectionCommand extends Command {
  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Command].
  Action getDirectionAction(Game game, Direction dir);
}