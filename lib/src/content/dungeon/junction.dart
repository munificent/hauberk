import 'dart:collection';

import 'package:piecemeal/piecemeal.dart';

class Junction {
  /// The theme of the initial room this junction is attached to.
  final String theme;

  /// Points from the first room towards where the new room should be attached.
  ///
  /// A room must have an opposing junction in order to match.
  final Direction direction;

  /// The location of the junction.
  ///
  /// For a placed room, this is in absolute coordinates. For a room yet to be
  /// placed, it's relative to the room's tile array.
  final Vec position;

  /// How many times we've tried to place something at this junction.
  int tries = 0;

  Junction(this.theme, this.direction, this.position);
}

class JunctionSet {
  final Map<Vec, Junction> _byPosition = {};
  final Queue<Junction> _queue = new Queue();

  bool get isNotEmpty => _queue.isNotEmpty;

  Junction at(Vec pos) => _byPosition[pos];

  void add(Junction junction) {
    if (_byPosition.containsKey(junction.position)) return;

    _byPosition[junction.position] = junction;
    _queue.add(junction);
  }

  Junction takeNext() {
    var junction = _queue.removeFirst();
    _byPosition.remove(junction.position);
    return junction;
  }

  void removeAt(Vec pos) {
    if (!_byPosition.containsKey(pos)) return;

    var junction = _byPosition[pos];
    _byPosition.remove(pos);
    _queue.remove(junction);
  }
}
