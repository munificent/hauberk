library hauberk.content.debug_area;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'stage_builder.dart';
import 'tiles.dart';

class DebugArea extends StageBuilder {
  void generate(Stage stage) {
    bindStage(stage);
    fill(Tiles.wall);

    for (var pos in stage.bounds.inflate(-5)) {
      setTile(pos, Tiles.floor);
    }

    for (var x = 10; x <= 20; x++) {
      setTile(new Vec(x, 15), Tiles.wall);
      setTile(new Vec(x, 25), Tiles.wall);
    }

    for (var y = 15; y <= 25; y++) {
      setTile(new Vec(10, y), Tiles.wall);
      setTile(new Vec(20, y), Tiles.wall);
    }

    setTile(new Vec(20, 20), Tiles.closedDoor);
  }
}

/// Creates a monster that breathes a cone for each element. Useful for
/// debugging element effects.
class DebugConeArea extends StageBuilder {
  void generate(Stage stage) {
    bindStage(stage);
    fill(Tiles.wall);

    for (var pos in stage.bounds.inflate(-1)) {
      setTile(pos, Tiles.floor);
    }

    var x = 4;
    var y = 4;
    for (var element in Element.all) {
      // TODO: Element-based color.
      var breed = new Breed("${element} breather", Pronoun.it,
          new Glyph(element.name.substring(0, 1).toUpperCase(), Color.white), [
      ], [
        new BoltMove(2, new RangedAttack("element", "hits", 1, element, 12)),
        new ConeMove(2, new RangedAttack("element", "hits", 1, element, 12))
      ], null, maxHealth: 100, tracking: 0, meander: 0, speed: 0,
          flags: new Set.from(["immobile"]));

      stage.addActor(breed.spawn(stage.game, new Vec(x, y)));
      x += 12;
      if (x > stage.width) {
        x = 10;
        y = stage.height - 6;
      }
    }
  }
}
