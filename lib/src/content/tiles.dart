library content.tiles;

import '../engine.dart';
import '../ui.dart';
import 'builder.dart';

/// Builder class for defining [TileType]s.
class Tiles extends ContentBuilder {
  static TileType floor;
  static TileType wall;
  static TileType lowWall;
  static TileType openDoor;
  static TileType closedDoor;
  static TileType stairs;

  static TileType grass;
  static TileType tree;
  static TileType treeAlt1;
  static TileType treeAlt2;

  void build() {
    // Define the tile types.
    Tiles.floor = new TileType(true, true, [gray('.'), darkGray('.')]);

    Tiles.wall = new TileType(false, false,
        [new Glyph('#', Color.LIGHT_GRAY, Color.DARK_GRAY),
         new Glyph('#', Color.DARK_GRAY)]);

    Tiles.lowWall = new TileType(false, true,
        [new Glyph('%', Color.GRAY, Color.DARK_GRAY),
         new Glyph('%', Color.DARK_GRAY)]);

    Tiles.openDoor = new TileType(true, true, [brown("'"), darkBrown("'")]);
    Tiles.closedDoor = new TileType(false, false, [brown('+'), darkBrown('+')]);
    Tiles.openDoor.closesTo = Tiles.closedDoor;
    Tiles.closedDoor.opensTo = Tiles.openDoor;

    Tiles.stairs = new TileType(true, true, [
        new Glyph.fromCharCode(CharCode.TRIPLE_BAR, Color.LIGHT_GRAY),
        new Glyph.fromCharCode(CharCode.TRIPLE_BAR, Color.DARK_GRAY)]);

    Tiles.grass = new TileType(true, true, [lightGreen('.'), green('.')]);

    Tiles.tree = new TileType(false, false, [
        new Glyph.fromCharCode(CharCode.BLACK_UP_POINTING_TRIANGLE,
            Color.GREEN, Color.DARK_GREEN),
         new Glyph.fromCharCode(CharCode.BLACK_UP_POINTING_TRIANGLE,
             Color.DARK_GREEN)]);

    Tiles.treeAlt1 = new TileType(false, false, [
        new Glyph.fromCharCode(CharCode.BLACK_SPADE_SUIT,
            Color.GREEN, Color.DARK_GREEN),
        new Glyph.fromCharCode(CharCode.BLACK_SPADE_SUIT,
            Color.DARK_GREEN)]);

    Tiles.treeAlt2 = new TileType(false, false, [
        new Glyph.fromCharCode(CharCode.BLACK_CLUB_SUIT,
            Color.GREEN, Color.DARK_GREEN),
        new Glyph.fromCharCode(CharCode.BLACK_CLUB_SUIT,
            Color.DARK_GREEN)]);
  }
}
