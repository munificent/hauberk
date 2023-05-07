import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/engine.dart';

/// Estimates how many monsters need to be killed to reach each experience
/// level.
void main() {
  Monsters.initialize();

  var breedsByDepth = <int, List<Breed>>{};
  for (var breed in Monsters.breeds.all) {
    breedsByDepth.putIfAbsent(breed.depth, () => []).add(breed);
  }

  var exp = 0.0;
  var averages = <double>[];
  for (var depth = 1; depth <= 100; depth++) {
    if (breedsByDepth.containsKey(depth)) {
      var breeds = breedsByDepth[depth]!;
      exp =
          breeds.fold<double>(0.0, (a, b) => a + b.experience) / breeds.length;
      print("${depth.toString().padLeft(3)}: $exp (${breeds.length} breeds)");
    } else {
      print("${depth.toString().padLeft(3)}: (no breeds)");
    }

    averages.add(exp);
  }

  var level = 1;
  exp = 0.0;
  var kills = 0;
  var totalKills = 0;
  while (level < Hero.maxLevel) {
    // Assume hero descends at an even rate to reach max level right at the
    // bottom of the dungeon.
    var depth = (level - 1) * 2;
    exp += averages[depth];
    kills++;
    totalKills++;
    while (level < Hero.maxLevel && exp >= experienceLevelCost(level + 1)) {
      level++;
      print("killed $kills more to reach $level");
      kills = 0;
    }
  }

  print("killed $totalKills total monsters to reach level $level");
}
