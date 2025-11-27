import 'package:hauberk/src/engine.dart';

void main() {
  print('Stat       0.7      0.8      0.9      1.0      1.1      1.2      1.3');
  print('-----  -------  -------  -------  -------  -------  -------  -------');
  for (var statTotal = 50; statTotal <= 50 * 5; statTotal += 5) {
    var line = statTotal.toString().padLeft(4);
    line += ':  ';
    for (var raceScale = 0.7; raceScale <= 1.4; raceScale += 0.1) {
      line += Stat.experienceCostAt(statTotal, raceScale).toString().padLeft(7);
      line += '  ';
    }
    print(line);
  }

  print('');
  print('');

  var strength = Strength();
  var agility = Agility();
  var vitality = Vitality();
  var intellect = Intellect();
  var will = Will();

  print("     Strength   Agility     Vitality  Intellect           Will");
  print("     ┌───────┐ ┌──────────┐ ┌───────┐ ┌─────────────────┐ ┌───┐");
  print("Lvl  Toss Heft Dodge Strike MaxHealth MaxFocus SpellFocus Focus");

  for (var i = 1; i <= Stat.modifiedMax; i++) {
    strength.update(i, (_) {});
    agility.update(i, (_) {});
    vitality.update(i, (_) {});
    intellect.update(i, (_) {});
    will.update(i, (_) {});

    print(
      " ${i.toString().padLeft(2)}:"
      " ${strength.tossRangeScale.toStringAsFixed(1).padLeft(3)}"
      " ${strength.heftScale(20).toStringAsFixed(2).padLeft(5)}"
      " ${agility.dodgeBonus.toString().padLeft(5)}"
      " ${agility.strikeBonus.toString().padLeft(6)}"
      " ${vitality.maxHealth.toString().padLeft(9)}"
      " ${intellect.maxFocus.toString().padLeft(8)}"
      " ${intellect.spellFocusScale(10).toStringAsFixed(2).padLeft(10)}"
      " ${will.damageFocusScale.toStringAsFixed(2).padLeft(5)}",
    );
  }
}
