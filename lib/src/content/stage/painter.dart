import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';

// TODO: The way this works isn't very flexible. Come up with something better.
/// Takes generic tiles and paints them with a specific style or theme.
class Painter {
  static final base = Painter({
    Tiles.open: [Tiles.floor],
    Tiles.solid: [Tiles.rock],
    Tiles.passage: [Tiles.floor],
    Tiles.solidWet: [Tiles.water],
    Tiles.passageWet: [Tiles.bridge]
  });

  static final stoneWall = Painter({
    Tiles.open: [Tiles.floor],
    Tiles.solid: [Tiles.wall],
    Tiles.passage: [Tiles.floor],
  });

  final Map<TileType, List<TileType>> _types;

  Painter(this._types);

  TileType paint(TileType type) {
    if (_types.containsKey(type)) {
      return rng.item(_types[type]);
    }

    if (this == base) return type;

    return base.paint(type);
  }

// TODO: Decide if we want to use this.
//  static List<TileType> _colorRange(
//      TileType baseType, int count, double maxMix, Color fore, Color back) {
//    var result = [baseType];
//    for (var i = 1; i < count; i++) {
//      var glyph = baseType.appearance as Glyph;
//      var mixedFore =
//          glyph.fore.blend(fore, lerpDouble(i, 0, count, 0.0, maxMix));
//      var mixedBack =
//          glyph.back.blend(back, lerpDouble(i, 0, count, 0.0, maxMix));
//
//      var type = TileType(
//          baseType.name,
//          Glyph.fromCharCode(glyph.char, mixedFore, mixedBack),
//          baseType.motility,
//          emanation: baseType.emanation,
//          isExit: baseType.isExit,
//          onClose: baseType.onClose,
//          onOpen: baseType.onOpen);
//      result.add(type);
//    }
//
//    return result;
//  }
}