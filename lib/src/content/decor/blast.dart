//import 'dart:math' as math;
//
//import 'package:piecemeal/piecemeal.dart';
//
//import '../dungeon/dungeon.dart';
//import '../tiles.dart';
//import 'decor.dart';
//
//class Blast extends Decor {
//  static final _tileMap = {
//    Tiles.floor: [Tiles.burntFloor, Tiles.burntFloor2],
//    Tiles.tableTopLeft: [
//      Tiles.tableTopLeft,
//      Tiles.burntFloor,
//      Tiles.burntFloor2
//    ],
//    Tiles.tableTop: [Tiles.tableTop, Tiles.burntFloor, Tiles.burntFloor2],
//    Tiles.tableTopRight: [
//      Tiles.tableTopRight,
//      Tiles.burntFloor,
//      Tiles.burntFloor2
//    ],
//    Tiles.tableSide: [Tiles.tableSide, Tiles.burntFloor, Tiles.burntFloor2],
//    Tiles.tableCenter: [Tiles.tableCenter, Tiles.burntFloor, Tiles.burntFloor2],
//    Tiles.tableBottomLeft: [
//      Tiles.tableBottomLeft,
//      Tiles.burntFloor,
//      Tiles.burntFloor2
//    ],
//    Tiles.tableBottom: [Tiles.tableBottom, Tiles.burntFloor, Tiles.burntFloor2],
//    Tiles.tableBottomRight: [
//      Tiles.tableBottomRight,
//      Tiles.burntFloor,
//      Tiles.burntFloor2
//    ],
//    Tiles.tableLegLeft: [
//      Tiles.tableLegLeft,
//      Tiles.burntFloor,
//      Tiles.burntFloor2
//    ],
//    Tiles.tableLeg: [Tiles.tableLeg, Tiles.burntFloor, Tiles.burntFloor2],
//    Tiles.tableLegRight: [
//      Tiles.tableLegRight,
//      Tiles.burntFloor,
//      Tiles.burntFloor2
//    ],
//  };
//
//  bool canPlace(Dungeon dungeon, Vec pos) {
//    return dungeon.getTileAt(pos).isWalkable;
//  }
//
//  void place(Dungeon dungeon, Vec pos) {
//    var particles = rng.range(3, 10);
//    for (var i = 0; i < particles; i++) {
//      var theta = rng.float(math.pi * 2.0);
//      var distance = rng.float(2.0, 6.0);
//      for (var r = 0.0; r < distance; r += 0.5) {
//        var here = pos +
//            Vec((math.cos(theta) * r).round(), (math.sin(theta) * r).round());
//
//        if (!dungeon.bounds.contains(here)) break;
//
//        var from = dungeon.getTileAt(here);
//        var to = _tileMap[from];
//        if (to != null) {
//          dungeon.setTileAt(here, rng.item(to));
//        } else if (!from.isWalkable) {
//          break;
//        }
//      }
//    }
//    // TODO: implement place
//  }
//}
