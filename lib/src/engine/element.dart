library hauberk.engine.element;

class Element {
  static const ALL = const [
    NONE,
    AIR,
    EARTH,
    FIRE,
    WATER,
    ACID,
    COLD,
    LIGHTNING,
    POISON,
    DARK,
    LIGHT,
    SPIRIT
  ];

  static const NONE      = const Element("none");
  static const AIR       = const Element("air");
  static const EARTH     = const Element("earth");
  static const FIRE      = const Element("fire");
  static const WATER     = const Element("water");
  static const ACID      = const Element("acid");
  static const COLD      = const Element("cold");
  static const LIGHTNING = const Element("lightning");
  static const POISON    = const Element("poison");
  static const DARK      = const Element("dark");
  static const LIGHT     = const Element("light");
  static const SPIRIT    = const Element("spirit");

  static Element fromName(String name) {
    switch (name) {
      case "none":      return NONE;
      case "air":       return AIR;
      case "earth":     return EARTH;
      case "fire":      return FIRE;
      case "water":     return WATER;
      case "acid":      return ACID;
      case "cold":      return COLD;
      case "lightning": return LIGHTNING;
      case "poison":    return POISON;
      case "dark":      return DARK;
      case "light":     return LIGHT;
      case "spirit":    return SPIRIT;
      default: throw new ArgumentError('Unknown element name "$name".');
    }
  }

  final String name;

  const Element(this.name);

  String toString() => name;
}