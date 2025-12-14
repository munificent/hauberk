import 'package:hauberk/src/engine.dart';

void main() {
  var strength = Strength();
  var agility = Agility();
  var vitality = Vitality();
  var intellect = Intellect();

  print("      Strength   Agility     Vitality  Intellect");
  print("      ┌───────┐ ┌──────────┐ ┌───────┐ ┌─────────────┐");
  print("Value Toss Heft Dodge Strike MaxHealth MaxFocus Spells");

  for (var i = 1; i <= Stat.modifiedMax; i++) {
    strength.update(i, (_) {});
    agility.update(i, (_) {});
    vitality.update(i, (_) {});
    intellect.update(i, (_) {});

    print(
      "  ${i.toString().padLeft(2)}:"
      " ${strength.tossRangeScale.toStringAsFixed(1).padLeft(3)}"
      " ${strength.heftScale(20).toStringAsFixed(2).padLeft(5)}"
      " ${agility.dodgeBonus.toString().padLeft(5)}"
      " ${agility.strikeBonus.toString().padLeft(6)}"
      " ${vitality.maxHealth.toString().padLeft(9)}"
      " ${intellect.maxFocus.toString().padLeft(8)}"
      " ${intellect.spellCount.toString().padLeft(6)}",
    );
  }
}
