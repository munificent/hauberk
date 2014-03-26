library dngn.engine.element;

class Element {
  static const NONE      = const Element(0, "None");
  static const AIR       = const Element(1, "Air");
  static const EARTH     = const Element(2, "Earth");
  static const FIRE      = const Element(3, "Fire");
  static const WATER     = const Element(4, "Water");
  static const ACID      = const Element(5, "Acid");
  static const COLD      = const Element(6, "Cold");
  static const LIGHTNING = const Element(7, "Lightning");
  static const POISON    = const Element(8, "Poison");
  static const DARK      = const Element(9, "Dark");
  static const LIGHT     = const Element(10, "Light");
  static const SPIRIT    = const Element(11, "Spirit");

  final int _value;
  final String _name;

  const Element(this._value, this._name);

  String toString() => _name;
}