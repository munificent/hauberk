import 'package:piecemeal/piecemeal.dart';

import '../../content.dart';
import '../../engine.dart';
import '../../hues.dart';
import 'animation.dart';
import 'effect.dart';

/// Draws a motionless particle for an [Element] that fades in intensity over
/// time.
class ElementEffect implements Effect {
  final Vec _pos;
  final Animation _animation;
  int _age = 0;

  ElementEffect(this._pos, Element element)
    : _animation = _elementAnimations[element]!;

  @override
  bool update(Game game) {
    if (rng.oneIn(_age + 2)) _age++;
    return _age < _animation.length;
  }

  @override
  void render(Game game, DrawGlyph drawGlyph) {
    if (game.stage.get(_pos.x, _pos.x).isOccluded) return;

    drawGlyph(_pos.x, _pos.y, _animation.get(_age));
  }
}

final _elementAnimations = <Element, Animation>{
  Element.none: AnimationBuilder()
      .frame("•", [sandal])
      .frame("•", [sandal])
      .frame("•", [tan])
      .build(),
  Elements.air: AnimationBuilder()
      .frame("Oo", [lighterCoolGray, lightAqua])
      .frame(".", [lightAqua])
      .frame(".", [lightBlue])
      .build(),
  Elements.earth: AnimationBuilder()
      .frame("*%", [sandal, gold])
      .frame("*%", [tan, brown])
      .frame("•*", [tan])
      .frame("•", [brown])
      .build(),
  Elements.fire: AnimationBuilder()
      .frame("▲^", [gold, buttermilk])
      .frame("*^", [carrot])
      .frame("^", [red])
      .frame("^", [brown, red])
      .frame(".", [brown, red])
      .build(),
  Elements.water: AnimationBuilder()
      .frame("Oo", [lightAqua, lightBlue])
      .frame("o•^", [lightBlue, blue])
      .frame("•^", [blue, darkBlue])
      .frame("^~", [blue, darkBlue])
      .frame("~", [darkBlue])
      .frame(".", [darkBlue, violet])
      .build(),
  Elements.acid: AnimationBuilder()
      .frame("Oo", [buttermilk, gold])
      .frame("o•~", [lima, gold])
      .frame(":,", [lima, olive])
      .frame(".", [lima])
      .build(),
  Elements.cold: AnimationBuilder()
      .frame("*", [lighterCoolGray])
      .frame("+x", [lightAqua, lighterCoolGray])
      .frame("+x", [lightBlue, lightCoolGray])
      .frame(".", [coolGray, darkBlue])
      .build(),
  Elements.lightning: AnimationBuilder()
      .frame("*", [lilac])
      .frame(r"-|\/", [purple, lighterCoolGray])
      .frame(".", [darkerCoolGray, darkerCoolGray, darkerCoolGray, lilac])
      .build(),
  Elements.poison: AnimationBuilder()
      .frame("Oo", [mint, lima])
      .frame("o•", [peaGreen, peaGreen, olive])
      .frame("•", [sherwood, olive])
      .frame(".", [sherwood])
      .build(),
  Elements.dark: AnimationBuilder()
      .frame("*%", [darkerCoolGray, darkerCoolGray, darkCoolGray])
      .frame("•", [darkerCoolGray, darkerCoolGray, lightCoolGray])
      .frame(".", [darkerCoolGray])
      .frame(".", [darkerCoolGray])
      .build(),
  Elements.light: AnimationBuilder()
      .frame("*", [lighterCoolGray])
      .frame("x+", [lighterCoolGray, buttermilk])
      .frame(":;\"'`,", [buttermilk, gold])
      .frame(".", [lightCoolGray, buttermilk])
      .build(),
  Elements.spirit: AnimationBuilder()
      .frame("Oo*+", [lilac, lightCoolGray])
      .frame("o+", [purple, peaGreen])
      .frame("•.", [violet, sherwood, sherwood])
      .build(),
};
