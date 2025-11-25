import 'package:hauberk/src/debug/histogram.dart';
import 'package:hauberk/src/debug/html_builder.dart';
import 'package:hauberk/src/engine.dart';

final breedDrops = <Breed, Histogram<String>>{};

void main() {
  var strength = Strength();
  var agility = Agility();
  var fortitude = Fortitude();
  var intellect = Intellect();
  var will = Will();

  var builder = HtmlBuilder();
  builder.table();
  builder.td('');
  builder.td('Strength', colspan: 4);
  builder.td('Agility', colspan: 2);
  builder.td('Fortitude');
  builder.td('Intellect', colspan: 2);
  builder.td('Will');
  builder.trEnd();
  builder.td('Stat', right: true);
  builder.td('Max Fury', right: true);
  builder.td('Max Fury Dmg', right: true);
  builder.td('Toss', right: true);
  builder.td('Heft', right: true);
  builder.td('Dodge', right: true);
  builder.td('Strike', right: true);
  builder.td('Health', right: true);
  builder.td('Max Focus', right: true);
  builder.td('Spell Focus', right: true);
  builder.td('Focus', right: true);
  builder.tbody();

  for (var i = 1; i <= Stat.modifiedMax; i++) {
    strength.update(i, (_) {});
    agility.update(i, (_) {});
    fortitude.update(i, (_) {});
    intellect.update(i, (_) {});
    will.update(i, (_) {});

    builder.td(i);
    builder.td(strength.maxFury);
    builder.td(
      strength.furyScale(strength.maxFury).toStringAsFixed(1),
      right: true,
    );
    builder.td(strength.tossRangeScale.toStringAsFixed(1), right: true);
    builder.td(strength.heftScale(20).toStringAsFixed(2), right: true);
    builder.td(agility.dodgeBonus);
    builder.td(agility.strikeBonus);
    builder.td(fortitude.maxHealth);
    builder.td(intellect.maxFocus);
    builder.td(intellect.spellFocusScale(10).toStringAsFixed(2), right: true);
    builder.td(will.damageFocusScale.toStringAsFixed(0), right: true);
    builder.trEnd();
  }

  builder.tableEnd();
  builder.replaceContents('table');
}
