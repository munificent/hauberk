import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../debug.dart';
import '../action/action.dart';
import '../action/walk.dart';
import '../core/game.dart';
import '../core/log.dart';
import '../hero/hero.dart';
import '../monster/breed.dart';
import '../monster/monster.dart';
import '../monster/monster_pathfinder.dart';
import '../stage/flow.dart';
import 'move.dart';

/// This defines the monster AI. AI is broken into a three level hierarchy.
///
/// The top sort-of level is the monster's "mood". This is a set of variables
/// that describe how the monster is "feeling". How afraid they are, how bored
/// they are, etc. These are the monster's senses and memory.
///
/// At the beginning of each turn, the monster uses these and some hysteresis
/// to determine it's *state*, which is how their mood manifests in behavior.
/// Where the "fear" mood fluctuates every turn, only when it reaches a high
/// enough point to trigger a transition to the "afraid" *state* does its
/// behavior change.
///
/// Most monsters the hero is interacting with are in the "awake" state.
/// Monsters off in the distances are usually asleep. Other states may be added
/// later: confused, blind, charmed, etc.
///
/// When awake, the monster has to decide what to do. It has a few options:
///
/// - It can perform a [Move], which are the "special" things different breeds
///   can do: teleportation, bolt attacks, etc.
/// - It can try to walk up to the hero and engage in melee combat.
/// - If it has a ranged attack move, it can try to get to a good vantage point
///   (not near the hero but still in range, with open LOS) and use a ranged
///   move.
///
/// Each move carries with it a little bit of logic to determine if it's a good
/// idea to use it. For example, the [HealMove] won't let itself be used if the
/// monster is at max health. In order to use a move, the monster must be
/// "recharged". Each move has a cost, and after using it, the monster must
/// recharge before another move can be performed. (Melee attacks have no cost.)
///
/// If a monster is recharged and does have a usable move, it will always prefer
/// to do that first. Once it's got no moves to do, it has to determine how it
/// wants to fight.
///
/// To choose between melee and ranged attacks, it decides how "cautious" it is.
/// The more damaging its ranged attacks are relative to melee, the more
/// cautious it is. Greater fear and lower health also make it more cautious.
/// If caution is above a threshold, the monster will prefer a ranged attack.
///
/// To get in position for that, it pathfinds to the nearest tile that's in
/// range and has an open line of sight to the hero. Checking for an open line
/// of sight obviously avoids friendly fire, but also makes monsters spread out
/// and flank the hero, which plays and looks cool.
///
/// Once it's on a good targeting tile, it will keep walking towards adjacent
/// tiles that are farther from the hero but still in range until it's fully
/// charged.
///
/// If it decides to go melee, it simply pathfinds to the hero and goes for it.
/// In either case, the end result is walking one tile (or possibly standing
/// in place.)
abstract class MonsterState {
  Monster _monster;

  void bind(Monster monster) {
    _monster = monster;
  }

  Monster get monster => _monster;

  Breed get breed => _monster.breed;

  Game get game => _monster.game;

  Vec get pos => _monster.pos;

  bool get isVisibleToHero => _monster.isVisibleToHero;

  void log(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    monster.log(message, noun1, noun2, noun3);
  }

  Action getAction();

  /// Applies the monster's meandering to [dir].
  Direction _meander(Direction dir) {
    var meander = breed.meander;

    if (monster.isBlinded) {
      // Being blinded makes the monster stumble around.
      meander += 50;
    } else if (pos + dir == game.hero.pos) {
      // Monsters are (mostly) smart enough to not meander when they're about
      // to melee. A small chance of meandering is still useful to get a
      // monster out of a doorway sometimes.
      meander ~/= 4;
    }

    // Should always have a chance to go the right direction.
    meander = math.min(meander, 90);

    if (!rng.percent(meander)) return dir;

    List<Direction> dirs;
    if (dir == Direction.none) {
      // Since the monster has no direction, any is equally valid.
      dirs = Direction.all;
    } else {
      dirs = [];

      // Otherwise, bias towards the direction the monster is headed.
      for (var i = 0; i < 3; i++) {
        dirs.add(dir.rotateLeft45);
        dirs.add(dir.rotateRight45);
      }

      for (var i = 0; i < 2; i++) {
        dirs.add(dir.rotateLeft90);
        dirs.add(dir.rotateRight90);
      }

      dirs.add(dir.rotateLeft90.rotateLeft45);
      dirs.add(dir.rotateRight90.rotateRight45);
    }

    dirs = dirs.where((dir) {
      var here = pos + dir;
      if (!monster.willOccupy(here)) return false;
      var actor = game.stage.actorAt(here);
      return actor == null || actor == game.hero;
    }).toList();

    if (dirs.isEmpty) return dir;
    return rng.item(dirs);
  }
}

class AsleepState extends MonsterState {
  Action getAction() => RestAction();
}

