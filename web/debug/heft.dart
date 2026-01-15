import 'dart:js_interop';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/content/skill/mastery/dual_wield.dart';
import 'package:hauberk/src/debug/html_builder.dart';
import 'package:hauberk/src/debug/utils.dart';
import 'package:hauberk/src/engine.dart';
import 'package:web/web.dart' as web;

final _content = createContent();

final List<ItemType> _weapons = _content.items
    .where((item) => item.attack != null)
    .toList();

/// For each strength value and dual-wield skill level, finds the weapon or
/// pair of weapons with the highest average damage. This can be used to tune
/// the math for heft and dual wielding.
void main() {
  _buildTable();
}

void _buildTable() async {
  var builder = HtmlBuilder();
  builder.thead();
  builder.td("Str \\ Dual Wield Level");
  for (var wield = 0; wield <= Skill.maxLevel; wield++) {
    builder.td(wield);
  }
  builder.tbody();
  for (var strength = 1; strength <= Stat.modifiedMax; strength++) {
    builder.td(strength);
    for (var wield = 0; wield <= Skill.maxLevel; wield++) {
      var best = _findBestWeapons(strength, wield).join('<br>');
      builder.td(best, right: true);
    }

    builder.trEnd();

    await waitFrame();
    web.document.querySelector('table')!.innerHTML =
        'Generating data for strength $strength...'.toJS;
  }
  builder.tbodyEnd();
  builder.replaceContents('table');
}

List<String> _findBestWeapons(int strengthValue, int dualWieldLevel) {
  var weaponDamage = <String, num>{};
  var weaponDesc = <String, String>{};

  var save = HeroSave.create(
    "Blah",
    _content.races.first,
    _content.classes.first,
  );
  var game = Game(_content, 1, save);

  for (var i = 0; i < _weapons.length; i++) {
    for (var j = i - 1; j < _weapons.length; j++) {
      var weapons = [_weapons[i], if (j >= i) _weapons[j]];

      var totalHeft = 0;
      var totalDamage = 0;

      for (var weapon in weapons) {
        totalHeft += weapon.heft;
        totalDamage += weapon.attack!.damage;
        game.hero.equipment.tryAdd(Item(weapon, 1));
      }

      var heftModifier = 1.0;
      heftModifier = DualWield().modifyHeft(
        game.hero,
        dualWieldLevel,
        heftModifier,
      );
      var scaledHeft = (totalHeft * heftModifier).round();

      var strengthStat = Strength();
      strengthStat.update(strengthValue, (_) {});
      var heftScale = strengthStat.heftScale(scaledHeft);

      var scaledDamage = totalDamage * heftScale;
      var label = weapons.join('+');
      weaponDamage[label] = scaledDamage;
      weaponDesc[label] = scaledDamage.fmt(w: 7, d: 2);

      // We re-use the hero for performance, so unequip the weapons.
      var previous = game.hero.equipment.toList();
      for (var item in previous) {
        game.hero.equipment.remove(item);
      }
    }
  }

  var sorted = weaponDamage.keys.toList();
  sorted.sort((a, b) => weaponDamage[b]!.compareTo(weaponDamage[a]!));
  return sorted
      .take(1)
      .map((weapon) => '$weapon ${weaponDesc[weapon]!}')
      .toList();
}
