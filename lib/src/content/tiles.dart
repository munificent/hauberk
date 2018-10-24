import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'action/tile.dart';

// Note: Not using lambdas for these because that prevents [Tiles.openDoor] and
// [Tiles.closedDoor] from having their types inferred.
Action _closeDoor(Vec pos) => CloseDoorAction(pos, Tiles.closedDoor);

Action _openDoor(Vec pos) => OpenDoorAction(pos, Tiles.openDoor);

/// Static class containing all of the [TileType]s.
class Tiles {
  static final floor = tile("floor", "·", slate).open();
  static final burntFloor = tile("burnt floor", "φ", steelGray).open();
  static final burntFloor2 = tile("burnt floor", "ε", steelGray).open();
  static final rock = tile("rock", "▓", gunsmoke, slate).solid();
  static final wall = tile("wall", "▒", gunsmoke, slate).solid();
  static final lowWall = tile("low wall", "%", gunsmoke).obstacle();
  static final openDoor =
      tile("open door", "○", persimmon, garnet).onClose(_closeDoor).open();
  static final closedDoor =
      tile("closed door", "◙", persimmon, garnet).onOpen(_openDoor).door();

//  TODO: maleSign = open square door
//  TODO: femaleSign = closed square door
//  TODO: eighthNote = barred wall

  // TODO: Different character that doesn't look like bridge?
  static final stairs = tile("stairs", "≡", gunsmoke, slate).exit().open();
  static final bridge = tile("bridge", "≡", persimmon, garnet).open();

  // TODO: Stop glowing when stepped on?
  static final glowingMoss =
      Tiles.tile("moss", "░", seaGreen).emanate(6).open();

  static final water = tile("water", "≈", cerulean, ultramarine)
      .animate(10, 0.4, ultramarine, nearBlack)
      .water();
  static final steppingStone =
      tile("stepping stone", "•", gunsmoke, ultramarine).open();

  static final dirt = tile("dirt", "·", garnet).open();
  static final dirt2 = tile("dirt2", "φ", garnet).open();
  static final grass = tile("grass", "░", peaGreen).open();
  static final tallGrass = tile("tall grass", "√", peaGreen).open();
  static final tree = tile("tree", "▲", peaGreen, sherwood).solid();
  static final treeAlt1 = tile("tree", "♠", peaGreen, sherwood).solid();
  static final treeAlt2 = tile("tree", "♣", peaGreen, sherwood).solid();

  static final tableTopLeft = tile("table", "┌", persimmon).obstacle();
  static final tableTop = tile("table", "─", persimmon).obstacle();
  static final tableTopRight = tile("table", "┐", persimmon).obstacle();
  static final tableSide = tile("table", "│", persimmon).obstacle();
  static final tableCenter = tile("table", " ", persimmon).obstacle();
  static final tableBottomLeft = tile("table", "╘", persimmon).obstacle();
  static final tableBottom = tile("table", "═", persimmon).obstacle();
  static final tableBottomRight = tile("table", "╛", persimmon).obstacle();

  static final tableLegLeft = tile("table", "╞", persimmon).obstacle();
  static final tableLeg = tile("table", "╤", persimmon).obstacle();
  static final tableLegRight = tile("table", "╡", persimmon).obstacle();

  static final candle = tile("candle", "≥", sandal).emanate(6).obstacle();

  static final wallTorch =
      tile("wall torch", "≤", gold, slate).emanate(8).solid();

  // TODO: Make these do something.
  static final openChest = tile("open chest", "⌠", persimmon).obstacle();
  static final closedChest = tile("closed chest", "⌡", persimmon)
      .onOpen((pos) => OpenChestAction(pos))
      .obstacle();
  static final closedBarrel = tile("closed barrel", "°", persimmon)
      .onOpen((pos) => OpenBarrelAction(pos))
      .obstacle();
  static final openBarrel = tile("open barrel", "∙", persimmon).obstacle();

  static final statue = tile("statue", "P", ash, slate).obstacle();

  // Make these "monsters" that can be pushed around.
  static final chair = tile("chair", "π", persimmon).open();

  static final brownJellyStain =
      tile("brown jelly stain", "·", persimmon).open();

  static final grayJellyStain = tile("gray jelly stain", "·", steelGray).open();

  static final greenJellyStain = tile("green jelly stain", "·", lima).open();

  static final redJellyStain = tile("red jelly stain", "·", brickRed).open();

  static final violetJellyStain =
      tile("violet jelly stain", "·", violet).open();

  static final whiteJellyStain = tile("white jelly stain", "·", ash).open();

  // TODO: Make this do stuff when walked through.
  static final spiderweb = tile("spiderweb", "÷", slate).open();

