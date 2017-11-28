import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';

class Element {
  static final none = new Element("none", "No", 1.0);

  final String name;
  final String abbreviation;

  /// The multiplier to a experience gained when killing a monster with a move
  /// or attack using this element.
  final double experience;

  String get capitalized => "${name[0].toUpperCase()}${name.substring(1)}";

  /// Creates a side-effect action to perform when an [Attack] of this element
  /// hits an actor for [damage] or `null` if this element has no side effect.
  final Action Function(int damage) attackAction;

  /// Creates a side-effect action to perform when an area attack of this
  /// element hits a tile or `null` if this element has no effect.
  final Action Function(Vec pos) floorAction;

  Element(this.name, this.abbreviation, this.experience,
      {Action Function(int damage) attack, Action Function(Vec pos) floor})
      : attackAction = attack ?? ((_) => null),
        floorAction = floor ?? ((_) => null);

  String toString() => name;
}
