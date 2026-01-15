import '../../engine.dart';

class Bloodlust extends Skill {
  static double damageScaleAt(int level) {
    var levelFactor = lerpDouble(level, 1, Skill.maxLevel, 1.0, 4.0);

    // Normalize the fury scale so that if we tweak max fury, this mostly
    // shouldn't have to change.
    return 2.0 * levelFactor / Strength.maxFuryAt(Stat.modifiedMax);
  }

  @override
  String get description =>
      "The more furious you are, the more deadly in combat you become.";

  @override
  String get name => "Bloodlust";

  @override
  void modifyHit(
    Hero hero,
    Monster? monster,
    Item? weapon,
    Hit hit,
    int level,
  ) {
    hit.scaleDamage(damageScaleAt(level) * hero.fury, 'Bloodlust');
  }

  @override
  String levelDescription(int level) {
    var percent = damageScaleAt(level).fmtPercent(d: 1);
    return "Increases damage by $percent for each point of fury.";
  }
}
