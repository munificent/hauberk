library hauberk.ui.effect;

import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';

typedef void DrawGlyph(int x, int y, Glyph glyph);

abstract class Effect {
  bool update(Game game);
  void render(Game game, DrawGlyph drawGlyph);
}

/// Creates a list of [Glyph]s for each combination of [chars] and [colors].
List<Glyph> _glyphs(String chars, List<Color> colors) {
  var results = [];
  for (var char in chars.codeUnits) {
    for (var color in colors) {
      results.add(new Glyph.fromCharCode(char, color));
    }
  }

  return results;
}

final _noneSequence = [
  _glyphs("•", [Color.LIGHT_BROWN]),
  _glyphs("•", [Color.LIGHT_BROWN]),
  _glyphs("•", [Color.BROWN])
];

final _airSequence = [
  _glyphs("Oo", [Color.WHITE, Color.LIGHT_AQUA]),
  _glyphs(".", [Color.LIGHT_AQUA]),
  _glyphs(".", [Color.LIGHT_GRAY])
];

final _earthSequence = [
  _glyphs("*%", [Color.LIGHT_BROWN, Color.GOLD]),
  _glyphs("*%", [Color.BROWN, Color.DARK_ORANGE]),
  _glyphs("•*", [Color.BROWN]),
  _glyphs("•", [Color.DARK_BROWN])
];

final _fireSequence = [
  _glyphs("*", [Color.GOLD, Color.YELLOW]),
  _glyphs("*", [Color.ORANGE]),
  _glyphs("•", [Color.RED]),
  _glyphs("•", [Color.DARK_RED, Color.RED]),
  _glyphs(".", [Color.DARK_RED, Color.RED])
];

final _waterSequence = [
  _glyphs("Oo", [Color.AQUA, Color.LIGHT_BLUE]),
  _glyphs("o•~", [Color.BLUE]),
  _glyphs("~", [Color.BLUE]),
  _glyphs("~", [Color.DARK_BLUE]),
  _glyphs(".", [Color.DARK_BLUE])
];

final _acidSequence = [
  _glyphs("Oo", [Color.YELLOW, Color.GOLD]),
  _glyphs("o•~", [Color.DARK_YELLOW, Color.GOLD]),
  _glyphs(":,", [Color.DARK_YELLOW, Color.DARK_GOLD]),
  _glyphs(".", [Color.DARK_YELLOW])
];

final _coldSequence = [
  _glyphs("*", [Color.WHITE]),
  _glyphs("+x", [Color.LIGHT_BLUE, Color.WHITE]),
  _glyphs("+x", [Color.LIGHT_BLUE, Color.LIGHT_GRAY]),
  _glyphs(".", [Color.GRAY, Color.DARK_BLUE])
];

final _lightningSequence = [
  _glyphs("*", [Color.LIGHT_PURPLE]),
  _glyphs(r"-|\/", [Color.PURPLE, Color.WHITE]),
  _glyphs(".", [Color.BLACK, Color.BLACK, Color.BLACK, Color.LIGHT_PURPLE])
];

final _poisonSequence = [
  _glyphs("Oo", [Color.YELLOW, Color.LIGHT_GREEN]),
  _glyphs("o•", [Color.GREEN, Color.GREEN, Color.DARK_YELLOW]),
  _glyphs("•", [Color.DARK_GREEN, Color.DARK_YELLOW]),
  _glyphs(".", [Color.DARK_GREEN])
];

final _darkSequence = [
  _glyphs("*%", [Color.BLACK, Color.BLACK, Color.LIGHT_GRAY]),
  _glyphs("•", [Color.BLACK, Color.BLACK, Color.GRAY]),
  _glyphs(".", [Color.BLACK]),
  _glyphs(".", [Color.BLACK])
];

final _lightSequence = [
  _glyphs("*", [Color.WHITE]),
  _glyphs("x+", [Color.WHITE, Color.LIGHT_YELLOW]),
  _glyphs(":;\"'`,", [Color.LIGHT_GRAY, Color.YELLOW]),
  _glyphs(".", [Color.GRAY, Color.YELLOW])
];

final _spiritSequence = [
  _glyphs("Oo*+", [Color.LIGHT_PURPLE, Color.GRAY]),
  _glyphs("o+", [Color.PURPLE, Color.GREEN]),
  _glyphs("•.", [Color.DARK_PURPLE, Color.DARK_GREEN, Color.DARK_GREEN])
];

final _elementSequences = {
  Element.NONE:      _noneSequence,
  Element.AIR:       _airSequence,
  Element.EARTH:     _earthSequence,
  Element.FIRE:      _fireSequence,
  Element.WATER:     _waterSequence,
  Element.ACID:      _acidSequence,
  Element.COLD:      _coldSequence,
  Element.LIGHTNING: _lightningSequence,
  Element.POISON:    _poisonSequence,
  Element.DARK:      _darkSequence,
  Element.LIGHT:     _lightSequence,
  Element.SPIRIT:    _spiritSequence
};

