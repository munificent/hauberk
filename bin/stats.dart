import 'package:hauberk/src/content/skill/bloodlust.dart';
import 'package:hauberk/src/engine.dart';

void main() {
  var strength = Strength();
  var agility = Agility();
  var vitality = Vitality();
  var intellect = Intellect();

  print("      Strength          Agility      Vitality  Intellect");
  print("      ┌───────────────┐ ┌──────────┐ ┌───────┐ ┌─────────────┐");
  print("Value MaxFury Toss Heft Dodge Strike MaxHealth MaxFocus Spells");

  for (var i = 1; i <= Stat.modifiedMax; i++) {
    strength.update(i, (_) {});
    agility.update(i, (_) {});
    vitality.update(i, (_) {});
    intellect.update(i, (_) {});

    print(
      "  ${i.toString().padLeft(2)}:"
      " ${strength.maxFury.toString().padLeft(7)}"
      " ${strength.tossRangeScale.toStringAsFixed(1).padLeft(3)}"
      " ${strength.heftScale(20).toStringAsFixed(2).padLeft(5)}"
      " ${agility.dodgeBonus.toString().padLeft(5)}"
      " ${agility.strikeBonus.toString().padLeft(6)}"
      " ${vitality.maxHealth.toString().padLeft(9)}"
      " ${intellect.maxFocus.toString().padLeft(8)}"
      " ${intellect.spellCount.toString().padLeft(6)}",
    );
  }

  print("");
  print("Bloodlust");
  var maxScale =
      Bloodlust.damageScaleAt(Skill.maxLevel) *
      Strength.maxFuryAt(Stat.modifiedMax);

  for (var i = 1; i <= Stat.modifiedMax; i++) {
    strength.update(i, (_) {});

    var line = "${i.toString().padLeft(2)}:";
    for (var level = 1; level <= Skill.maxLevel; level += 2) {
      var scale = Bloodlust.damageScaleAt(level) * strength.maxFury;
      var bar = _makeBar(10, scale / maxScale);
      line += " ${((scale + 1.0) * 100).toInt().toString().padLeft(4)}% $bar";
    }
    print(line);
  }
}

String _makeBar(int width, num value) {
  const solidBlock = "█";
  const chars = " ▏▎▍▌▋▊▉█";

  if (value >= 1.0) return solidBlock * width;

  var total = value.clamp(0.0, 1.0) * width;
  var solidChars = total.toInt();
  var fraction = (total - solidChars);
  var bar =
      solidBlock * solidChars +
      chars[(fraction * chars.length).toInt().clamp(0, chars.length - 1)];
  return bar.padRight(width);
}
