import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';

/// Static class containing all of the [TileType]s.
class Tiles {
  static final TileType floor = _open("floor", CharCode.middleDot, slate);
  static final TileType burntFloor =
      _open("burnt floor", CharCode.greekSmallLetterPhi, steelGray);
  static final TileType burntFloor2 =
      _open("burnt floor", CharCode.greekSmallLetterEpsilon, steelGray);
  static final TileType rock =
      _solid("rock", CharCode.darkShade, gunsmoke, back: slate);
  static final TileType wall =
      _solid("wall", CharCode.mediumShade, gunsmoke, back: slate);
  static final TileType lowWall =
      _obstacle("low wall", CharCode.percent, gunsmoke);
  static final TileType openDoor =
      _open("open door", CharCode.whiteCircle, persimmon, back: garnet);
  static final TileType closedDoor = _door(
      "closed door", CharCode.inverseWhiteCircle, persimmon,
      back: garnet);

  // TODO: maleSign = barred wall

  // TODO: Different character that doesn't look like bridge?
  static final TileType stairs =
      _exit("stairs", CharCode.identicalTo, gunsmoke, back: slate);
  static final TileType bridge =
      _open("bridge", CharCode.identicalTo, persimmon, back: garnet);

  static final TileType water =
      _water("water", CharCode.almostEqualTo, cerulean, back: ultramarine);
  static final TileType steppingStone =
      _open("stepping stone", "•", gunsmoke, back: ultramarine);

  static final TileType dirt = _open("dirt", CharCode.middleDot, garnet);
  static final TileType dirt2 =
      _open("dirt2", CharCode.greekSmallLetterPhi, garnet);
  static final TileType grass = _open("grass", CharCode.lightShade, peaGreen);
  static final TileType tallGrass =
      _open("tall grass", CharCode.squareRoot, peaGreen);
  static final TileType tree = _solid(
      "tree", CharCode.blackUpPointingTriangle, peaGreen,
      back: sherwood);
  static final TileType treeAlt1 =
      _solid("tree", CharCode.blackSpadeSuit, peaGreen, back: sherwood);
  static final TileType treeAlt2 =
      _solid("tree", CharCode.blackClubSuit, peaGreen, back: sherwood);

  static final TileType tableTopLeft = _obstacle("table", "┌", persimmon);
  static final TileType tableTop = _obstacle("table", "─", persimmon);
  static final TileType tableTopRight = _obstacle("table", "┐", persimmon);
  static final TileType tableSide = _obstacle("table", "│", persimmon);
  static final TileType tableCenter = _obstacle("table", " ", persimmon);
  static final TileType tableBottomLeft = _obstacle("table", "╘", persimmon);
  static final TileType tableBottom = _obstacle("table", "═", persimmon);
  static final TileType tableBottomRight = _obstacle("table", "╛", persimmon);

  static final TileType tableLegLeft = _obstacle("table", "╞", persimmon);
  static final TileType tableLeg = _obstacle("table", "╤", persimmon);
  static final TileType tableLegRight = _obstacle("table", "╡", persimmon);

  static final TileType candle =
      _obstacle("candle", CharCode.greaterThanOrEqualTo, sandal, emanation: 6);

  static final TileType wallTorch = _solid(
      "wall torch", CharCode.lessThanOrEqualTo, gold,
      back: slate, emanation: 8);

  // TODO: Make these do something.
  static final TileType barrel =
      _obstacle("barrel", CharCode.topHalfIntegral, persimmon);
  static final TileType chest =
      _obstacle("chest", CharCode.bottomHalfIntegral, persimmon);

  static final TileType statue = _obstacle("statue", "P", ash, back: slate);

  // Make these "monsters" that can be pushed around.
  static final TileType chair = _open("chair", "π", persimmon);

  static final TileType brownJellyStain =
      _open("brown jelly stain", CharCode.middleDot, persimmon);

  static final TileType grayJellyStain =
      _open("gray jelly stain", CharCode.middleDot, steelGray);

  static final TileType greenJellyStain =
      _open("green jelly stain", CharCode.middleDot, lima);

  static final TileType redJellyStain =
      _open("red jelly stain", CharCode.middleDot, brickRed);

  static final TileType violetJellyStain =
      _open("violet jelly stain", CharCode.middleDot, violet);

