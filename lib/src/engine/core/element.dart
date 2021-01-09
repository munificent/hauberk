import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import 'combat.dart';

class Element {
  static final none = Element("none", "No", 1.0);

  final String name;
  final String abbreviation;

  /// Text displayed when an item is destroyed by this element.
  final String destroyMessage;

  /// Whether this element emanates light when a substance on the ground.
  final bool emanates;

  /// The multiplier to experience gained when killing a monster with a move or
  /// attack using this element.
  final double experience;

  String get capitalized => "${name[0].toUpperCase()}${name.substring(1)}";

  /// Creates a side-effect action to perform when an [Attack] of this element
  /// hits an actor for `damage` or `null` if this element has no side effect.
  final Action Function(int damage) attackAction;

  /// Creates a side-effect action to perform when an area attack of this
  /// element hits a tile or `null` if this element has no effect.
  final Action Function(Vec pos, Hit hit, num distance, int fuel) floorAction;

  Element(this.name, this.abbreviation, this.experience,
      {bool emanates,
      String destroyMessage,
      Action Function(int damage) attack,
      Action Function(Vec pos, Hit hit, num distance, int fuel) floor})
      : emanates = emanates ?? false,
        destroyMessage = destroyMessage ?? "",
        attackAction = attack ?? ((_) => null),
        floorAction = floor ?? ((_, __, ___, ____) => null);

  String toString() => name;
}
