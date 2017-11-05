import 'dart:math' as math;

import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/items.dart';

const tries = 1000;

main() {
  Items.initialize();

  var line = " ".padRight(32);

  for (var strength = 1; strength <= 60; strength += 2) {
    line += strength.toString().padLeft(2) + " ";
  }

  print(line);

  for (var itemType in Items.types.all) {
    if (itemType.toss == null) continue;

    var line = itemType.toString().padRight(32);

    for (var strength = 1; strength <= 60; strength += 2) {
      var range = itemType.toss.attack.range;
      range = math.max(1, (range * Strength.tossRangeScale(strength)).round());
      line += range.toString().padLeft(2) + " ";
    }

    print(line);
  }
}
