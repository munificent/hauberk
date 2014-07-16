library hauberk.content.debug_area;

import '../engine.dart';
import '../util.dart';
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
