import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';

/// Estimates how many monsters need to be killed to reach each experience
/// level.
main() {
  var strength = Strength();
  var agility = Agility();
  var fortitude = Fortitude();
  var intellect = Intellect();
  var will = Will();

  var save = createContent().createHero("Blah");
  strength.bindHero(save);
  agility.bindHero(save);
  fortitude.bindHero(save);
  intellect.bindHero(save);
  will.bindHero(save);

  print("     Strength   Agility     Fortitude Intellect Will");
  print("     ┌───────┐ ┌──────────┐ ┌───────┐ ┌───────┐ ┌──┐");
  print("Lvl  Toss Heft Dodge Strike Health    Focus");

  for (var i = 1; i <= Stat.max; i++) {
    strength.update(i, (_) {});
    agility.update(i, (_) {});
    fortitude.update(i, (_) {});
    intellect.update(i, (_) {});
    will.update(i, (_) {});

    print(" ${i.toString().padLeft(2)}:"
        " ${strength.tossRangeScale.toStringAsFixed(1).padLeft(3)}"
        " ${strength.heftScale(20, 1).toStringAsFixed(2).padLeft(5)}"
        " ${agility.dodgeBonus.toString().padLeft(5)}"
        " ${agility.strikeBonus.toString().padLeft(6)}"
        " ${fortitude.maxHealth.toString().padLeft(6)}"
        "   ${intellect.maxFocus.toString().padLeft(6)}");
  }
}