  static final TileType whiteJellyStain =
      _open("white jelly stain", CharCode.middleDot, ash);

  // TODO: Make this do stuff when walked through.
  static final TileType spiderweb =
      _open("spiderweb", CharCode.divisionSign, slate);

  static void initialize() {
    // Link doors together.
    Tiles.openDoor.closesTo = Tiles.closedDoor;
    Tiles.closedDoor.opensTo = Tiles.openDoor;
  }

  /// The amount of heat required for [tile] to catch fire or 0 if the tile
  /// cannot be ignited.
  static int ignition(TileType tile) => _ignition[tile] ?? 0;

  static final _ignition = {
    openDoor: 30,
    closedDoor: 30,
    bridge: 50,
    grass: 3,
    tallGrass: 3,
    tree: 40,
    treeAlt1: 40,
    treeAlt2: 40,
    tableTopLeft: 20,
    tableTop: 20,
    tableTopRight: 20,
    tableSide: 20,
    tableCenter: 20,
    tableBottomLeft: 20,
    tableBottom: 20,
    tableBottomRight: 20,
    tableLegLeft: 20,
    tableLeg: 20,
    tableLegRight: 20,
    candle: 1,
    chair: 10,
    spiderweb: 1
  };

  /// How long [tile] burns before going out.
  static int fuel(TileType tile) => _fuel[tile] ?? 0;

  static final _fuel = {
    openDoor: 70,
    closedDoor: 70,
    bridge: 50,
    grass: 30,
    tallGrass: 50,
    tree: 100,
    treeAlt1: 100,
    treeAlt2: 100,
    tableTopLeft: 60,
    tableTop: 60,
    tableTopRight: 60,
    tableSide: 60,
    tableCenter: 60,
    tableBottomLeft: 60,
    tableBottom: 60,
    tableBottomRight: 60,
    tableLegLeft: 60,
    tableLeg: 60,
    tableLegRight: 60,
    candle: 60,
    chair: 40,
    spiderweb: 20
  };

  /// What types [tile] can turn into when it finishes burning.
  static List<TileType> burnResult(TileType tile) {
    if (_burnTypes.containsKey(tile)) return _burnTypes[tile];

    return [burntFloor, burntFloor2];
  }

  static final _burnTypes = {
    bridge: [water],
    grass: [dirt, dirt2],
    tallGrass: [dirt, dirt2],
    tree: [dirt, dirt2],
    treeAlt1: [dirt, dirt2],
    treeAlt2: [dirt, dirt2],
    candle: [tableCenter],
    spiderweb: [floor]
  };
}

Glyph _makeGlyph(Object char, Color fore, [Color back]) {
  var charCode = char is int ? char : (char as String).codeUnitAt(0);
  if (back == null) {
    back = midnight;
  } else {}

  return new Glyph.fromCharCode(charCode, fore, back);
}

/// Creates an impassable, opaque tile.
TileType _door(String name, Object char, Color fore, {Color back}) {
  return new TileType(name, _makeGlyph(char, fore, back), [Motility.door],
      isExit: false);
}

/// Creates a passable, transparent exit tile.
TileType _exit(String name, Object char, Color fore, {Color back}) {
  return new TileType(
      name, _makeGlyph(char, fore, back), [Motility.walk, Motility.fly],
      isExit: true);
}

/// Creates an impassable, transparent tile.
TileType _obstacle(String name, Object char, Color fore,
    {Color back, int emanation}) {
  return new TileType(name, _makeGlyph(char, fore, back), [Motility.fly],
      emanation: Lighting.emanationForLevel(emanation ?? 0), isExit: false);
}

/// Creates a passable, transparent tile.
TileType _open(String name, Object char, Color fore, {Color back}) {
  return new TileType(
      name, _makeGlyph(char, fore, back), [Motility.walk, Motility.fly],
      isExit: false);
}

/// Creates an impassable, opaque tile.
TileType _solid(String name, Object char, Color fore,
    {Color back, int emanation}) {
  return new TileType(name, _makeGlyph(char, fore, back), [],
      emanation: Lighting.emanationForLevel(emanation ?? 0), isExit: false);
}

TileType _water(String name, Object char, Color fore, {Color back}) {
  return new TileType(
      name, _makeGlyph(char, fore, back), [Motility.fly, Motility.swim],
      emanation: 1, isExit: false);
}
