import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'effect.dart';

/// An animated series of glyphs.
///
/// Each frame in the series is a moment in time. Each frame can have multiple
/// glyphs which are chosen from randomly.
class Animation {
  final List<List<Glyph>> _frames;

  Animation(this._frames);

  int get length => _frames.length;

  Glyph get(int frame) => rng.item(_frames[frame]);
}

class AnimationBuilder {
  final List<List<Glyph>> _frames = [];

  AnimationBuilder addSingle(Glyph glyph) {
    _frames.add([glyph]);
    return this;
  }

  /// Adds a frame with [Glyph]s for each combination of [chars] and [colors].
  AnimationBuilder frame(String chars, List<Color> colors) {
    var results = <Glyph>[];
    for (var char in chars.codeUnits) {
      for (var color in colors) {
        results.add(Glyph.fromCharCode(char, color));
      }
    }

    _frames.add(results);
    return this;
  }

  Animation build() => Animation(_frames);
}

/// Plays an animation.
class AnimationEffect implements Effect {
  final Vec _pos;
  final Animation _animation;
  int _age = -1;

  AnimationEffect(this._pos, this._animation);

  @override
  bool update(Game game) {
    return ++_age < _animation.length;
  }

  @override
  void render(Game game, DrawGlyph drawGlyph) {
    if (game.stage[_pos].isOccluded) return;
    drawGlyph(_pos.x, _pos.y, _animation.get(_age));
  }
}