/// Draws a motionless particle for an [Element] that fades in intensity over
/// time.
class ElementEffect implements Effect {
  final Vec _pos;
  final List<List<Glyph>> _sequence;
  int _age = 0;

  ElementEffect(this._pos, Element element)
      : _sequence = _elementSequences[element];

  bool update(Game game) {
    if (rng.oneIn(_age + 1)) _age++;
    return _age <= _sequence.length;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    drawGlyph(_pos.x, _pos.y, rng.item(_sequence[_age - 1]));
  }
}

class FrameEffect implements Effect {
  final Vec pos;
  final String char;
  final Color color;
  int life;

  FrameEffect(this.pos, this.char, this.color, {this.life: 4});

  bool update(Game game) {
    return --life >= 0;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    drawGlyph(pos.x, pos.y, new Glyph(char, color));
  }
}

/// Blinks the background color for an actor a couple of times.
class BlinkEffect implements Effect {
  final Actor actor;
  final Color color;
  int life = 8 * 3;

  BlinkEffect(this.actor, this.color);

  bool update(Game game) {
    return --life >= 0;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    if (!actor.isVisible) return;

    if ((life ~/ 8) % 2 == 0) {
      var glyph = actor.appearance;
      glyph = new Glyph.fromCharCode(glyph.char, glyph.fore, color);
      drawGlyph(actor.pos.x, actor.pos.y, glyph);
    }
  }
}

class HitEffect implements Effect {
  final int x;
  final int y;
  final int health;
  int frame = 0;

  static final NUM_FRAMES = 15;

  HitEffect(Actor actor)
  : x = actor.x,
    y = actor.y,
    health = 10 * actor.health.current ~/ actor.health.max;

  bool update(Game game) {
    return frame++ < NUM_FRAMES;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    var back;
    switch (frame ~/ 5) {
      case 0: back = Color.RED;      break;
      case 1: back = Color.DARK_RED; break;
      case 2: back = Color.BLACK;    break;
    }
    drawGlyph(x, y, new Glyph(' 123456789'[health], Color.BLACK, back));
  }
}

class ParticleEffect implements Effect {
  num x;
  num y;
  num h;
  num v;
  int life;
  final Color color;

  ParticleEffect(this.x, this.y, this.color) {
    final theta = rng.range(628) / 100;
    final radius = rng.range(30, 40) / 100;

    h = math.cos(theta) * radius;
    v = math.sin(theta) * radius;
    life = rng.range(7, 15);
  }

  bool update(Game game) {
    x += h;
    y += v;

    final pos = new Vec(x.toInt(), y.toInt());
    if (!game.stage.bounds.contains(pos)) return false;
    if (!game.stage[pos].isPassable) return false;

    return life-- > 0;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    drawGlyph(x.toInt(), y.toInt(), new Glyph('*', color));
  }
}

class HealEffect implements Effect {
  int x;
  int y;
  int frame = 0;

  HealEffect(this.x, this.y);

  bool update(Game game) {
    return frame++ < 24;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    if (!game.stage.get(x, y).visible) return;

    var back;
    switch ((frame ~/ 4) % 4) {
      case 0: back = Color.BLACK;       break;
      case 1: back = Color.DARK_AQUA;   break;
      case 2: back = Color.AQUA;        break;
      case 3: back = Color.LIGHT_AQUA;  break;
    }

    drawGlyph(x - 1, y, new Glyph('-', back));
    drawGlyph(x + 1, y, new Glyph('-', back));
    drawGlyph(x, y - 1, new Glyph('|', back));
    drawGlyph(x, y + 1, new Glyph('|', back));
  }
}

class DetectEffect implements Effect {
  final Vec pos;
  int life = 30;

  DetectEffect(this.pos);

  bool update(Game game) {
    return --life >= 0;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    var radius = life ~/ 4;
    var glyph = new Glyph("*", Color.LIGHT_GOLD);

    var bounds = new Rect(pos.x - radius, pos.y - radius,
        radius * 2 + 1, radius * 2 + 1);

    for (var pixel in bounds) {
      var relative = pos - pixel;
      if (relative < radius && relative > radius - 2) {
        drawGlyph(pixel.x, pixel.y, glyph);
      }
    }
  }
}

class TeleportEffect implements Effect {
  final Vec to;
  final Iterator<Vec> los;
  int tick = 0;

  TeleportEffect(Vec from, Vec to)
    : to = to,
      los = new Los(from, to).iterator;

  bool update(Game game) {
    if (los.current == to) return false;
    los.moveNext();
    return true;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    if (!game.stage[los.current].visible) return;

    var color = rng.item([Color.WHITE, Color.AQUA, Color.BLUE]);

    drawGlyph(los.current.x - 1, los.current.y, new Glyph('-', color));
    drawGlyph(los.current.x + 1, los.current.y, new Glyph('-', color));
    drawGlyph(los.current.x, los.current.y - 1, new Glyph('|', color));
    drawGlyph(los.current.x, los.current.y + 1, new Glyph('|', color));
    drawGlyph(los.current.x, los.current.y, new Glyph('*', color));
  }
}
