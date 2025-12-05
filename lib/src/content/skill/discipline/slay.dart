import '../../../engine.dart';
import '../../monster/monsters.dart';
import 'discipline.dart';

class SlayDiscipline extends Discipline {
  // TODO: Tune.
  @override
  int get maxLevel => 20;

  final String _displayName;
  final String _breedGroup;

  // TODO: Implement description.
  @override
  String get description => "TODO: Implement description.";

  @override
  String get discoverMessage =>
      "{1} are eager to learn to slay ${_displayName.toLowerCase()}.";

  @override
  String get name => "Slay $_displayName";

  SlayDiscipline(this._displayName, this._breedGroup);

  double _damageScale(int level) => lerpDouble(level, 1, maxLevel, 1.05, 2.0);

  @override
  void seeBreed(Hero hero, Breed breed) {
    if (!Monsters.breeds.hasTag(breed.name, _breedGroup)) return;
    hero.discoverSkill(this);
  }

  @override
  void killMonster(Hero hero, Action action, Monster monster) {
    if (!Monsters.breeds.hasTag(monster.breed.name, _breedGroup)) return;

    hero.skills.earnPoints(this, (monster.experience / 1000).ceil());
    // TODO: Having to call this manually every place we call earnPoints()
    // is lame. Fix?
    hero.refreshSkill(this);
  }

  @override
  void modifyHit(
    Hero hero,
    Monster? monster,
    Item? weapon,
    Hit hit,
    int level,
  ) {
    if (monster == null) return;
    if (!Monsters.breeds.hasTag(monster.breed.name, _breedGroup)) return;

    // TODO: Tune.
    hit.scaleDamage(_damageScale(level), 'slay skill');
  }

  @override
  String levelDescription(int level) {
    var damage = ((_damageScale(level) - 1.0) * 100).toInt();
    return "Melee attacks inflict $damage% more damage against "
        "${_displayName.toLowerCase()}.";
  }

  // TODO: Tune.
  @override
  int baseTrainingNeeded(int level) => 100 * level * level * level;
}
