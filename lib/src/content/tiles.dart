import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';

// TODO: Move to hues.dart?
const _unlitBlend = const Color(0x00, 0x01, 0x33);
const _defaultBackUnlit = const Color(0x7, 0x6, 0x12);

/// Static class containing all of the [TileType]s.
class Tiles {
  static TileType floor;
  static TileType wall;
  static TileType lowWall;
  static TileType table;
  static TileType openDoor;
  static TileType closedDoor;
  static TileType stairs;
  static TileType water;

  static TileType grass;
  static TileType tallGrass;
  static TileType tree;
  static TileType treeAlt1;
  static TileType treeAlt2;

  static void initialize() {
    // Define the tile types.
    Tiles.floor = _open("floor", CharCode.middleDot, slate);
    Tiles.wall = _solid("wall", CharCode.mediumShade, gunsmoke, slate);

    Tiles.table = _obstacle("table", CharCode.greekSmallLetterPi, persimmon);

    Tiles.lowWall = _obstacle("low wall", CharCode.percent, gunsmoke);

    Tiles.openDoor =
        _open("open door", CharCode.whiteCircle, persimmon, garnet);
    Tiles.closedDoor =
        _solid("closed door", CharCode.inverseWhiteCircle, persimmon, garnet);
    Tiles.openDoor.closesTo = Tiles.closedDoor;
    Tiles.closedDoor.opensTo = Tiles.openDoor;

    // TODO: Allow flying monster to fly over it.
    Tiles.water =
        _obstacle("water", CharCode.almostEqualTo, cerulean, ultramarine);

    Tiles.stairs = _exit("stairs", CharCode.identicalTo, slate);

    Tiles.grass = _open("grass", CharCode.lightShade, peaGreen);

    Tiles.tallGrass = _open("tall grass", CharCode.squareRoot, peaGreen);

    Tiles.tree = _solid(
        "tree", CharCode.blackUpPointingTriangle, peaGreen, sherwood);
    Tiles.treeAlt1 =
        _solid("tree", CharCode.blackSpadeSuit, peaGreen, sherwood);
    Tiles.treeAlt2 =
        _solid("tree", CharCode.blackClubSuit, peaGreen, sherwood);
  }
}

TileType tileType(
    String name, bool isPassable, bool isTransparent, appearance) {
  return new TileType(name, appearance,
      isPassable: isPassable, isTransparent: isTransparent);
}

List<Glyph> _makeGlyphs(int charCode, Color fore, [Color back]) {
  Color unlitBack;
  if (back == null) {
    back = midnight;
    unlitBack = _defaultBackUnlit;
  } else {
    unlitBack = back.blend(_unlitBlend, 50);
  }

  var lit = new Glyph.fromCharCode(charCode, fore, back);
  var unlit =
      new Glyph.fromCharCode(charCode, fore.blend(_unlitBlend, 50), unlitBack);

  return [lit, unlit];
}

/// Creates a passable, transparent tile.
TileType _open(String name, int charCode, Color fore, [Color back]) {
  return new TileType(name, _makeGlyphs(charCode, fore, back),
      isPassable: true, isTransparent: true, isExit: false);
}

/// Creates an impassable, opaque tile.
TileType _solid(String name, int charCode, Color fore, [Color back]) {
  return new TileType(name, _makeGlyphs(charCode, fore, back),
      isPassable: false, isTransparent: false, isExit: false);
}

/// Creates an impassable, transparent tile.
TileType _obstacle(String name, int charCode, Color fore, [Color back]) {
  return new TileType(name, _makeGlyphs(charCode, fore, back),
      isPassable: false, isTransparent: true, isExit: false);
}

/// Creates a passable, transparent exit tile.
TileType _exit(String name, int charCode, Color fore, [Color back]) {
  return new TileType(name, _makeGlyphs(charCode, fore, back),
      isPassable: true, isTransparent: true, isExit: true);
}
