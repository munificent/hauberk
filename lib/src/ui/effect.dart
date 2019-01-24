import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import '../content/elements.dart';
import '../engine.dart';
import '../hues.dart';

// TODO: Effects need to take background color into effect better: should be
// black when over unexplored tiles, unlit over unlit, etc.

final _directionLines = {
  Direction.n: "|",
  Direction.ne: "/",
  Direction.e: "-",
  Direction.se: r"\",
  Direction.s: "|",
  Direction.sw: "/",
  Direction.w: "-",
  Direction.nw: r"\"
};

/// Adds an [Effect]s that should be displayed when [event] happens.
void addEffects(List<Effect> effects, Event event) {
  switch (event.type) {
    case EventType.pause:
      // Do nothing.
      break;

    case EventType.bolt:
      // TODO: Assumes all none-element bolts are arrows. Do something better?
      if (event.element == Element.none) {
        var char = const {
          Direction.none: "•",
          Direction.n: "|",
          Direction.ne: "/",
          Direction.e: "-",
          Direction.se: "\\",
          Direction.s: "|",
          Direction.sw: "/",
          Direction.w: "-",
          Direction.nw: "\\",
        }[event.dir];
        effects.add(FrameEffect(event.pos, char, sandal, life: 2));
      } else {
        effects.add(ElementEffect(event.pos, event.element));
      }
      break;

    case EventType.cone:
      effects.add(ElementEffect(event.pos, event.element));
      break;

    case EventType.toss:
      effects.add(ItemEffect(event.pos, event.other as Item));
      break;

    case EventType.hit:
      effects.add(DamageEffect(event.actor, event.element, event.other as int));
      break;

    case EventType.die:
      // TODO: Make number of particles vary based on monster health.
      for (var i = 0; i < 10; i++) {
        // TODO: Different blood colors for different breeds.
        effects.add(ParticleEffect(event.actor.x, event.actor.y, red));
      }
      break;

    case EventType.heal:
      effects.add(HealEffect(event.actor.pos.x, event.actor.pos.y));
      break;

    case EventType.detect:
      effects.add(DetectEffect(event.pos));
      break;

    case EventType.perceive:
      // TODO: Make look different.
      effects.add(DetectEffect(event.actor.pos));
      break;

    case EventType.map:
      effects.add(MapEffect(event.pos));
      break;

    case EventType.teleport:
      var numParticles = (event.actor.pos - event.pos).kingLength * 2;
      for (var i = 0; i < numParticles; i++) {
        effects.add(TeleportEffect(event.pos, event.actor.pos));
      }
      break;

    case EventType.spawn:
      // TODO: Something more interesting.
      effects.add(FrameEffect(event.actor.pos, '*', ash));
      break;

    case EventType.polymorph:
      // TODO: Something more interesting.
      effects.add(FrameEffect(event.actor.pos, '*', ash));
      break;

    case EventType.howl:
      effects.add(HowlEffect(event.actor));
      break;

    case EventType.awaken:
      effects.add(BlinkEffect(event.actor, Glyph('!', ash)));
      break;

    case EventType.frighten:
      effects.add(BlinkEffect(event.actor, Glyph("!", gold)));
      break;

    case EventType.wind:
      // TODO: Do something.
      break;

    case EventType.knockBack:
      // TODO: Something more interesting.
      effects.add(FrameEffect(event.pos, "*", buttermilk));
      break;

    case EventType.slash:
    case EventType.stab:
      var line = _directionLines[event.dir];

      var color = ash;
      if (event.other != null) {
        color = (event.other as Glyph).fore;
      }
      // TODO: If monsters starting using this, we'll need some other way to
      // color it.

      effects.add(FrameEffect(event.pos, line, color));
      break;

    case EventType.gold:
      effects.add(TreasureEffect(event.pos, event.other as Item));
      break;

    case EventType.openBarrel:
      effects.add(FrameEffect(event.pos, '*', sandal));
      break;
  }
}

typedef void DrawGlyph(int x, int y, Glyph glyph);

abstract class Effect {
  bool update(Game game);

  void render(Game game, DrawGlyph drawGlyph);
}

/// Creates a list of [Glyph]s for each combination of [chars] and [colors].
List<Glyph> _glyphs(String chars, List<Color> colors) {
  var results = <Glyph>[];
  for (var char in chars.codeUnits) {
    for (var color in colors) {
      results.add(Glyph.fromCharCode(char, color));
    }
  }

  return results;
}

