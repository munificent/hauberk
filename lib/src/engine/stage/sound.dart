import 'package:piecemeal/piecemeal.dart';

import 'flow.dart';
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

  /// How far away the [Hero] is from [pos] in terms of sound flow, up to
  /// [Sound.maxDistance].
  ///
  /// Returns the auditory equivalent of the number of open tiles away the hero
  /// is. (It may be fewer actual tiles if there are sound-deadening obstacles
  /// in the way like doors or walls.
  ///
  /// Smaller numbers mean louder sound.
  int heroAuditoryDistance(Vec pos) {
    if ((_stage.game.hero.pos - pos).kingLength > maxDistance) {
      return maxDistance;
    }

    _refresh();
    return _flow.costAt(pos) ?? maxDistance;
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

  int tileCost(int parentCost, Vec pos, Tile tile, bool isDiagonal) {
    // Stop propagating if we reach the max distance.
    if (parentCost >= Sound.maxDistance) return null;

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
