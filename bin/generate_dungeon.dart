import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content.dart';

/// A benchmark that just repeatedly generates dungeons for running in a
/// profiler.

void main() {
  var content = createContent();
  var save = content.createHero("blah");

  while (true) {
    var watch = Stopwatch();
    watch.start();

    // Generate a dungeon at each level.
    var count = 0;
    for (var i = 1; i <= 10; i++) {
      rng.setSeed(i);

      var game = Game(content, save, 1);
      for (var _ in game.generate());

      // Read some bit of game data so the JIT doesn't optimize the whole
      // program away as dead code.
      if (game.hero.pos.x >= -1) count++;
      print(i);
    }

    watch.stop();
    print("Generated $count dungeons in ${watch.elapsedMilliseconds}ms");
  }
}
