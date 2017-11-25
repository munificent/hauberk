import 'dart:math' as math;

import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content/items.dart';

const tries = 1000;

main(List<String> arguments) {
  Items.initialize();

  if (arguments.length == 0) return;

  if (arguments[0] == "toss") _showTossRanges();
  if (arguments[0] == "heft") _showHeft();
}

void _showTossRanges() {
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

void _showHeft() {
  var line = " ".padRight(32);

  for (var strength = 1; strength <= 60; strength += 4) {
    line += strength.toString().padLeft(6) + " ";
  }

  print(line);

  for (var itemType in Items.types.all) {
    if (itemType.attack == null) continue;
    // Ignore ranged weapons.
    if (itemType.attack.range > 0) continue;

    var line = itemType.toString().padRight(32);

    for (var strength = 1; strength <= 60; strength += 4) {
      var scale = Strength.scaleHeft(strength - itemType.heft);
      var damage = itemType.attack.damage * scale;
      line += damage.toStringAsFixed(2).padLeft(6) + " ";
    }

    print(line);
  }

  print("");

  // Figure out which weapons have the most power at each strength level.
  for (var strength = 1; strength <= 60; strength++) {
    var damages = <ItemType, double>{};

    for (var itemType in Items.types.all) {
      if (itemType.attack == null) continue;
      // Ignore ranged weapons.
      if (itemType.attack.range > 0) continue;

      var scale = Strength.scaleHeft(strength - itemType.heft);
      var damage = itemType.attack.damage * scale;
      damages[itemType] = damage;
    }

    var items = damages.keys.toList();
    items.sort((a, b) => damages[b].compareTo(damages[a]));

    var line = strength.toString().padLeft(2);
    for (var item in items.take(5)) {
      line += item.name.padLeft(14) +
          "(${(strength - item.heft).toString().padLeft(3)}): " +
          damages[item].toStringAsFixed(2).padLeft(6);
    }

    print(line);
  }
}

//void _showHeftCsv() {
//  var line = "Weapon,";
//
//  for (var strength = 1; strength <= 60; strength++) {
//    line += strength.toString() + ",";
//  }
//
//  print(line);
//
//  for (var itemType in Items.types.all) {
//    if (itemType.attack == null) continue;
//
//    var line = itemType.toString();
//
//    for (var strength = 1; strength <= 60; strength++) {
//      var scale = Strength.scaleHeft(strength - itemType.heft);
//      var damage = itemType.attack.damage * scale;
//      line += "," + damage.toStringAsFixed(2);
//    }
//
//    print(line);
//  }
//}
