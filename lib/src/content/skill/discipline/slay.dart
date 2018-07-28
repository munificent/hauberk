import '../../../engine.dart';

class SlayDiscipline extends Discipline {
  // TODO: Tune.
  int get maxLevel => 20;

  final BreedGroup _group;

  // TODO: Implement description.
  String get description => "TODO: Implement description.";

  String get discoverMessage =>
      "{1} are eager to learn to slay ${_group.displayName.toLowerCase()}.";

  String get name => "Slay ${_group.displayName}";

  SlayDiscipline(this._group);

  double _damageScale(int level) => lerpDouble(level, 1, maxLevel, 1.05, 2.0);

  void killMonster(Hero hero, Action action, Monster monster) {
    if (!monster.breed.groups.contains(_group)) return;

    hero.skills.earnPoints(this, (monster.experienceCents / 1000).ceil());
    // TODO: Having to call this manually every place we call earnPoints()
    // is lame. Fix?
    hero.refreshSkill(this);
  }

  void modifyAttack(Hero hero, Monster monster, Hit hit, int level) {
    if (monster == null) return;

    if (!monster.breed.groups.contains(_group)) return;

    // TODO: Tune.
    hit.scaleDamage(_damageScale(level));
  }

  String levelDescription(int level) {
    var damage = ((_damageScale(level) - 1.0) * 100).toInt();
    return "Melee attacks inflict $damage% more damage against "
        "${_group.displayName.toLowerCase()}.";
  }

  // TODO: Tune.
  int baseTrainingNeeded(int level) => 100 * level * level * level;
}
