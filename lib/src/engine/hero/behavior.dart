import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../action/walk.dart';
import '../monster/monster.dart';
import 'hero.dart';

/// What the [Hero] is "doing". If the hero has no behavior, he is waiting for
/// user input. Otherwise, the behavior will determine which [Action]s he
/// performs.
///
/// Behavior is coarser-grained than actions. A single behavior may produce a
/// series of actions. For example, when running, it will continue to produce
/// walk actions until disturbed.
abstract class Behavior {
  bool canPerform(Hero hero);
  Action getAction(Hero hero);
}

/// A simple one-shot behavior that performs a given [Action] and then reverts
/// back to waiting for input.
class ActionBehavior extends Behavior {
  final Action action;

  ActionBehavior(this.action);

  @override
  bool canPerform(Hero hero) => true;

  @override
  Action getAction(Hero hero) {
    hero.waitForInput();
    return action;
  }
}

/// Automatic resting. With this [Behavior], the [Hero] will rest each turn
/// until any of the following occurs:
///
/// * He is fully rested.
/// * He gets hungry.
/// * He is "disturbed" and something gets hit attention, like a [Monster]
///   moving, being hit, etc.
class RestBehavior extends Behavior {
  @override
  bool canPerform(Hero hero) {
    // See if done resting.
    if (hero.health == hero.maxHealth) return false;
    // TODO: Keep resting if focus is not at max?

    if (hero.stomach == 0) {
      hero.game.log.message("You must eat before you can rest.");
      return false;
    }

    return true;
  }

  @override
  Action getAction(Hero hero) => RestAction();
}

/// Automatic running.
class RunBehavior extends Behavior {
  bool firstStep = true;

  /// Whether the hero is running with open tiles to their left.
  bool? openLeft;

  /// Whether the hero is running with open tiles to their right.
  bool? openRight;

  Direction direction;

  RunBehavior(this.direction);

  @override
  bool canPerform(Hero hero) {
    // On first step, always try to go in direction player pressed.
    if (firstStep) return true;

    if (openLeft == null) {
      // On the second step, figure out if we're in a passage and which way
      // it's going. If the hero is running straight (NSEW), allow up to a 90°
      // turn. This covers cases like:
      //
      //     ####
      //     .@.#
      //     ##.#
      //
      // If the player presses right here, we want to take a first step, then
      // turn and run south. If the hero is running diagonally, we only allow
      // a 45° turn. That way it doesn't get confused by cases like:
      //
      //      #.#
      //     ##.##
      //     .@...
      //     #####
      //
      // If the player presses NE here, we want to run north and not get
      // confused by the east passage.
      var dirs = [
        direction.rotateLeft45,
        direction,
        direction.rotateRight45,
      ];

      if (Direction.cardinal.contains(direction)) {
        dirs.add(direction.rotateLeft90);
        dirs.add(direction.rotateRight90);
      }

      var openDirs = dirs.where((dir) => _isOpen(hero, dir));

      if (openDirs.isEmpty) return false;

      if (openDirs.length == 1) {
        // Entering a passage.
        openLeft = false;
        openRight = false;

        // The direction may change if the first step entered a passage from
        // around a corner.
        direction = openDirs.first;
      } else {
        // Entering an open area.
        openLeft = _isOpen(hero, direction.rotateLeft90);
        openRight = _isOpen(hero, direction.rotateRight90);
      }
    } else if (!openLeft! && !openRight!) {
      if (!_runInPassage(hero)) return false;
    } else {
      if (!_runInOpen(hero)) return false;
    }

    return _shouldKeepRunning(hero);
  }

  @override
  Action getAction(Hero hero) {
    firstStep = false;
    return WalkAction(direction);
  }

