import 'package:piecemeal/piecemeal.dart';

import 'flow.dart';
import 'stage.dart';
import 'tile.dart';

/// Keeps track of how audible the hero is from various places in the dungeon.
///
/// Used for monsters that hear the hero's actions.
class Sound {
  static final _maxDistance = 16;

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

  /// Calculates the level of audibility between [a] and [b].
  ///
  /// Returns a number from 1.0 (audible at full volume) and 0.0 (inaudible).
  double heroLoudnessAt(Vec pos) {
    if ((_stage.game.hero.pos - pos).kingLength > _maxDistance) return 0.0;

    _refresh();
    var cost = _flow.costAt(pos);
    if (cost == null) return 0.0;

    // In theory, this should be 1/distance^2 because sound attenuates with the
    // inverse square. But since the dungeon is relatively flat and we assume
    // sound bounces off the floor and ceiling, we'll say sound is more 2D and
    // expands as a circle, not a sphere, hence inverse linear.
    return 1.0 - cost / _maxDistance;
  }

  void _refresh() {
    // Don't recalculate if still valid.
    if (_flow != null && _stage.game.hero.pos == _flow.start) return;

    // TODO: Is this the right motility set?
    _flow = new _SoundFlow(_stage);
  }
}

class _SoundFlow extends Flow {
  _SoundFlow(Stage stage) : super(stage, stage.game.hero.pos);

  int tileCost(int parentCost, Vec pos, Tile tile) {
    // Stop propagating if we reach the max distance.
    if (parentCost >= Sound._maxDistance) return null;

    // Don't flow off the edge of the dungeon. We have to check for this
    // explicitly because we do flow through walls.
    if (pos.x < 1) return null;
    if (pos.x >= stage.width - 1) return null;
    if (pos.y < 1) return null;
    if (pos.y >= stage.height - 1) return null;

    // Closed doors block some but not all sound.
    if (tile.type.opensTo != null) return 8;

    // Walls almost block all sound, but a 1-thick wall does let a little
    // through.
    if (!tile.isFlyable) return 10;

    // Open tiles don't block any.
    return 1;
  }
}
