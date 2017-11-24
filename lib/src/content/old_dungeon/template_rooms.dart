import 'package:piecemeal/piecemeal.dart';

import '../tiles.dart';
import 'dungeon.dart';
import 'rooms.dart';

class TemplateRoom extends RoomType {
  static void initialize() {
    for (var template in _templates) {
      var lines =
          template.template.split("\n").map((line) => line.trim()).toList();
      lines.removeLast();
      RoomType.add(new TemplateRoom(lines), template.rarity * 6);

      // Automatically generate all mirrors and rotations of templates too.
      // Because of this, we scale the rarity by six to cancel out the extra
      // frequency.

      // Flip it horizontally.
      RoomType.add(
          new TemplateRoom(lines
              .map((line) => new String.fromCharCodes(line.codeUnits.reversed))
              .toList()),
          template.rarity * 6);

      // Flip it vertically.
      RoomType.add(
          new TemplateRoom(lines.reversed.toList()), template.rarity * 6);

      // Flip it both ways.
      RoomType.add(
          new TemplateRoom(lines.reversed
              .map((line) => new String.fromCharCodes(line.codeUnits.reversed))
              .toList()),
          template.rarity * 6);

      // Rotate it left.
      var rotated = <String>[];
      for (var x = 0; x < lines[0].length; x++) {
        var codes = <int>[];
        for (var y = 0; y < lines.length; y++) {
          codes.add(lines[y].codeUnitAt(x));
        }
        rotated.add(new String.fromCharCodes(codes));
      }
      RoomType.add(new TemplateRoom(rotated), template.rarity * 6);

      // Rotate it right.
      RoomType.add(
          new TemplateRoom(rotated.reversed
              .map((line) => new String.fromCharCodes(line.codeUnits.reversed))
              .toList()),
          template.rarity * 6);
    }
  }

  int get width => lines[0].length - 2;
  int get height => lines.length - 2;

  final List<String> lines;

  TemplateRoom(this.lines);

  void place(OldDungeon dungeon, Rect room) {
    // Render the tiles.
    var doorChoices = <Vec>[];

    for (var y = 0; y < height; y++) {
      var line = lines[y + 1];
      for (var x = 0; x < width; x++) {
        var pos = room.pos.offset(x, y);

        var tileType = _templateTiles[line[x + 1]];
        if (tileType != null) {
          dungeon.setTile(pos, tileType);
        } else {
          switch (line[x + 1]) {
            case '?':
              // The template can have multiple "?" and one of them will be
              // randomly turned into a door and the others walls.
              doorChoices.add(pos);
              break;
          }
        }
      }
    }

    // Place the random door.
    if (doorChoices.isNotEmpty) {
      var door = rng.range(doorChoices.length);
      for (var i = 0; i < doorChoices.length; i++) {
        dungeon.setTile(
            doorChoices[i], i == door ? Tiles.closedDoor : Tiles.wall);
      }
    }

    // Handle the treasure and monster tiles. Do this after the tile ones so
    // that group monsters don't spawn in tiles that later get filled.
    for (var y = 0; y < height; y++) {
      var line = lines[y + 1];
      for (var x = 0; x < width; x++) {
        var pos = room.pos.offset(x, y);
        switch (line[x + 1]) {
          case '1':
            dungeon.tryPlaceItem(pos, dungeon.depth);
            break;
          case '2':
            dungeon.tryPlaceItem(pos, dungeon.depth + 4);
            break;
          case '3':
            dungeon.tryPlaceItem(pos, dungeon.depth + 8);
            break;
          case '4':
            dungeon.tryPlaceItem(pos, dungeon.depth + 16);
            break;
          case '5':
            dungeon.tryPlaceItem(pos, dungeon.depth + 32);
            break;

          case 'a':
            dungeon.trySpawn(pos, dungeon.depth);
            break;
          case 'b':
            dungeon.trySpawn(pos, dungeon.depth + 4);
            break;
          case 'c':
            dungeon.trySpawn(pos, dungeon.depth + 8);
            break;
          case 'd':
            dungeon.trySpawn(pos, dungeon.depth + 16);
            break;
          case 'e':
            dungeon.trySpawn(pos, dungeon.depth + 32);
            break;

          case 'A':
            dungeon.tryPlaceItem(pos, dungeon.depth);
            dungeon.trySpawn(pos, dungeon.depth);
            break;
          case 'B':
            dungeon.tryPlaceItem(pos, dungeon.depth + 4);
            dungeon.trySpawn(pos, dungeon.depth + 4);
            break;
          case 'C':
            dungeon.tryPlaceItem(pos, dungeon.depth + 8);
            dungeon.trySpawn(pos, dungeon.depth + 8);
            break;
          case 'D':
            dungeon.tryPlaceItem(pos, dungeon.depth + 16);
            dungeon.trySpawn(pos, dungeon.depth + 16);
            break;
          case 'E':
            dungeon.tryPlaceItem(pos, dungeon.depth + 32);
            dungeon.trySpawn(pos, dungeon.depth + 32);
            break;
        }
      }
    }

    // Look for `+` along the outer rim. Those are the connectors.
    for (var x = 0; x < lines[0].length; x++) {
      if (lines[0][x] == '+') {
        dungeon.addConnector(room.left + x, room.top - 1);
      }

      if (lines[lines.length - 1][x] == '+') {
        dungeon.addConnector(room.left + x, room.bottom);
      }
    }

    for (var y = 0; y < lines.length; y++) {
      if (lines[y][0] == '+') {
        dungeon.addConnector(room.left - 1, room.top + y);
      }

      if (lines[y][lines[y].length - 1] == '+') {
        dungeon.addConnector(room.right, room.top + y);
      }
    }
  }
}