class AwakeState extends MonsterState {
  Action getAction() {
    // If on a burning etc. tile, try to get out.
    // TODO: Should consider moves like teleport that will help it escape.
    var escape = _escapeSubstance();
    if (escape != Direction.none) return WalkAction(escape);

    // If there is a worthwhile move, use it.
    var moves = breed.moves
        .where((move) => monster.canUse(move) && move.shouldUse(monster))
        .toList();
    if (moves.isNotEmpty) return rng.item(moves).getAction(monster);

    // If the monster doesn't pursue, then it does melee or waits.
    if (breed.flags.immobile) {
      var toHero = game.hero.pos - pos;

      if (toHero.kingLength != 1) return RestAction();

      // Map the offset to a direction.
      // TODO: Move this into piecemeal?
      for (var dir in Direction.all) {
        if (toHero == dir) return WalkAction(dir);
      }

      throw "unreachable";
    }

    // The monster doesn't have a move to use, so they are going to attack.
    // It needs to decide if it wants to do a ranged attack or a melee attack.
    monster.wantsToMelee = true;

    // First, it determines how "cautious" it is. Being more cautious makes the
    // monster prefer a ranged attack when possible.

    // Determine how much ranged damage it can dish out per turn.
    var rangedDamage = 0.0;
    var rangedAttacks = 0.0;

    for (var move in breed.moves) {
      if (move is! RangedMove) continue;

      rangedDamage += (move as RangedMove).attack.damage / move.rate;
      rangedAttacks++;

      // TODO: Take elements into account?
      // TODO: Take range into account? Any other factors?
      // TODO: Smart monsters should take hero resists into account.
    }

    if (rangedAttacks != 0) {
      // Determine how much melee damage it can dish out per turn.
      var meleeDamage = 0.0;
      var meleeAttacks = 0.0;

      for (var attack in breed.attacks) {
        // Monsters don't have any raw ranged attacks, just ranged moves.
        assert(!attack.isRanged);
        meleeDamage += attack.damage;
        meleeAttacks++;

        // TODO: Smart monsters should take hero resists into account.
      }

      if (meleeAttacks > 0) meleeDamage /= meleeAttacks;
      rangedDamage /= rangedAttacks;

      // The more damage a monster can do with ranged attacks, relative to its
      // melee attacks, the more cautious it is.
      var damageRatio = 100 * rangedDamage / (rangedDamage + meleeDamage);
      var caution = damageRatio;

      // Being afraid makes the monster more cautious.
      caution += monster.fear;

      // Being close to death makes the monster more cautious.
      var nearDeath = 100 * (1 - monster.health / monster.maxHealth);
      caution += nearDeath;

      // TODO: Breed-specific "aggression" modifier to caution.

      // Less likely to break away for a ranged attack if already in melee
      // distance.
      if (pos - game.hero.pos <= 1) {
        monster.wantsToMelee = caution < 60;
      } else {
        monster.wantsToMelee = caution < 30;
      }
    }

    // Now that we know what the monster *wants* to do, reconcile it with what
    // they're able to do.
    var meleeDir = _findMeleePath();
    var rangedDir = rangedAttacks > 0 ? _findRangedPath() : null;

    Direction walkDir;
    if (monster.wantsToMelee) {
      walkDir = meleeDir ?? rangedDir;
    } else {
      walkDir = rangedDir ?? meleeDir;
    }

    walkDir = meleeDir;

    if (walkDir == null) walkDir = Direction.none;

    return WalkAction(_meander(walkDir));
  }

  /// If the monster is currently on a substance tile, find the nearest path
  /// out of the substance.
  ///
  /// Otherwise, returns [Direction.none].
  Direction _escapeSubstance() {
    // If we're not on a bad tile, don't worry.
    if (game.stage[monster.pos].substance == 0) return Direction.none;

    // Otherwise, we'll need to actually pathfind to reach a good vantage point.
    var flow = MotilityFlow(game.stage, pos, monster.motilities,
        avoidSubstances: true);
    return flow.directionToBestWhere((pos) => game.stage[pos].substance == 0);
  }

