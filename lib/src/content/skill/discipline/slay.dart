import '../../../engine.dart';
import '../../monster/monsters.dart';

class SlayDiscipline extends Discipline {
  // TODO: Tune.
  int get maxLevel => 20;

  final String _displayName;
  final String _breedGroup;

  // TODO: Implement description.
  String get description => "TODO: Implement description.";

  String get discoverMessage =>
      "{1} are eager to learn to slay ${_displayName.toLowerCase()}.";

  String get name => "Slay $_displayName";

  SlayDiscipline(this._displayName, this._breedGroup);

  double _damageScale(int level) => lerpDouble(level, 1, maxLevel, 1.05, 2.0);

  void seeBreed(Hero hero, Breed breed) {
    if (!Monsters.breeds.hasTag(breed.name, _breedGroup)) return;
    hero.discoverSkill(this);
  }

  void killMonster(Hero hero, Action action, Monster monster) {
    if (!Monsters.breeds.hasTag(monster.breed.name, _breedGroup)) return;

    hero.skills.earnPoints(this, (monster.experience / 1000).ceil());
    // TODO: Having to call this manually every place we call earnPoints()
    // is lame. Fix?
    hero.refreshSkill(this);
  }

  void modifyAttack(Hero hero, Monster monster, Hit hit, int level) {
    if (monster == null) return;

    if (!Monsters.breeds.hasTag(monster.breed.name, _breedGroup)) return;

    // TODO: Tune.
    hit.scaleDamage(_damageScale(level));
  }

  String levelDescription(int level) {
    var damage = ((_damageScale(level) - 1.0) * 100).toInt();
    return "Melee attacks inflict $damage% more damage against "
        "${_displayName.toLowerCase()}.";
  }

  // TODO: Tune.
  int baseTrainingNeeded(int level) => 100 * level * level * level;
}
