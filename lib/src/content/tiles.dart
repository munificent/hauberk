import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';

/// Static class containing all of the [TileType]s.
class Tiles {
  static TileType floor = _open("floor", CharCode.middleDot, slate);
  static TileType rock = _solid("rock", CharCode.darkShade, gunsmoke, slate);
  static TileType wall = _solid("wall", CharCode.mediumShade, gunsmoke, slate);
  static TileType lowWall = _obstacle("low wall", CharCode.percent, gunsmoke);
  static TileType openDoor =
      _open("open door", CharCode.whiteCircle, persimmon, garnet);
  static TileType closedDoor =
      _door("closed door", CharCode.inverseWhiteCircle, persimmon, garnet);
  // TODO: Different character that doesn't look like bridge?
  static TileType stairs =
      _exit("stairs", CharCode.identicalTo, gunsmoke, slate);
  static TileType bridge =
      _open("bridge", CharCode.identicalTo, persimmon, garnet);

  // TODO: Allow flying monster to fly over it.
  static TileType water =
      _water("water", CharCode.almostEqualTo, cerulean, ultramarine);

  static TileType grass = _open("grass", CharCode.lightShade, peaGreen);
  static TileType tallGrass =
      _open("tall grass", CharCode.squareRoot, peaGreen);
  static TileType tree =
      _solid("tree", CharCode.blackUpPointingTriangle, peaGreen, sherwood);
  static TileType treeAlt1 =
      _solid("tree", CharCode.blackSpadeSuit, peaGreen, sherwood);
  static TileType treeAlt2 =
      _solid("tree", CharCode.blackClubSuit, peaGreen, sherwood);

  static final TileType tableTopLeft = _obstacle("table", "┌", persimmon);
  static final TileType tableTop = _obstacle("table", "─", persimmon);
  static final TileType tableTopRight = _obstacle("table", "┐", persimmon);
  static final TileType tableLeft = _obstacle("table", "│", persimmon);
  static final TileType tableCenter = _obstacle("table", " ", persimmon);
  static final TileType tableRight = _obstacle("table", "│", persimmon);
  static final TileType tableBottomLeft = _obstacle("table", "╘", persimmon);
  static final TileType tableBottom = _obstacle("table", "═", persimmon);
  static final TileType tableBottomRight = _obstacle("table", "╛", persimmon);

  static final TileType tableLegLeft = _obstacle("table", "╞", persimmon);
  static final TileType tableLeg = _obstacle("table", "╤", persimmon);
  static final TileType tableLegRight = _obstacle("table", "╡", persimmon);

  // Make these "monsters" that can be pushed around.
  static final TileType chair = _open("chair", "π", persimmon);

  static TileType brownJellyStain =
      _open("brown jelly stain", CharCode.middleDot, persimmon);

  static TileType grayJellyStain =
      _open("gray jelly stain", CharCode.middleDot, steelGray);

  static TileType greenJellyStain =
      _open("green jelly stain", CharCode.middleDot, lima);

  static TileType redJellyStain =
      _open("red jelly stain", CharCode.middleDot, brickRed);

  static TileType violetJellyStain =
      _open("violet jelly stain", CharCode.middleDot, violet);

  static TileType whiteJellyStain =
      _open("white jelly stain", CharCode.middleDot, ash);

  // TODO: Make this do stuff when walked through.
  static TileType spiderweb = _open("spiderweb", CharCode.divisionSign, slate);

  static void initialize() {
    // Link doors together.
    Tiles.openDoor.closesTo = Tiles.closedDoor;
    Tiles.closedDoor.opensTo = Tiles.openDoor;
  }
}

Glyph _makeGlyph(Object char, Color fore, [Color back]) {
  var charCode = char is int ? char : (char as String).codeUnitAt(0);
  if (back == null) {
    back = midnight;
  } else {}

  return new Glyph.fromCharCode(charCode, fore, back);
}

/// Creates an impassable, opaque tile.
TileType _door(String name, Object char, Color fore, [Color back]) {
  return new TileType(name, _makeGlyph(char, fore, back), [Motility.door],
      isExit: false);
}

/// Creates a passable, transparent exit tile.
TileType _exit(String name, Object char, Color fore, [Color back]) {
  return new TileType(
      name, _makeGlyph(char, fore, back), [Motility.walk, Motility.fly],
      isExit: true);
}

/// Creates an impassable, transparent tile.
TileType _obstacle(String name, Object char, Color fore, [Color back]) {
  return new TileType(name, _makeGlyph(char, fore, back), [Motility.fly],
      isExit: false);
}

/// Creates a passable, transparent tile.
TileType _open(String name, Object char, Color fore, [Color back]) {
  return new TileType(
      name, _makeGlyph(char, fore, back), [Motility.walk, Motility.fly],
      isExit: false);
}

/// Creates an impassable, opaque tile.
TileType _solid(String name, Object char, Color fore, [Color back]) {
  return new TileType(name, _makeGlyph(char, fore, back), [], isExit: false);
}

TileType _water(String name, Object char, Color fore, [Color back]) {
  return new TileType(
      name, _makeGlyph(char, fore, back), [Motility.fly, Motility.swim],
      isExit: false);
}
