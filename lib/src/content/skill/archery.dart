import '../../engine.dart';
import 'skills.dart';

class Archery extends Skill {
  static final Archery instance = Archery._();

  Archery._();

  @override
  String get name => "Archery";

  @override
  String get description =>
      "Kill your foe without risking harm to yourself by unleashing a volley "
      "of arrows from far away.";

  @override
  Domain get domain => Domains.archery;

  @override
  String levelDescription(int level) =>
      "Scales strike by ${_strikeScale(level).fmtPercent()}.";

  @override
  void modifyRangedHit(Hero hero, Item? weapon, Hit hit) {
    var level = hero.skills.level(this);
    if (weapon != null && weapon.type.weaponType == 'bow') {
      hit.scaleStrike(_strikeScale(level), 'archery');
    }
  }

  double _strikeScale(int level) =>
      lerpDouble(level, 1, Skill.modifiedMax, 1.0, 3.0);
}
