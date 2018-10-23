import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../tiles.dart';
import 'architect.dart';

// TODO: The way this works isn't very flexible. Come up with something better.
/// Takes generic tiles and paints them with a specific style or theme.
class Painter {
  static final base = Painter({
    TempTiles.open: [Tiles.floor],
    TempTiles.solid: [Tiles.rock],
    TempTiles.passage: [Tiles.floor],
    TempTiles.solidWet:
        _animated(Tiles.water, 10, 0.4, ultramarine, nearBlack),
    TempTiles.passageWet: [Tiles.bridge]
  });

  static final stoneWall = Painter({
    TempTiles.open: [Tiles.floor],
    TempTiles.solid: [Tiles.wall],
    TempTiles.passage: [Tiles.floor],
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

  // TODO: Is this something we want to keep? If so, move this to tiles.dart.
  static List<TileType> _animated(
      TileType baseType, int count, double maxMix, Color fore, Color back) {
    var glyph = baseType.appearance as Glyph;
    var glyphs = [glyph];
    for (var i = 1; i < count; i++) {
      var mixedFore =
          glyph.fore.blend(fore, lerpDouble(i, 0, count, 0.0, maxMix));
      var mixedBack =
          glyph.back.blend(back, lerpDouble(i, 0, count, 0.0, maxMix));

      glyphs.add(Glyph.fromCharCode(glyph.char, mixedFore, mixedBack));
    }

    return [
      TileType(baseType.name, glyphs, baseType.motility,
          emanation: baseType.emanation,
          isExit: baseType.isExit,
          onClose: baseType.onClose,
          onOpen: baseType.onOpen)
    ];
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
