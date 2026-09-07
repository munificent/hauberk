import 'dart:js_interop';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/debug/html_builder.dart';
import 'package:hauberk/src/debug/utils.dart';
import 'package:hauberk/src/engine.dart';
import 'package:web/web.dart' as web;

final _content = createContent();

final List<ItemType> _weapons = _content.items.where((item) {
  var attack = item.attack;

  // Only include melee weapons.
  if (attack == null) return false;
  if (attack.isRanged) return false;

  // Skip artifacts because they are overpowered and skew the basic results.
  return !item.isArtifact;
}).toList();

/// For each strength value and dual-wield skill level, finds the weapon or
/// pair of weapons with the highest average damage. This can be used to tune
/// the math for heft and dual wielding.
void main() {
  _buildTable();
}

void _buildTable() async {
  var builder = HtmlBuilder();
  builder.thead();
  builder.td("Str");
  for (var heroClass in _content.classes) {
    builder.td(heroClass.name, right: true);
  }
  builder.tbody();
  for (var strength = 1; strength <= Stat.modifiedMax; strength++) {
    builder.td(strength);

    for (var heroClass in _content.classes) {
      var best = _findBestWeapons(strength, heroClass).join('<br>');
      builder.td(best, right: true);
    }

    builder.trEnd();

    await waitFrame();
    web.document.querySelector('table')!.innerHTML =
        'Testing all weapon combinations for strength $strength...'.toJS;
  }
  builder.tbodyEnd();
  builder.replaceContents('table');
}

List<String> _findBestWeapons(int strengthValue, HeroClass heroClass) {
  var weaponDamage = <String, num>{};
  var weaponDesc = <String, String>{};

  var save = HeroSave.create("Blah", _content.races.first, heroClass);
  var game = Game(_content, 1, save);

  var hero = game.hero;
  save.strength.refresh(save, strengthValue);

  for (var i = 0; i < _weapons.length; i++) {
    for (var j = i - 1; j < _weapons.length; j++) {
      var weapons = [_weapons[i], if (j >= i) _weapons[j]];
      for (var weapon in weapons) {
        hero.equipment.tryAdd(Item(weapon, 1));
      }

      hero.refreshProperties();

      var totalDamage = 0.0;
      for (var hit in hero.createMeleeHits(null)) {
        totalDamage += hit.averageDamage;
      }

      var label = weapons.map((w) => "$w(${w.heft})").join(' + ');
      weaponDamage[label] = totalDamage;
      weaponDesc[label] = "$label ${totalDamage.fmt(w: 7, d: 2)}";

      // We re-use the hero for performance, so unequip the weapons.
      var previous = hero.equipment.toList();
      for (var item in previous) {
        hero.equipment.remove(item);
      }
    }
  }

  var sorted = weaponDamage.keys.toList();
  sorted.sort((a, b) => weaponDamage[b]!.compareTo(weaponDamage[a]!));
  return sorted.take(1).map((weapon) => weaponDesc[weapon]!).toList();
}