  /// Advance one step while in a passage.
  ///
  /// The basic idea is to look ahead two steps from the current position and
  /// choose a direction for the first step based on where the hero is able
  /// to get. Looking two steps ahead enables the hero to cut corners, like:
  ///
  ///     #####       #####       #####       #####
  ///     -@..#       .-@.#       ..\.#       ....#
  ///     ###.#  -->  ###.#  -->  ###@#  -->  ###|#
  ///       #.#         #.#         #.#         #@#
  ///
  /// Note how the hero never steps all the way into the corner (which would
  /// require another step and make the hero slower than chasing monsters).
  bool _runInPassage(Hero hero) {
    // Note that "near" in this function means one step from the hero and "far"
    // means two.

    // The first step directions that lead to an open position.
    var dirsToNear = <Direction>[];

    // The first step directions that lead to an open second position.
    var dirsToFar = <Direction>{};

    // The set of tiles reachable in two steps.
    var farPositions = <Vec>{};

    // Consider one step, allowing up to a 90° turn.
    var possibleFirstDirs = [
      direction.rotateLeft90,
      direction.rotateLeft45,
      direction,
      direction.rotateRight45,
      direction.rotateRight90,
    ];

    for (var firstDir in possibleFirstDirs) {
      // Ignore unreachable tiles.
      var firstPos = hero.pos + firstDir;
      if (!_isOpenAt(hero, firstPos)) continue;

      // We can get here, so it's a viable step.
      dirsToNear.add(firstDir);

      // From here, consider possible second steps, allowing up to a 45° turn.
      var possibleSecondDirs = [
        firstDir.rotateLeft45,
        firstDir,
        firstDir.rotateRight45,
      ];

      for (var secondDir in possibleSecondDirs) {
        // Ignore unreachable tiles.
        var secondPos = firstPos + secondDir;
        if (!_isOpenAt(hero, secondPos)) continue;

        dirsToFar.add(firstDir);
        farPositions.add(secondPos);
      }
    }

    switch (dirsToFar.length) {
      case 0 when dirsToNear.length == 1:
        // We can't reach any far points and only one near point, so may as well
        // go there. In other words, go all the way into a dead end:
        //
        //     ####
        //     >@.#
        //     ####
        direction = dirsToNear.first;
        return true;

      case 1:
        // There's only one way to go that leads to far destinations, so pick
        // that. There may be multiple far points that can be reached going
        // this way, as in:
        //
        //     #####
        //     >@12#
        //     ###3#
        //       #.#
        //
        // Here, both 2 and 3 are far reachable tiles, but you have to go
        // through 1 to get to either, so 1 is unambiguously the best path. This
        // lets the hero walk towards corners.
        direction = dirsToFar.first;
        return true;

      case 2 when farPositions.length == 1:
        // There is only one far tile that's reachable, but there are two near
        // paths to reach it. This is usually from going through a tight corner
        // or zig-zag like:
        //
        //     #####
        //     .>@1####
        //     ###23...
        //       ######
        //
        // Here, the hero can reach 3 by going through either 1 (E then SE) or
        // 2 (SE then E). So the first step is ambiguous, but the ambiguity
        // isn't *interesting* enough to be worth stopping.
        //
        // If the two possible directions are only 45° apart and both reach the
        // same far point, just (mostly arbitrarily) pick the direction that's
        // closest to the current heading.
        //
        // If the two possible directions *aren't* 45° apart, then it is a more
        // ambiguous path, as in:
        //
        //       ###
        //     ###1###
        //     .>@#3..
        //     ###2###
        //       ###
        //
        // Here, there is a real fork in the road, so we don't choose and
        // instead stop.
        if (dirsToFar.contains(direction)) {
          return true;
        } else if (dirsToFar.contains(direction.rotateLeft45) &&
            dirsToFar.contains(direction.rotateLeft90)) {
          direction = direction.rotateLeft45;
          return true;
        } else if (dirsToFar.contains(direction.rotateRight45) &&
            dirsToFar.contains(direction.rotateRight90)) {
          direction = direction.rotateRight45;
          return true;
        }
    }

    return false;
  }

  bool _runInOpen(Hero hero) {
    // Whether or not the hero's left and right sides are open cannot change.
    // In other words, if they are running along a wall on their left (closed on
    // left, open on right), they will stop if they enter an open room (open on
    // both).
    var nextLeft = _isOpen(hero, direction.rotateLeft45);
    var nextRight = _isOpen(hero, direction.rotateRight45);
    return openLeft == nextLeft && openRight == nextRight;
  }

  /// Returns `true` if the hero can run one step in the current direction.
  ///
  /// Returns `false` if they should stop because they'd hit a wall or actor.
  bool _shouldKeepRunning(Hero hero) {
    var pos = hero.pos + direction;
    var stage = hero.game.stage;

    if (!hero.canEnter(pos)) return false;

    // Don't open doors. The hero *could* run through it, but they probably
    // don't want to since the player doesn't know what's past it.
    if (stage[pos].isClosedDoor) return false;

    // Whether the hero knows there is an actor at [pos].
    bool actorAt(Vec pos) => stage[pos].isVisible && stage.actorAt(pos) != null;

    // Don't run into someone.
    if (actorAt(pos)) return false;

    // Don't run next to someone.
    if (actorAt(pos + direction.rotateLeft90)) return false;
    if (actorAt(pos + direction.rotateLeft45)) return false;
    if (actorAt(pos + direction)) return false;
    if (actorAt(pos + direction.rotateRight45)) return false;
    if (actorAt(pos + direction.rotateRight90)) return false;

    // Don't run into a substance.
    if (stage[pos].substance > 0) return false;

    return true;
  }

  // TODO: Leaks information. Should take explored/visible into account.
  bool _isOpen(Hero hero, Vec offset) => _isOpenAt(hero, hero.pos + offset);

  // TODO: Leaks information. Should take explored/visible into account.
  bool _isOpenAt(Hero hero, Vec pos) {
    return hero.game.stage.bounds.contains(pos) &&
        hero.game.stage[pos].isTraversable;
  }
}
