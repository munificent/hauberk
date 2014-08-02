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

  static const NONE      = const Element("None");
  static const AIR       = const Element("Air");
  static const EARTH     = const Element("Earth");
  static const FIRE      = const Element("Fire");
  static const WATER     = const Element("Water");
  static const ACID      = const Element("Acid");
  static const COLD      = const Element("Cold");
  static const LIGHTNING = const Element("Lightning");
  static const POISON    = const Element("Poison");
  static const DARK      = const Element("Dark");
  static const LIGHT     = const Element("Light");
  static const SPIRIT    = const Element("Spirit");

  static Element fromName(String name) {
    switch (name) {
      case "None":      return NONE;
      case "Air":       return AIR;
      case "Earth":     return EARTH;
      case "Fire":      return FIRE;
      case "Water":     return WATER;
      case "Acid":      return ACID;
      case "Cold":      return COLD;
      case "Lightning": return LIGHTNING;
      case "Poison":    return POISON;
      case "Dark":      return DARK;
      case "Light":     return LIGHT;
      case "Spirit":    return SPIRIT;
      default: throw new ArgumentError('Unknown element name "$name".');
    }
  }

  final String name;

  const Element(this.name);

  String toString() => name;
}