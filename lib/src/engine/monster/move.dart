import '../action/action.dart';
import '../core/attack.dart';
import '../monster/monster.dart';

/// A [Move] is an action that a [Monster] can perform aside from the basic
/// walking and melee attack actions. Moves include things like spells, breaths,
/// and missiles.
abstract class Move {
  /// The frequency at which the monster can perform this move (with some
  /// randomness added in).
  ///
  /// A rate of 1 means the monster can perform the move roughly every turn.
  /// A rate of 10 means it can perform it about one in ten turns. Fractional
  /// rates are allowed.
  final num rate;

  /// The range of this move if it's a ranged one, or `0` otherwise.
  int get range => 0;

  /// The experience gained by killing a [Monster] with this move.
  ///
  /// This should take the power of the move into account, but not its rate.
  num get experience;

  Move(this.rate);

  /// Returns `true` if the monster would reasonably perform this move right
  /// now.
  bool shouldUse(Monster monster) => true;

  /// Called when the [Monster] has selected this move. Returns an [Action] that
  /// performs the move.
  Action getAction(Monster monster) {
    monster.useMove(this);
    return onGetAction(monster);
  }

  /// Create the [Action] to perform this move.
  Action onGetAction(Monster monster);
}

/// Base class for a Move that performs a ranged attack in some way.
///
/// The monster AI looks for this to determine whether it should go for melee
/// or ranged behavior.
abstract class RangedMove extends Move {
  final Attack attack;

  int get range => attack.range;

  RangedMove(num rate, this.attack) : super(rate);
}
