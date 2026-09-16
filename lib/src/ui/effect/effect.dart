import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../../content.dart';
import '../../engine.dart';
import '../../hues.dart';
import 'animation.dart';
import 'blink.dart';
import 'damage.dart';
import 'detect.dart';
import 'element.dart';
import 'frame.dart';
import 'heal.dart';
import 'howl.dart';
import 'item.dart';
import 'map.dart';
import 'particle.dart';
import 'teleport.dart';
import 'treasure.dart';

// TODO: Effects need to take background color into effect better: should be
// black when over unexplored tiles, unlit over unlit, etc.

/// Adds an [Effect]s that should be displayed when [event] happens.
void addEffects(List<Effect> effects, Event event) {
  switch (event.type) {
    case Events.bolt:
      // TODO: Assumes all none-element bolts are arrows. Do something better?
      if (event.element == Element.none) {
        var char = _lines[event.dir]!;
        effects.add(FrameEffect(event.pos, char, sandal, life: 2));
      } else {
        effects.add(ElementEffect(event.pos, event.element));
      }

    case Events.icicle:
      var animation = _icicleAnimations[event.dir]!;
      effects.add(AnimationEffect(event.pos, animation));

    case Events.cone:
      effects.add(ElementEffect(event.pos, event.element));

    case EventType.toss:
      effects.add(ItemEffect(event.pos, event.item!));

    case EventType.hit:
      effects.add(DamageEffect(event.actor!, event.element, event.amount));

    case EventType.die:
      // TODO: Make number of particles vary based on monster health.
      for (var i = 0; i < 10; i++) {
        // TODO: Different blood colors for different breeds.
        effects.add(
          ParticleEffect(event.actor!.pos.x, event.actor!.pos.y, red),
        );
      }

    case Events.heal:
      effects.add(HealEffect(event.actor!.pos.x, event.actor!.pos.y));

    case Events.detect:
      effects.add(DetectEffect(event.pos));

    case Events.perceive:
      // TODO: Make look different.
      effects.add(DetectEffect(event.actor!.pos));

    case Events.map:
      effects.add(MapEffect(event.pos));

    case Events.teleport:
      var numParticles = (event.actor!.pos - event.pos).kingLength.clamp(4, 12);
      for (var i = 0; i < numParticles; i++) {
        effects.add(TeleportEffect(event.pos, event.actor!.pos));
      }

    case Events.spawn:
      // TODO: Something more interesting.
      effects.add(FrameEffect(event.actor!.pos, '*', lighterCoolGray));

    case Events.polymorph:
      // TODO: Something more interesting.
      effects.add(FrameEffect(event.actor!.pos, '*', lighterCoolGray));

    case Events.howl:
      effects.add(HowlEffect(event.pos));

    case EventType.awaken:
      effects.add(BlinkEffect(event.actor!, Glyph('!', lighterCoolGray), 1));

    case EventType.frighten:
      effects.add(BlinkEffect(event.actor!, Glyph("!", gold), 3));

    case Events.wind:
      // TODO: Do something.
      break;

    case Events.knockBack:
      // TODO: Something more interesting.
      effects.add(FrameEffect(event.pos, "*", buttermilk));

    case Events.slash:
    case Events.stab:
      var line = _lines[event.dir]!;

      var color = lighterCoolGray;
      if (event.item case var item?) {
        color = (item.appearance as Glyph).fore;
      }
      // TODO: If monsters starting using this, we'll need some other way to
      // color it.

      effects.add(FrameEffect(event.pos, line, color));

    case EventType.gold:
      effects.add(TreasureEffect(event.pos, event.item!));

    case Events.openBarrel:
      effects.add(FrameEffect(event.pos, '*', sandal));
  }
}

typedef DrawGlyph = void Function(int x, int y, Glyph glyph);

abstract class Effect {
  bool update(Game game);

  void render(Game game, DrawGlyph drawGlyph);
}

final _lines = {
  Direction.n: "|",
  Direction.ne: "/",
  Direction.e: "-",
  Direction.se: r"\",
  Direction.s: "|",
  Direction.sw: "/",
  Direction.w: "-",
  Direction.nw: r"\",
};

final _chevrons = {
  Direction.n: "^",
  Direction.ne: "┐",
  Direction.e: ">",
  Direction.se: "┘",
  Direction.s: "v",
  Direction.sw: "└",
  Direction.w: "<",
  Direction.nw: "┌",
};

// TODO: Better place for this?
final _icicleAnimations = {
  for (var direction in Direction.all)
    direction: AnimationBuilder()
        .frame(_chevrons[direction]!, [lighterCoolGray])
        .frame(_chevrons[direction]!, [lightBlue])
        .frame("*x+", [blue])
        .frame("*x+", [darkBlue])
        .build(),
};
