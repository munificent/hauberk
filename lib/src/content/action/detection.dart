import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

enum DetectType {
  exit,
  item,
}

/// An [Action] that marks all tiles containing [Item]s explored.
class DetectAction extends Action {
  final Set<DetectType> _types;
  final int _maxDistance;

  /// The different distances (squared) that contain tiles, in reverse order
  /// for easy removal of the nearest distance.
  List<List<Vec>> _tilesByDistance;

  bool get isImmediate => false;

  DetectAction(Iterable<DetectType> types, [this._maxDistance])
      : _types = types.toSet();

  ActionResult onPerform() {
    if (_tilesByDistance == null) {
      _findTiles();
    }

    // If we've shown all the tiles, we're done.
    if (_tilesByDistance.isEmpty) return ActionResult.success;

    for (var pos in _tilesByDistance.removeLast()) {
      game.stage.explore(pos, force: true);
      addEvent(EventType.detect, pos: pos);
    }

    return ActionResult.notDone;
  }

  /// Finds all the tiles that should be detected and organizes them from
  /// farthest to nearest.
  void _findTiles() {
    var distanceMap = <int, List<Vec>>{};

    void addTile(Vec pos) {
      var distance = (actor.pos - pos).lengthSquared;
      if (_maxDistance != null && distance > _maxDistance * _maxDistance) {
        return;
      }

      distanceMap.putIfAbsent(distance, () => []);
      distanceMap[distance].add(pos);
    }

    var foundExits = 0;
    if (_types.contains(DetectType.exit)) {
      for (var pos in game.stage.bounds) {
        // Ignore already found ones.
        if (game.stage[pos].isExplored) continue;

        if (!game.stage[pos].isExit) continue;

        foundExits++;
        addTile(pos);
      }
    }

    var foundItems = 0;
    if (_types.contains(DetectType.item)) {
      game.stage.forEachItem((item, pos) {
        // Ignore items already found.
        if (game.stage[pos].isExplored) return;

        foundItems++;
        addTile(pos);
      });
    }

    if (foundExits > 0) {
      if (foundItems > 0) {
        log('{1} sense[s] hidden secrets in the dark!', actor);
      } else {
        log('{1} sense[s] places to escape!', actor);
      }
    } else {
      if (foundItems > 0) {
        log('{1} sense[s] the treasures held in the dark!', actor);
      } else {
        log('The darkness holds no secrets.');
      }
    }

    var distances = distanceMap.keys.toList();
    distances.sort((a, b) => b.compareTo(a));

    _tilesByDistance =
        distances.map((distance) => distanceMap[distance]).toList();
  }
}
