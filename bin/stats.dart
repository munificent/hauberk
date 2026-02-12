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
      "  ${i.fmt(w: 2)}:"
      " ${strength.maxFury.fmt(w: 7)}"
      " ${strength.tossRangeScale.fmt(w: 3, d: 1)}"
      " ${strength.heftScale(20).fmt(w: 5, d: 2)}"
      " ${agility.dodgeBonus.fmt(w: 5)}"
      " ${agility.strikeBonus.fmt(w: 6)}"
      " ${vitality.maxHealth.fmt(w: 9)}"
      " ${intellect.maxFocus.fmt(w: 8)}"
      " ${intellect.spellCount.fmt(w: 6)}",
    );
  }

  print("");
  print("Bloodlust");
  var maxScale =
      Bloodlust.damageScaleAt(Skill.modifiedMax) *
      Strength.maxFuryAt(Stat.modifiedMax);

  for (var i = 1; i <= Stat.modifiedMax; i++) {
    strength.update(i, (_) {});

    var line = "${i.fmt(w: 2)}:";
    for (var level = 1; level <= Skill.modifiedMax; level++) {
      var scale = Bloodlust.damageScaleAt(level) * strength.maxFury;
      var bar = _makeBar(10, scale / maxScale);
      line += " ${(scale + 1.0).fmtPercent(w: 4, d: 0)} $bar";
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
  return bar.fmt(w: width);
}
