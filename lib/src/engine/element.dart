part of engine;

class Element {
  static const NONE      = const Element(0);
  static const AIR       = const Element(1);
  static const EARTH     = const Element(2);
  static const FIRE      = const Element(3);
  static const WATER     = const Element(4);
  static const ACID      = const Element(5);
  static const COLD      = const Element(6);
  static const LIGHTNING = const Element(7);
  static const POISON    = const Element(8);
  static const DARK      = const Element(9);
  static const LIGHT     = const Element(10);
  static const SPIRIT    = const Element(11);

  final int _value;

  const Element(this._value);
}