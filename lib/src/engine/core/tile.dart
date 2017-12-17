import 'lighting.dart';

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
  /// The tile's basic type.
  ///
  /// If you change this during the game, make sure to call
  /// [Stage.dirtyTileLight] and [Stage.dirtyVisibility] if the tile's opacity
  /// changed.
  TileType type;

  /// Whether some other opaque tile is blocking the hero's view of this tile.
  ///
  /// This gets updated by [Fov] as the hero moves around.
  bool isOccluded = false;

  /// Whether the tile can be seen through or blocks the hero's view beyond it.
  ///
  /// We assume any tile that an actor can fly over is also "open" enough to
  /// be seen through. We don't use [isWalkable] because things like water
  /// cannot be walked over but can be seen through.
  bool get blocksView => !isFlyable;

  /// Whether the hero can currently see the tile.
  ///
  /// To be visible, a tile must not be occluded or in the dark.
  bool get isVisible => illumination > 0 && !isOccluded;

  /// The total amount of light being cast onto this tile from various sources.
  ///
  /// This is a combination of the tile's [emanation], the propagated emanation
  /// from nearby tiles, light from actors, etc.
  int illumination = 0;

  /// The amount of light the tile itself produces.
  ///
  /// If you set this, make sure to call `Stage.dirtyTileVisibility()`.
  // TODO: Should any of this come from the type?
  int _emanation = 0;
  int get emanation => _emanation;
  set emanation(int value) {
    _emanation = value.clamp(0, Lighting.max);
  }

  bool _isExplored = false;
  bool get isExplored => _isExplored;

  /// Marks this tile as explored if the hero can see it and hasn't previously
  /// explored it.
  ///
  /// Returns 1 if this tile was explored just now or 0 otherwise.
  int updateExplored() {
    if (isVisible && !_isExplored) {
      _isExplored = true;
      return 1;
    }

    return 0;
  }

  bool get isWalkable => type.isWalkable;
  bool get isTraversable => type.isTraversable;
  bool get isFlyable => canEnter(Motility.fly);
  bool get isExit => type.isExit;

  bool canEnter(Motility motility) => type.canEnter(motility);
  bool canEnterAny(MotilitySet motilities) => type.canEnterAny(motilities);
}
