import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/monster/monsters.dart';

const tries = 1000;

main() {
  Monsters.initialize();

  for (var i = 0; i < 20; i++) {
    var watch = Stopwatch();
    watch.start();
    var generated = trial();
    watch.stop();
    print("new generated $generated in ${watch.elapsedMilliseconds}");
  }
}

int trial() {
  var generated = 0;
  for (var depth = 1; depth <= Option.maxDepth; depth++) {
    for (var i = 0; i < tries; i++) {
      var breed = Monsters.breeds.tryChoose(depth);
      if (breed == null) continue;

      generated++;
    }
  }

  return generated;
}