final _templateTiles = {
  '.': Tiles.floor,
  '%': Tiles.lowWall,
  '+': Tiles.closedDoor,
  '#': Tiles.wall,
  '~': Tiles.water
};

class _RoomTemplate {
  final String name;
  final int rarity;
  final String template;

  _RoomTemplate(this.name, this.rarity, this.template);
}

final _templates = [
  new _RoomTemplate("Tiny treasure nook", 20, r"""
      ##+#+#+##
      #.......#
      #.##?##.#
      +.?1B1?.+
      #.##?##.#
      #.......#
      ##+#+#+##
      """),
  new _RoomTemplate("Moat", 30, r"""
      ###+#+#+###
      ##.......##
      #.........#
      #~~~~a~~~~#
      #.........#
      ##.......##
      ###+#+#+###
      """),
  new _RoomTemplate("Snake", 100, r"""
      ###+#+#+###
      #1..a.a..1#
      #.#######.#
      +.+.AB11#.+
      #.#######.#
      +.#CBA..+.+
      #.#.#####.#
      +.#..222#.+
      #.#######.#
      #1..a.a..1#
      ###+#+#+###
      """),
  new _RoomTemplate("Castle", 1000, r"""
      #######################
      #.....................#
      #.....................#
      #..#####.......#####..#
      #..#.1.#.......#.2.#..#
      #..#11.#########.22#..#
      #..#...+..bbb..+...#..#
      #..###+#########+###..#
      #....#a#...d...#.#....#
      #....#a#.#####.#c#....#
      #....+a#..d..#.#c#....#
      #....#######.#d#c#....#
      #....#.e.e...#.#.#....#
      #..###+#######.#+###..#
      #..#...+.+...#.+...#..#
      #..#44.####+####.33#..#
      #..#.4.#.......#.3.#..#
      #..#####..555..#####..#
      #....~~~.......~~~....#
      #.....~~~~~~~~~~~.....#
      #......~~~~~~~~~......#
      #.....................#
      #.....................#
      #.....................#
      #.....................#
      ###+++++++++++++++++###
      """)
];
