/// Enum-like class defining ways that monsters can move over tiles.
///
/// Each [TileType] has a set of motilities that determine which kind of
/// movement is needed to enter the tile. Monsters and the hero have a set of
/// motilities that determine which ways they are able to move. In order to
/// move into a tile, the actor must have one of the tile's motilities.
class Motility {
  // TODO: Should these be in content, engine, or a mixture of both?
  static final Motility door = new Motility("door");
  static final Motility fly = new Motility("fly");
  static final Motility swim = new Motility("swim");
  static final Motility walk = new Motility("walk");

  /// Each motility object has a bit value that is used by MotilitySet to store
  /// a set of motilities efficiently.
  static int _nextBit = 1;

  final String name;
  final int _bit = _nextBit;

  Motility(this.name) {
    _nextBit <<= 1;
  }
}

class MotilitySet {
  static final walk = new MotilitySet([Motility.walk]);
  static final walkAndDoor = new MotilitySet([Motility.walk, Motility.door]);
  static final walkAndFly = new MotilitySet([Motility.walk, Motility.fly]);

  int _bitMask = 0;

  MotilitySet([Iterable<Motility> iterable]) {
    if (iterable != null) {
      for (var motility in iterable) {
        add(motility);
      }
    }
  }

  void add(Motility motility) {
    _bitMask = _bitMask | motility._bit;
  }

  void addAll(Iterable<Motility> motilities) {
    motilities.forEach(add);
  }

  bool contains(Motility motility) => _bitMask & motility._bit != 0;

  bool overlaps(MotilitySet other) => _bitMask & other._bitMask != 0;
}

class TileType {
  final String name;
  final bool isExit;
  final appearance;
  TileType opensTo;
  TileType closesTo;

  final MotilitySet motilities;

  bool get isTraversable => canEnter(Motility.walk) || (opensTo != null);
  bool get isWalkable => canEnter(Motility.walk);

  TileType(this.name, this.appearance, Iterable<Motility> motilities,
      {this.isExit})
      : motilities = new MotilitySet(motilities);

  bool canEnter(Motility motility) => this.motilities.contains(motility);
  bool canEnterAny(MotilitySet motilities) =>
      this.motilities.overlaps(motilities);
}

class Tile {
  TileType type;
  bool _visible = false;

  Tile();

  bool get visible => _visible;
  void set visible(bool value) {
    if (value) isExplored = true;
    _visible = value;
  }

  /// Sets the visibility of this tile to [visible].
  ///
  /// Returns `true` if this is the first time the tile has been made visible.
  bool setVisible(bool visible) {
    _visible = visible;

    if (visible && !isExplored) {
      isExplored = true;
      return true;
    }

    return false;
  }

  bool isExplored = false;
  bool get isWalkable => type.isWalkable;
  bool get isTraversable => type.isTraversable;
  bool get isFlyable => canEnter(Motility.fly);
  bool get isExit => type.isExit;

  bool canEnter(Motility motility) => type.canEnter(motility);
  bool canEnterAny(MotilitySet motilities) => type.canEnterAny(motilities);
}
