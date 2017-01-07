import 'package:malison/malison.dart';

import '../engine.dart';
import 'utils.dart';

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
  static TileType tree;
  static TileType treeAlt1;
  static TileType treeAlt2;

  static void initialize() {
    // Define the tile types.
    Tiles.floor = open("floor", gray('.'), darkGray('.'));
    Tiles.wall = solid("wall",
        lightGray(CharCode.mediumShade, Color.darkGray),
        darkGray(CharCode.mediumShade));

    Tiles.table = obstacle("table",
      brown(CharCode.greekSmallLetterPi),
      darkBrown(CharCode.greekSmallLetterPi));

    Tiles.lowWall = obstacle("low wall", gray('%', Color.darkGray), darkGray('%'));

    Tiles.openDoor = open("open door",
        brown(CharCode.whiteCircle),
        darkBrown(CharCode.whiteCircle));
    Tiles.closedDoor = solid("closed door",
        brown(CharCode.inverseWhiteCircle),
        darkBrown(CharCode.inverseWhiteCircle));
    Tiles.openDoor.closesTo = Tiles.closedDoor;
    Tiles.closedDoor.opensTo = Tiles.openDoor;

    // TODO: Allow flying monster to fly over it.
    Tiles.water = obstacle("water",
        blue(CharCode.almostEqualTo), darkBlue(CharCode.almostEqualTo));

    Tiles.stairs = exit("stairs",
        lightGray(CharCode.identicalTo), darkGray(CharCode.identicalTo));

    Tiles.grass = open("grass", lightGreen('.'), green('.'));

    Tiles.tree = solid("tree",
        green(CharCode.blackUpPointingTriangle, Color.darkGreen),
        darkGreen(CharCode.blackUpPointingTriangle));

    Tiles.treeAlt1 = solid("tree",
        green(CharCode.blackSpadeSuit, Color.darkGreen),
        darkGreen(CharCode.blackSpadeSuit));

    Tiles.treeAlt2 = solid("tree",
        green(CharCode.blackClubSuit, Color.darkGreen),
        darkGreen(CharCode.blackClubSuit));
  }
}

TileType tileType(String name, bool isPassable, bool isTransparent, appearance) {
  return new TileType(name, appearance, isPassable: isPassable, isTransparent: isTransparent);
}

/// Creates a passable, transparent tile.
TileType open(String name, Glyph lit, Glyph unlit) {
  return new TileType(name, <Glyph>[lit, unlit],
      isPassable: true, isTransparent: true, isExit: false);
}

/// Creates an impassable, opaque tile.
TileType solid(String name, Glyph lit, Glyph unlit) {
  return new TileType(name, <Glyph>[lit, unlit],
      isPassable: false, isTransparent: false, isExit: false);
}

/// Creates an impassable, transparent tile.
TileType obstacle(String name, Glyph lit, Glyph unlit) {
  return new TileType(name, <Glyph>[lit, unlit],
      isPassable: false, isTransparent: true, isExit: false);
}

/// Creates a passable, transparent exit tile.
TileType exit(String name, Glyph lit, Glyph unlit) {
  return new TileType(name, <Glyph>[lit, unlit],
      isPassable: true, isTransparent: true, isExit: true);
}