  /// Tries to find a path a desirable position for using a ranged [Move].
  ///
  /// Returns the [Direction] to take along the path. Returns [Direction.none]
  /// if the monster's current position is a good ranged spot. Returns `null`
  /// if no good ranged position could be found.
  Direction _findRangedPath() {
    var maxRange = 9999;
    for (var move in breed.moves) {
      if (move.range > 0 && move.range < maxRange) maxRange = move.range;
    }

    bool isValidRangedPosition(Vec pos) {
      // Ignore tiles that are out of range.
      var toHero = pos - game.hero.pos;
      if (toHero > maxRange) return false;

      // TODO: Being near max range reduces damage. Should try to be within
      // max damage range.

      // Don't go point-blank.
      if (toHero.kingLength <= 2) return false;

      // Ignore occupied tiles.
      var actor = game.stage.actorAt(pos);
      if (actor != null && actor != monster) return false;

      // Ignore tiles that don't have a line-of-sight to the hero.
      return _hasLosFrom(pos);
    }

    // First, see if the current tile or any of its neighbors are good. Once in
    // a tolerable position, the monster will hill-climb to get into a local
    // optimal position (which basically means as far from the hero as possible
    // while still in range).
    Direction best;
    var bestDistance = 0;

    if (isValidRangedPosition(pos)) {
      best = Direction.none;
      bestDistance = (pos - game.hero.pos).kingLength;
    }

    for (var dir in Direction.all) {
      var pos = monster.pos + dir;
      if (!monster.willEnter(pos)) continue;
      if (!isValidRangedPosition(pos)) continue;

      var distance = (pos - game.hero.pos).kingLength;
      if (distance > bestDistance) {
        best = dir;
        bestDistance = distance;
      }
    }

    if (best != null) return best;

    // Otherwise, we'll need to actually pathfind to reach a good vantage point.
    var flow = MotilityFlow(game.stage, pos, monster.motilities,
        maxDistance: maxRange, avoidSubstances: true);
    var dir = flow.directionToBestWhere(isValidRangedPosition);
    if (dir != Direction.none) {
      Debug.logMonster(monster, "Ranged position $dir");
      return dir;
    }

    // If we get here, couldn't find to a ranged position at all. We may be
    // cornered, or the hero may be surrounded.
    Debug.logMonster(monster, "No good ranged position");
    return null;
  }

  Direction _findMeleePath() {
    var losDir = _findLosWalkPath();
    if (losDir != null) return losDir;

    return MonsterPathfinder.findDirection(game.stage, monster);
  }

  /// Try to find a direction to walk towards the hero based on line-of-sight.
  ///
  /// We prefer this over A* when the monster does have a straight path to the
  /// hero for two reasons:
  ///
  /// 1. It's faster. In open areas, A* wastes time examining the multiple
  ///    identical paths to the hero.
  ///
  /// 2. It produces better walking directions. When the monster is diagonal
  ///    to the hero, A* will always prefer an intercardinal move direction,
  ///    even if the hero is almost a cardinal direction away. Bresenham will
  ///    pick a direction that's closest to the direction pointing at the hero.
  Direction _findLosWalkPath() {
    // TODO: Need to verify that this does actually help performance.
    Vec first;
    var length = 1;

    for (var pos in Line(pos, game.hero.pos)) {
      first ??= pos;

      // Don't walk into fire, etc.
      // TODO: Take immunity into account.
      if (game.stage[pos].substance > 0) return null;

      // TODO: Should not walk through doors since that might not be the
      // fastest path.
      if (!monster.canOccupy(pos)) return null;

      // Don't walk into other monsters.
      var actor = game.stage.actorAt(pos);
      if (actor != null && actor is! Hero) return null;

      if (++length >= breed.tracking) return null;

      if (pos == game.hero.pos) break;
    }

    var step = first - pos;
    if (step.y == -1) {
      if (step.x == -1) {
        return Direction.nw;
      } else if (step.x == 0) {
        return Direction.n;
      } else {
        return Direction.ne;
      }
    } else if (step.y == 0) {
      if (step.x == -1) {
        return Direction.w;
      } else {
        return Direction.e;
      }
    } else {
      if (step.x == -1) {
        return Direction.sw;
      } else if (step.x == 0) {
        return Direction.s;
      } else {
        return Direction.se;
      }
    }
  }

  /// Returns `true` if there is an open LOS from [from] to the hero.
  bool _hasLosFrom(Vec from) {
    for (var step in Line(from, game.hero.pos)) {
      if (step == game.hero.pos) return true;
      if (game.stage[step].blocksView) return false;
      var actor = game.stage.actorAt(step);
      if (actor != null && actor != this) return false;
    }

    throw "unreachable";
  }
}

class AfraidState extends MonsterState {
  Action getAction() {
    // TODO: Take light and the breed's light preference into account.
    // If we're already hidden, rest.
    if (game.stage[pos].isOccluded) return RestAction();

    // TODO: Should not walk past hero to get to escape!
    // Run to the nearest place the hero can't see.
    var flow = MotilityFlow(game.stage, pos, monster.motilities,
        maxDistance: breed.tracking, avoidSubstances: true);
    // TODO: Should monsters prefer darkness too?
    var dir = flow.directionToBestWhere((pos) => game.stage[pos].isOccluded);

    if (dir != Direction.none) {
      Debug.logMonster(monster, "Fleeing $dir out of sight");
      return WalkAction(_meander(dir));
    }

    // If we couldn't find a hidden tile, at least try to get some distance.
    var heroDistance = (pos - game.hero.pos).kingLength;
    var farther = Direction.all.where((dir) {
      var here = pos + dir;
      if (!monster.willEnter(here)) return false;
      return (here - game.hero.pos).kingLength > heroDistance;
    });

    if (farther.isNotEmpty) {
      dir = rng.item(farther.toList());
      Debug.logMonster(monster, "Fleeing $dir away from hero");
      return WalkAction(_meander(dir));
    }

    // If we got here, we couldn't escape. Cornered!
    // TODO: Kind of hacky.
    var state = AwakeState();
    monster.changeState(state);
    return state.getAction();
  }
}
