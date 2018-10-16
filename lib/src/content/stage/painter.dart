import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

import '../tiles.dart';

/// Takes generic tiles and paints them with a specific style or theme.
class Painter {
  TileType paint(Vec pos, TileType type) {
    if (type == Tiles.filled) return Tiles.wall;
    if (type == Tiles.unfilled) return Tiles.floor;
    if (type == Tiles.aquatic) return Tiles.water;

    // TODO: Should this ever be reached? I think it is now just because of the
    // rock edge around the stage.
    return type;
  }
}