// TODO: Design custom sprites for these.
final _elementSequences = <Element, List<List<Glyph>>>{
  Element.none: [
    _glyphs("•", [sandal]),
    _glyphs("•", [sandal]),
    _glyphs("•", [tan])
  ],
  Elements.air: [
    _glyphs("Oo", [ash, lightAqua]),
    _glyphs(".", [lightAqua]),
    _glyphs(".", [lightBlue])
  ],
  Elements.earth: [
    _glyphs("*%", [sandal, gold]),
    _glyphs("*%", [tan, brown]),
    _glyphs("•*", [tan]),
    _glyphs("•", [brown])
  ],
  Elements.fire: [
    _glyphs("▲^", [gold, buttermilk]),
    _glyphs("*^", [carrot]),
    _glyphs("^", [red]),
    _glyphs("^", [brown, red]),
    _glyphs(".", [brown, red])
  ],
  Elements.water: [
    _glyphs("Oo", [lightAqua, lightBlue]),
    _glyphs("o•^", [lightBlue, blue]),
    _glyphs("•^", [blue, darkBlue]),
    _glyphs("^~", [blue, darkBlue]),
    _glyphs("~", [darkBlue]),
    _glyphs(".", [darkBlue, violet])
  ],
  Elements.acid: [
    _glyphs("Oo", [buttermilk, gold]),
    _glyphs("o•~", [lima, gold]),
    _glyphs(":,", [lima, olive]),
    _glyphs(".", [lima])
  ],
  Elements.cold: [
    _glyphs("*", [ash]),
    _glyphs("+x", [lightAqua, ash]),
    _glyphs("+x", [lightBlue, lightCoolGray]),
    _glyphs(".", [coolGray, darkBlue])
  ],
  Elements.lightning: [
    _glyphs("*", [lilac]),
    _glyphs(r"-|\/", [purple, ash]),
    _glyphs(".", [darkerCoolGray, darkerCoolGray, darkerCoolGray, lilac])
  ],
  Elements.poison: [
    _glyphs("Oo", [mint, lima]),
    _glyphs("o•", [peaGreen, peaGreen, olive]),
    _glyphs("•", [sherwood, olive]),
    _glyphs(".", [sherwood])
  ],
  Elements.dark: [
    _glyphs("*%", [darkerCoolGray, darkerCoolGray, darkCoolGray]),
    _glyphs("•", [darkerCoolGray, darkerCoolGray, lightCoolGray]),
    _glyphs(".", [darkerCoolGray]),
    _glyphs(".", [darkerCoolGray])
  ],
  Elements.light: [
    _glyphs("*", [ash]),
    _glyphs("x+", [ash, buttermilk]),
    _glyphs(":;\"'`,", [buttermilk, gold]),
    _glyphs(".", [lightCoolGray, buttermilk])
  ],
  Elements.spirit: [
    _glyphs("Oo*+", [lilac, lightCoolGray]),
    _glyphs("o+", [purple, peaGreen]),
    _glyphs("•.", [violet, sherwood, sherwood])
  ]
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
    if (rng.oneIn(_age + 2)) _age++;
    return _age < _sequence.length;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    drawGlyph(_pos.x, _pos.y, rng.item(_sequence[_age]));
  }
}

class FrameEffect implements Effect {
  final Vec pos;
  final String char;
  final Color color;
  int life;

  FrameEffect(this.pos, this.char, this.color, {this.life = 4});

  bool update(Game game) {
    if (!game.stage[pos].isVisible) return false;

    return --life >= 0;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    drawGlyph(pos.x, pos.y, Glyph(char, color));
  }
}

/// Draws an [Item] as a given position. Used for thrown items.
class ItemEffect implements Effect {
  final Vec pos;
  final Item item;
  int _life = 2;

  ItemEffect(this.pos, this.item);

  bool update(Game game) {
    if (!game.stage[pos].isVisible) return false;

    return --_life >= 0;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    drawGlyph(pos.x, pos.y, item.appearance as Glyph);
  }
}

class DamageEffect implements Effect {
  final Actor actor;
  final Element element;
  final int _blinks;
  int _frame = 0;

  DamageEffect(this.actor, this.element, int damage)
      : _blinks = math.sqrt(damage / 5).ceil();

  bool update(Game game) => ++_frame < _blinks * _framesPerBlink;

  void render(Game game, DrawGlyph drawGlyph) {
    var frame = _frame % _framesPerBlink;
    if (frame < _framesPerBlink ~/ 2) {
      drawGlyph(actor.x, actor.y, Glyph("*", elementColor(element)));
    }
  }

  /// Blink faster as the number of blinks increases so that the effect doesn't
  /// get gratuitously long.
  int get _framesPerBlink => lerpInt(_blinks, 1, 10, 16, 8);
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

    final pos = Vec(x.toInt(), y.toInt());
    if (!game.stage.bounds.contains(pos)) return false;
    if (!game.stage[pos].isFlyable) return false;

    return life-- > 0;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    drawGlyph(x.toInt(), y.toInt(), Glyph('•', color));
  }
}

/// A particle that starts with a random initial velocity and arcs towards a
/// target.
class TeleportEffect implements Effect {
  num x;
  num y;
  num h;
  num v;
  int age = 0;
  final Vec target;

  static final _colors = [lightAqua, lightBlue, lilac, ash];

  TeleportEffect(Vec from, this.target) {
    x = from.x;
    y = from.y;

    var theta = rng.range(628) / 100;
    var radius = rng.range(10, 80) / 100;

    h = math.cos(theta) * radius;
    v = math.sin(theta) * radius;
  }

