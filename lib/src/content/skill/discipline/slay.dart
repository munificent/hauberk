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

  // TODO: The fact that this only counts kills and not the difficulty of the
  // monster means players are incentivized to grind weak monsters to raise
  // this. Is that OK?
  int trained(Lore lore) {
    var count = 0;

    for (var breed in lore.slainBreeds) {
      if (breed.groups.contains(_group)) {
        count += lore.slain(breed);
      }
    }

    return count;
  }

  // TODO: Tune.
  /// How much training is needed to reach [level].
  int baseTrainingNeeded(int level) => 10 * level * level;
}
