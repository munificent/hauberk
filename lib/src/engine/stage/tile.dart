import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/element.dart';
import 'lighting.dart';

/// Bitmask-like class defining ways that actors can move over tiles.
///
/// Each [TileType] has a set of motilities that determine which kind of
/// movement is needed to enter the tile. Monsters and the hero have a set of
/// motilities that determine which ways they are able to move. In order to
/// move into a tile, the actor must have one of the tile's motilities.
class Motility {
  static final none = Motility._(0);

  // TODO: Should these be in content, engine, or a mixture of both?
  static final door = Motility._(1);
  static final fly = Motility._(2);
  static final swim = Motility._(4);
  static final walk = Motility._(8);

  static final doorAndFly = Motility.door | Motility.fly;
  static final doorAndWalk = Motility.door | Motility.walk;
  static final flyAndWalk = Motility.fly | Motility.walk;
  static final all = door | fly | swim | walk;

  int _bitMask = 0;

  Motility._(this._bitMask);

  bool operator ==(other) {
    if (other is Motility) return _bitMask == other._bitMask;
    return false;
  }

  /// Creates a new MotilitySet containing all of the motilities of this and
  /// [other].
  Motility operator |(Motility other) => Motility._(_bitMask | other._bitMask);

  /// Creates a new MotilitySet containing all of the motilities of this
  /// except for the motilities in [other].
  Motility operator -(Motility other) => Motility._(_bitMask & ~other._bitMask);

  bool overlaps(Motility other) => _bitMask & other._bitMask != 0;

  String toString() => _bitMask.toString();
}

/// Enum-like class for tiles that transport the hero: dungeon entrance, exit,
/// shops, etc.
class TilePortal {
  final String name;

  const TilePortal(this.name);

  String toString() => name;
}

class TileType {
  final String name;

  /// Where the tile takes the hero, or `null` if it's a regular tile.
  final TilePortal portal;

  final int emanation;
  final appearance;

  bool get canClose => onClose != null;

  bool get canOpen => onOpen != null;

  final Motility motility;

  /// If the tile can be "opened", this is the function that produces an open
  /// action for it. Otherwise `null`.
  final Action Function(Vec) onClose;

  /// If the tile can be "opened", this is the function that produces an open
  /// action for it. Otherwise `null`.
  final Action Function(Vec) onOpen;

  bool get isTraversable => canEnter(Motility.doorAndWalk);

  bool get isWalkable => canEnter(Motility.walk);

  TileType(this.name, this.appearance, Motility motility,
      {int emanation, this.portal, this.onClose, this.onOpen})
      : emanation = emanation ?? 0,
        motility = motility;

  /// Whether an actor with [motility] is able to enter this tile.
  bool canEnter(Motility motility) => this.motility.overlaps(motility);
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

  /// How much visibility is reduced by distance fall-off.
  int _fallOff = 0;

  /// Whether the tile can be seen through or blocks the hero's view beyond it.
  ///
  /// We assume any tile that an actor can fly over is also "open" enough to
  /// be seen through. We don't use [isWalkable] because things like water
  /// cannot be walked over but can be seen through.
  bool get blocksView => !isFlyable;

  /// Whether the hero can currently see the tile.
  ///
  /// To be visible, a tile must not be occluded, in the dark, or too far away.
  bool get isVisible => !isOccluded && visibility > 0;

  /// How visible the tile is to the player.
  ///
  /// If zero or less, the player can't see it because it's too dark or far
  /// away.
  int get visibility => illumination - _fallOff;

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
    _appliedEmanation =
        (_appliedEmanation + offset).clamp(0, Lighting.floorMax);
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

  void updateVisibility(bool isOccluded, int fallOff) {
    _isOccluded = isOccluded;
    _fallOff = fallOff;
  }

  /// The element of the substance occupying this file: fire, water, poisonous
  /// gas, etc.
  Element element = Element.none;

  /// How much of [_element] is occupying the tile.
  int substance = 0;

  bool get isWalkable => type.isWalkable;

  bool get isTraversable => type.isTraversable;

  bool get isFlyable => canEnter(Motility.fly);

  bool get isClosedDoor => type.motility == Motility.door;

  TilePortal get portal => type.portal;

  bool canEnter(Motility motility) => type.canEnter(motility);
}
