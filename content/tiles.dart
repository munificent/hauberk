library content.tiles;

import '../engine.dart';
import '../ui.dart';
import 'builder.dart';

/// Builder class for defining [TileType]s.
class TileBuilder extends ContentBuilder {
  TileBuilder();

  void build() {
    // Define the tile types.
    Tiles.floor = new TileType(true, true, [gray('.'), darkGray('.')]);

    Tiles.wall = new TileType(false, false,
        [new Glyph('#', Color.WHITE, Color.DARK_GRAY),
         new Glyph('#', Color.GRAY)]);

    Tiles.lowWall = new TileType(false, true,
        [new Glyph('%', Color.GRAY, Color.DARK_GRAY),
         new Glyph('%', Color.DARK_GRAY)]);

    Tiles.openDoor = new TileType(true, true, [brown("'"), darkBrown("'")]);
    Tiles.closedDoor = new TileType(false, false, [brown('+'), darkBrown('+')]);

    Tiles.openDoor.closesTo = Tiles.closedDoor;
    Tiles.closedDoor.opensTo = Tiles.openDoor;
  }
}

class Tiles {
  static TileType floor;
  static TileType wall;
  static TileType lowWall;
  static TileType openDoor;
  static TileType closedDoor;
}
