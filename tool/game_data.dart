import 'dart:convert';

import 'package:hauberk/src/content/item/drops.dart';
import 'package:hauberk/src/content/monster/monsters.dart';
import 'package:hauberk/src/content/monster/spawns.dart';
import 'package:malison/malison.dart';

/// Prints out game data in a deterministic text format. Makes it easier to
/// refactor content code and ensure it didn't change the game data
/// unexpectedly.
void main() {
  Monsters.initialize();

  var names = Monsters.breeds.all.map((breed) => breed.name).toList();
  names.sort();

  var data = <Object?>[];
  for (var name in names) {
    var breed = Monsters.breeds.find(name);
    var breedData = {
      // TODO: Expand name data.
      'name': breed.name,
      'appearance': _appearanceGameData(breed.appearance),
      'depth': breed.depth,
      'maxHealth': breed.maxHealth,
      'tracking': breed.tracking,
      'vision': breed.vision,
      'hearing': breed.hearing,
      'meander': breed.meander,
      'speed': breed.speed,
      'drop': dropGameData(breed.drop),
      'spawnLocation': breed.location.name,
      'motility': breed.motility.toString(),
      'flags': breed.flags.toString(),
      'dodge': breed.dodge,
      'emanationLevel': breed.emanationLevel,
      'countMin': breed.countMin,
      'countMax': breed.countMax,
      'groups': breed.groups,
      'description': breed.description,
      if (breed.stain case var stain?) 'stain': stain.name,
      if (breed.minions case var minions?) 'minions': spawnGameData(minions),
      if (breed.attacks.isNotEmpty)
        'attacks': [
          for (var attack in breed.attacks)
            {
              if (attack.prop case var prop?) 'prop': prop.noun.short,
              'verb': attack.verb,
              'damage': attack.damage,
              'range': attack.range,
              'element': attack.element.name,
            },
        ],
      if (breed.moves.isNotEmpty)
        'moves': [
          for (var move in breed.moves)
            {
              'rate': move.rate,
              'range': move.range,
              'experience': move.experience,
              'type': move.runtimeType.toString(),
              // TODO: Include type-specific properties.
            },
        ],
    };
    data.add(breedData);
  }

  var encoder = JsonEncoder.withIndent('  ');
  var json = encoder.convert(data);
  print(json);
}

Object _appearanceGameData(Object appearance) {
  switch (appearance) {
    case Glyph glyph:
      return {
        'type': 'glyph',
        'char': glyph.char,
        'fore': glyph.fore.cssColor,
        'back': glyph.back.cssColor,
      };

    default:
      return appearance.toString();
  }
}
