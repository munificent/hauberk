import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/element.dart';
import 'lighting.dart';

/// Enum-like class defining ways that monsters can move over tiles.
///
/// Each [TileType] has a set of motilities that determine which kind of
/// movement is needed to enter the tile. Monsters and the hero have a set of
/// motilities that determine which ways they are able to move. In order to
/// move into a tile, the actor must have one of the tile's motilities.
class Motility extends MotilitySet {
  // TODO: Should these be in content, engine, or a mixture of both?
  static final Motility door = Motility("door");
  static final Motility fly = Motility("fly");
  static final Motility swim = Motility("swim");
  static final Motility walk = Motility("walk");

  /// Each motility object has a bit value that is used by MotilitySet to store
  /// a set of motilities efficiently.
  static int _nextBit = 1;

  final String name;

  Motility(this.name) : super._(_nextBit) {
    _nextBit <<= 1;
  }
}

class MotilitySet {
  static final doorAndFly = MotilitySet([Motility.door, Motility.fly]);
  static final doorAndWalk = MotilitySet([Motility.door, Motility.walk]);
  static final flyAndWalk = MotilitySet([Motility.fly, Motility.walk]);
  static final none = MotilitySet([]);
  static final walk = MotilitySet([Motility.walk]);

  int _bitMask = 0;

  factory MotilitySet([Iterable<Motility> iterable]) {
    var mask = 0;
    if (iterable != null) {
      for (var motility in iterable) {
        mask += motility._bitMask;
      }
    }

    return MotilitySet._(mask);
  }

  MotilitySet._(this._bitMask);

  bool operator ==(other) {
    if (other is MotilitySet) return _bitMask == other._bitMask;
    return false;
  }

  /// Creates a new MotilitySet containing all of the motilities of this and
  /// [other].
  MotilitySet operator +(MotilitySet other) =>
      MotilitySet._(_bitMask | other._bitMask);

  /// Creates a new MotilitySet containing all of the motilities of this
  /// except for the motilities in [other].
  MotilitySet operator -(MotilitySet other) =>
      MotilitySet._(_bitMask & ~other._bitMask);

  bool contains(Motility motility) => _bitMask & motility._bitMask != 0;

  bool overlaps(MotilitySet other) => _bitMask & other._bitMask != 0;
}

class TileType {
  final String name;
  final bool isExit;
  final int emanation;
  final appearance;

  bool get canClose => onClose != null;
  bool get canOpen => onOpen != null;

  final MotilitySet motilities;

  /// If the tile can be "opened", this is the function that produces an open
  /// action for it. Otherwise `null`.
  final Action Function(Vec) onClose;

  /// If the tile can be "opened", this is the function that produces an open
  /// action for it. Otherwise `null`.
  final Action Function(Vec) onOpen;

  bool get isTraversable => canEnterAny(MotilitySet.doorAndWalk);

  bool get isWalkable => canEnter(Motility.walk);

  TileType(this.name, this.appearance, MotilitySet motilities,
      {int emanation, bool isExit, this.onClose, this.onOpen})
      : isExit = isExit ?? false,
        emanation = emanation ?? 0,
        motilities = motilities;

  bool canEnter(Motility motility) => this.motilities.contains(motility);

  bool canEnterAny(MotilitySet motilities) =>
      this.motilities.overlaps(motilities);
}

class Tile {
  /// The tile's basic type.
  ///
  /// If you change this during the game, make sure to call
  /// [Stage.tileOpacityChanged] if the tile's opacity changed.
  TileType type;

  /// Whether some other opaque tile is blocking the hero's view of this tile.
  ///
  /// This gets updated by [Fov] as the hero moves around.
  bool _isOccluded = false;

  bool get isOccluded => _isOccluded;

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

  /// The amount of light the tile produces.
  ///
  /// Includes "native" emanation from the tile itself along with light that
  /// has been applied to it.
  int get emanation =>
      (type.emanation + _appliedEmanation).clamp(0, Lighting.floorMax);

  /// The extra emanation applied to this tile independent of its type from
  /// things like light spells.
  int _appliedEmanation = 0;

  /// If you call this, make sure to call [Stage.tileEmanationChanged()].
  void addEmanation(int offset) {
    _appliedEmanation = (_appliedEmanation + offset).clamp(0, Lighting.floorMax);
  }

  bool _isExplored = false;

  bool get isExplored => _isExplored;

  /// Marks this tile as explored if the hero can see it and hasn't previously
  /// explored it.
  ///
  /// This should not be called directly. Instead, call [Stage.explore()].
  ///
  /// Returns true if this tile was explored just now.
  bool updateExplored({bool force}) {
    force ??= false;
    if ((force || isVisible) && !_isExplored) {
      _isExplored = true;
      return true;
    }

    return false;
  }

  void updateOcclusion(bool isOccluded) {
    _isOccluded = isOccluded;
  }

  /// The element of the substance occupying this file: fire, water, poisonous
  /// gas, etc.
  Element element = Element.none;

  /// How much of [_element] is occupying the tile.
  int substance = 0;

  bool get isWalkable => type.isWalkable;

  bool get isTraversable => type.isTraversable;

  bool get isFlyable => canEnter(Motility.fly);

  bool get isClosedDoor => type.motilities == Motility.door;

  bool get isExit => type.isExit;

  bool canEnter(Motility motility) => type.canEnter(motility);

  bool canEnterAny(MotilitySet motilities) => type.canEnterAny(motilities);
}
