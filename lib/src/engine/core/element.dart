class Element {
  static const all = const [
    none,
    air,
    earth,
    fire,
    water,
    acid,
    cold,
    lightning,
    poison,
    dark,
    light,
    spirit
  ];

  static const allButNone = const [
    air,
    earth,
    fire,
    water,
    acid,
    cold,
    lightning,
    poison,
    dark,
    light,
    spirit
  ];

  static const none = const Element("none");
  static const air = const Element("air");
  static const earth = const Element("earth");
  static const fire = const Element("fire");
  static const water = const Element("water");
  static const acid = const Element("acid");
  static const cold = const Element("cold");
  static const lightning = const Element("lightning");
  static const poison = const Element("poison");
  static const dark = const Element("dark");
  static const light = const Element("light");
  static const spirit = const Element("spirit");

  static Element fromName(String name) {
    switch (name) {
      case "none":
        return none;
      case "air":
        return air;
      case "earth":
        return earth;
      case "fire":
        return fire;
      case "water":
        return water;
      case "acid":
        return acid;
      case "cold":
        return cold;
      case "lightning":
        return lightning;
      case "poison":
        return poison;
      case "dark":
        return dark;
      case "light":
        return light;
      case "spirit":
        return spirit;
      default:
        throw new ArgumentError('Unknown element name "$name".');
    }
  }

  final String name;

  String get capitalized => "${name[0].toUpperCase()}${name.substring(1)}";

  const Element(this.name);

  String toString() => name;
}
