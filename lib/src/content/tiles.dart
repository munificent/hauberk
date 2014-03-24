library content.tiles;

import '../engine.dart';
import '../ui.dart';
import 'builder.dart';

/// Builder class for defining [TileType]s.
class Tiles extends ContentBuilder {
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

  void build() {
    // Define the tile types.
    Tiles.floor = new TileType("floor", true, true,
        [gray('.'), darkGray('.')]);

    Tiles.wall = new TileType("wall", false, false, [
      new Glyph('#', Color.LIGHT_GRAY, Color.DARK_GRAY),
      new Glyph('#', Color.DARK_GRAY)
    ]);

    Tiles.table = new TileType("table", false, true, [
      new Glyph.fromCharCode(CharCode.PI, Color.BROWN),
      new Glyph.fromCharCode(CharCode.PI, Color.DARK_BROWN)
    ]);

    Tiles.lowWall = new TileType("low wall", false, true, [
      new Glyph('%', Color.GRAY, Color.DARK_GRAY),
      new Glyph('%', Color.DARK_GRAY)
    ]);

    Tiles.openDoor = new TileType("open door", true, true,
        [brown("'"), darkBrown("'")]);
    Tiles.closedDoor = new TileType("closed door", false, false,
        [brown('+'), darkBrown('+')]);
    Tiles.openDoor.closesTo = Tiles.closedDoor;
    Tiles.closedDoor.opensTo = Tiles.openDoor;

    Tiles.stairs = new TileType("stairs", true, true, [
      new Glyph.fromCharCode(CharCode.TRIPLE_BAR, Color.LIGHT_GRAY),
      new Glyph.fromCharCode(CharCode.TRIPLE_BAR, Color.DARK_GRAY)
    ]);

    Tiles.grass = new TileType("grass", true, true,
        [lightGreen('.'), green('.')]);

    Tiles.tree = new TileType("tree", false, false, [
      new Glyph.fromCharCode(CharCode.BLACK_UP_POINTING_TRIANGLE,
          Color.GREEN, Color.DARK_GREEN),
      new Glyph.fromCharCode(CharCode.BLACK_UP_POINTING_TRIANGLE,
          Color.DARK_GREEN)
    ]);

    Tiles.treeAlt1 = new TileType("tree", false, false, [
      new Glyph.fromCharCode(CharCode.BLACK_SPADE_SUIT,
          Color.GREEN, Color.DARK_GREEN),
      new Glyph.fromCharCode(CharCode.BLACK_SPADE_SUIT,
          Color.DARK_GREEN)
    ]);

    Tiles.treeAlt2 = new TileType("tree", false, false, [
      new Glyph.fromCharCode(CharCode.BLACK_CLUB_SUIT,
          Color.GREEN, Color.DARK_GREEN),
      new Glyph.fromCharCode(CharCode.BLACK_CLUB_SUIT,
          Color.DARK_GREEN)
    ]);
  }
}
