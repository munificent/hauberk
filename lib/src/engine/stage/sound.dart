import 'package:piecemeal/piecemeal.dart';

import 'flow.dart';
import 'pathfinder.dart';
import 'stage.dart';
import 'tile.dart';

/// Keeps track of how audible the hero is from various places in the dungeon.
///
/// Used for monsters that hear the hero's actions.
class Sound {
  static const restNoise = 0.05;
  static const normalNoise = 0.25;
  static const attackNoise = 1.0;

  static const maxDistance = 16;

  final Stage _stage;

  /// A [Flow] that calculates how much sound attenuates from the hero's
  /// current position.
  Flow _flow;

  Sound(this._stage);

  /// Marks the sound stage as needing recalculation.
  ///
  /// This should be called if a tile in the dungeon is changed in a way that
  /// affects how it attenuates sound. For example, opening a door.
  void dirty() {
    // TODO: Especially during a fight, the hero probably moves a bunch but
    // reoccupies the same set of tiles repeatedly. It may be worth keeping a
    // cache of some fixed number of recently used flows instead of only a
    // single one.
    _flow = null;
  }

  /// How loud the hero is from [pos] in terms of sound flow, up to
  /// [Sound.maxDistance].
  ///
  /// Returns a number between 0.0 (completely inaudible) to 1.0 (maximum
  /// volume). Does not take hero noise into account. This is how well the hero
  /// can be heard in general.
  double heroVolume(Vec pos) => _volume(_heroAuditoryDistance(pos));

  double volumeBetween(Vec from, Vec to) {
    if ((to - from).kingLength > maxDistance) return 0.0;

    var distance = _SoundPathfinder(_stage, from, to).search();
    return _volume(distance);
  }

  /// How far away the hero is from [pos] in terms of sound flow, up to
  /// [Sound.maxDistance].
  ///
  /// Returns the auditory equivalent of the number of open tiles away the hero
  /// is. (It may be fewer actual tiles if there are sound-deadening obstacles
  /// in the way like doors or walls.
  ///
  /// Smaller numbers mean louder sound.
  int _heroAuditoryDistance(Vec pos) {
    if ((_stage.game.hero.pos - pos).kingLength > maxDistance) {
      return maxDistance;
    }

    _refresh();
    return _flow.costAt(pos) ?? maxDistance;
  }

  /// Converts [auditoryDistance] to a volume.
  double _volume(int auditoryDistance) {
    // Normalize.
    var volume = (Sound.maxDistance - auditoryDistance) / Sound.maxDistance;

    // Sound attenuates with the square of the distance. This is realistic but
    // also means that even hard-of-hearing monsters will hero the hero once
    // they are very close.
    return volume * volume;
  }

  void _refresh() {
    // Don't recalculate if still valid.
    if (_flow != null && _stage.game.hero.pos == _flow.start) return;

    // TODO: Is this the right motility set?
    _flow = _SoundFlow(_stage);
  }
}

class _SoundFlow extends Flow {
  _SoundFlow(Stage stage) : super(stage, stage.game.hero.pos);

  int tileCost(int parentCost, Vec pos, Tile tile, bool isDiagonal) {
    // Stop propagating if we reach the max distance.
    if (parentCost >= Sound.maxDistance) return null;

    // Don't flow off the edge of the dungeon. We have to check for this
    // explicitly because we do flow through walls.
    if (pos.x < 1) return null;
    if (pos.x >= stage.width - 1) return null;
    if (pos.y < 1) return null;
    if (pos.y >= stage.height - 1) return null;

    return _tileCost(tile);
  }
}

class _SoundPathfinder extends Pathfinder<int> {
  _SoundPathfinder(Stage stage, Vec from, Vec to) : super(stage, from, to);

  int processStep(Path path) {
    if (path.cost > Sound.maxDistance) return Sound.maxDistance;
    return null;
  }

  int stepCost(Vec pos, Tile tile) {
    return _tileCost(tile);
  }

  int reachedGoal(Path path) => path.cost;

  /// There's no path to the goal so, just pick the path that gets nearest to
  /// it and hope for the best. (Maybe someone will open a door later or
  /// something.)
  int unreachableGoal() => Sound.maxDistance;
}

int _tileCost(Tile tile) {
  // Closed doors block some but not all sound.
  if (tile.isClosedDoor) return 8;

  // Walls almost block all sound, but a 1-thick wall does let a little
  // through.
  if (!tile.isFlyable) return 10;

  // Open tiles don't block any.
  return 1;
}