  bool update(Game game) {
    var friction = 1.0 - age * 0.015;
    h *= friction;
    v *= friction;

    var pull = age * 0.003;
    h += (target.x - x) * pull;
    v += (target.y - y) * pull;

    x += h;
    y += v;

    age++;
    return (Vec(x.toInt(), y.toInt()) - target) > 1;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    var pos = Vec(x.toInt(), y.toInt());
    if (!game.stage.bounds.contains(pos)) return;

    var char = _getChar(h, v);
    var color = rng.item(_colors);

    drawGlyph(pos.x, pos.y, Glyph.fromCharCode(char, color));
  }

  /// Chooses a "line" character based on the vector [x], [y]. It will try to
  /// pick a line that follows the vector.
  int _getChar(num x, num y) {
    var velocity = Vec((x * 10).toInt(), (y * 10).toInt());
    if (velocity < 5) return CharCode.bullet;

    var angle = math.atan2(x, y) / (math.pi * 2) * 16 + 8;
    return r"|\\--//||\\--//||".codeUnitAt(angle.floor());
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
    if (game.stage.get(x, y).isOccluded) return;

    Color back;
    switch ((frame ~/ 4) % 4) {
      case 0:
        back = darkerCoolGray;
        break;
      case 1:
        back = aqua;
        break;
      case 2:
        back = lightBlue;
        break;
      case 3:
        back = lightAqua;
        break;
    }

    drawGlyph(x - 1, y, Glyph('-', back));
    drawGlyph(x + 1, y, Glyph('-', back));
    drawGlyph(x, y - 1, Glyph('|', back));
    drawGlyph(x, y + 1, Glyph('|', back));
  }
}

class DetectEffect implements Effect {
  static final _colors = [
    ash,
    buttermilk,
    gold,
    olive,
    darkOlive,
  ];

  final Vec pos;
  int life = 20;

  DetectEffect(this.pos);

  bool update(Game game) => --life >= 0;

  void render(Game game, DrawGlyph drawGlyph) {
    var radius = life ~/ 4;
    var glyph = Glyph("*", _colors[radius]);

    for (var pixel in Circle(pos, radius).edge) {
      drawGlyph(pixel.x, pixel.y, glyph);
    }
  }
}

class MapEffect implements Effect {
  final _maxLife = rng.range(10, 20);

  final Vec pos;
  int life;

  MapEffect(this.pos) {
    life = _maxLife;
  }

  bool update(Game game) => --life >= 0;

  void render(Game game, DrawGlyph drawGlyph) {
    var glyph = game.stage[pos].type.appearance as Glyph;

    glyph = Glyph.fromCharCode(
        glyph.char,
        glyph.fore.blend(gold, life / _maxLife),
        glyph.back.blend(tan, life / _maxLife));

    drawGlyph(pos.x, pos.y, glyph);
  }
}

/// Floats a treasure item upward.
class TreasureEffect implements Effect {
  final int _x;
  int _y;
  final Item _item;
  int _life = 8;

  TreasureEffect(Vec pos, this._item)
      : _x = pos.x,
        _y = pos.y;

  bool update(Game game) {
    if (_life % 2 == 0) {
      _y--;
      if (_y < 0) return false;
    }

    return --_life >= 0;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    drawGlyph(_x, _y, _item.appearance as Glyph);
  }
}

class HowlEffect implements Effect {
  static final bang = Glyph("!", aqua);
  static final slash = Glyph("/", lightAqua);
  static final backslash = Glyph("\\", lightAqua);
  static final dash = Glyph("-", aqua);
  static final less = Glyph("<", aqua);
  static final greater = Glyph(">", aqua);

  final Actor _actor;
  int _age = 0;

  HowlEffect(this._actor);

  bool update(Game game) {
    return ++_age < 24;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    var pos = _actor.pos;

    if ((_age ~/ 6) % 2 == 0) {
      drawGlyph(pos.x, pos.y, bang);
      drawGlyph(pos.x - 1, pos.y, greater);
      drawGlyph(pos.x + 1, pos.y, less);
    } else {
      drawGlyph(pos.x - 1, pos.y - 1, backslash);
      drawGlyph(pos.x - 1, pos.y + 1, slash);
      drawGlyph(pos.x + 1, pos.y - 1, slash);
      drawGlyph(pos.x + 1, pos.y + 1, backslash);
      drawGlyph(pos.x - 1, pos.y, dash);
      drawGlyph(pos.x + 1, pos.y, dash);
    }
  }
}

class BlinkEffect implements Effect {
  final Actor _actor;
  final Glyph _glyph;
  int _age = 0;

  BlinkEffect(this._actor, this._glyph);

  bool update(Game game) {
    if (!game.stage[_actor.pos].isVisible) return false;

    return ++_age < 24;
  }

  void render(Game game, DrawGlyph drawGlyph) {
    var pos = _actor.pos;

    if ((_age ~/ 6) % 2 == 1) {
      drawGlyph(pos.x, pos.y, _glyph);
    }
  }
}