  static _TileBuilder tile(String name, Object char, Color fore,
          [Color back]) =>
      _TileBuilder(name, char, fore, back);

  /// The amount of heat required for [tile] to catch fire or 0 if the tile
  /// cannot be ignited.
  static int ignition(TileType tile) => _ignition[tile] ?? 0;

  static final _ignition = {
    openDoor: 30,
    closedDoor: 30,
    bridge: 50,
    glowingMoss: 10,
    grass: 3,
    tallGrass: 3,
    tree: 40,
    treeAlt1: 40,
    treeAlt2: 40,
    tableTopLeft: 20,
    tableTop: 20,
    tableTopRight: 20,
    tableSide: 20,
    tableCenter: 20,
    tableBottomLeft: 20,
    tableBottom: 20,
    tableBottomRight: 20,
    tableLegLeft: 20,
    tableLeg: 20,
    tableLegRight: 20,
    openChest: 40,
    closedChest: 80,
    openBarrel: 15,
    closedBarrel: 40,
    candle: 1,
    chair: 10,
    spiderweb: 1
  };

  /// How long [tile] burns before going out.
  static int fuel(TileType tile) => _fuel[tile] ?? 0;

  static final _fuel = {
    openDoor: 70,
    closedDoor: 70,
    bridge: 50,
    glowingMoss: 20,
    grass: 30,
    tallGrass: 50,
    tree: 100,
    treeAlt1: 100,
    treeAlt2: 100,
    tableTopLeft: 60,
    tableTop: 60,
    tableTopRight: 60,
    tableSide: 60,
    tableCenter: 60,
    tableBottomLeft: 60,
    tableBottom: 60,
    tableBottomRight: 60,
    tableLegLeft: 60,
    tableLeg: 60,
    tableLegRight: 60,
    openChest: 70,
    closedChest: 80,
    openBarrel: 30,
    closedBarrel: 40,
    candle: 60,
    chair: 40,
    spiderweb: 20
  };

  /// What types [tile] can turn into when it finishes burning.
  static List<TileType> burnResult(TileType tile) {
    if (_burnTypes.containsKey(tile)) return _burnTypes[tile];

    return [burntFloor, burntFloor2];
  }

  static final _burnTypes = {
    bridge: [water],
    grass: [dirt, dirt2],
    tallGrass: [dirt, dirt2],
    tree: [dirt, dirt2],
    treeAlt1: [dirt, dirt2],
    treeAlt2: [dirt, dirt2],
    candle: [tableCenter],
    spiderweb: [floor]
  };
}

class _TileBuilder {
  final String name;
  final List<Glyph> glyphs;

  Action Function(Vec) _onClose;
  Action Function(Vec) _onOpen;
  bool _isExit = false;
  int _emanationLevel = 0;

  factory _TileBuilder(String name, Object char, Color fore, [Color back]) {
    back ??= midnight;
    var charCode = char is int ? char : (char as String).codeUnitAt(0);

    return _TileBuilder._(name, Glyph.fromCharCode(charCode, fore, back));
  }

  _TileBuilder._(this.name, Glyph glyph) : glyphs = [glyph];

  _TileBuilder animate(int count, double maxMix, Color fore, Color back) {
    var glyph = glyphs.first;
    for (var i = 1; i < count; i++) {
      var mixedFore =
          glyph.fore.blend(fore, lerpDouble(i, 0, count, 0.0, maxMix));
      var mixedBack =
          glyph.back.blend(back, lerpDouble(i, 0, count, 0.0, maxMix));

      glyphs.add(Glyph.fromCharCode(glyph.char, mixedFore, mixedBack));
    }

    return this;
  }

  _TileBuilder emanate(int level) {
    _emanationLevel = level;
    return this;
  }

  _TileBuilder exit() {
    _isExit = true;
    return this;
  }

  _TileBuilder onClose(Action Function(Vec) onClose) {
    _onClose = onClose;
    return this;
  }

  _TileBuilder onOpen(Action Function(Vec) onOpen) {
    _onOpen = onOpen;
    return this;
  }

  TileType door() => _motility(Motility.door);

  TileType obstacle() => _motility(Motility.fly);

  TileType open() => _motility(Motility.flyAndWalk);

  TileType solid() => _motility(Motility.none);

  TileType water() => _motility(Motility.fly | Motility.swim);

  TileType _motility(Motility motility) {
    return TileType(name, glyphs.length == 1 ? glyphs.first : glyphs, motility,
        emanation: Lighting.emanationForLevel(_emanationLevel),
        isExit: _isExit,
        onClose: _onClose,
        onOpen: _onOpen);
  }
}
