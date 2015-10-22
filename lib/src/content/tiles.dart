library hauberk.content.tiles;

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

  static TileType grass;
  static TileType tree;
  static TileType treeAlt1;
  static TileType treeAlt2;

  static void initialize() {
    // Define the tile types.
    Tiles.floor = new TileType("floor", true, true,
        [gray('.'), darkGray('.')]);

    Tiles.wall = new TileType("wall", false, false,
        [lightGray('#', Color.darkGray), darkGray('#')]);

    Tiles.table = new TileType("table", false, true, [
      brown(CharCode.greekSmallLetterPi),
      darkBrown(CharCode.greekSmallLetterPi)
    ]);

    Tiles.lowWall = new TileType("low wall", false, true,
        [gray('%', Color.darkGray), darkGray('%')]);

    Tiles.openDoor = new TileType("open door", true, true,
        [brown("'"), darkBrown("'")]);
    Tiles.closedDoor = new TileType("closed door", false, false,
        [brown('+'), darkBrown('+')]);
    Tiles.openDoor.closesTo = Tiles.closedDoor;
    Tiles.closedDoor.opensTo = Tiles.openDoor;

    Tiles.stairs = new TileType("stairs", true, true,
        [lightGray(CharCode.identicalTo), darkGray(CharCode.identicalTo)]);

    Tiles.grass = new TileType("grass", true, true,
        [lightGreen('.'), green('.')]);

    Tiles.tree = new TileType("tree", false, false, [
      green(CharCode.blackUpPointingTriangle, Color.darkGreen),
      darkGreen(CharCode.blackUpPointingTriangle)
    ]);

    Tiles.treeAlt1 = new TileType("tree", false, false, [
      green(CharCode.blackSpadeSuit, Color.darkGreen),
      darkGreen(CharCode.blackSpadeSuit)
    ]);

    Tiles.treeAlt2 = new TileType("tree", false, false, [
      green(CharCode.blackClubSuit, Color.darkGreen),
      darkGreen(CharCode.blackClubSuit)
    ]);
  }
}
