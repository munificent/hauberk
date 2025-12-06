import '../../../engine.dart';

/// Disciplines are the primary [Skill]s of warriors.
///
/// A discipline is "trained", which means to perform an in-game action related
/// to the discipline. For example, killing monsters with a sword trains the
/// Swordfighting discipline.
///
/// The underlying data used to track progress in disciplines is stored in the
/// hero's [Lore].
abstract class Discipline extends Skill {
  @override
  String gainMessage(int level) => "You have reached level $level in $name.";

  @override
  String get discoverMessage => "{1} can begin training in $name.";

  @override
  int onCalculateLevel(HeroSave hero, int points) {
    var training = hero.skills.points(this);
    for (var level = 1; level <= maxLevel; level++) {
      if (training < trainingNeeded(hero.heroClass, level)!) return level - 1;
    }

    return maxLevel;
  }

  /// How close the hero is to reaching the next level in this skill, in
  /// percent, or `null` if this skill is at max level.
  int? percentUntilNext(HeroSave hero) {
    var level = calculateLevel(hero);
    if (level == maxLevel) return null;

    var points = hero.skills.points(this);
    var current = trainingNeeded(hero.heroClass, level)!;
    var next = trainingNeeded(hero.heroClass, level + 1)!;
    return 100 * (points - current) ~/ (next - current);
  }

  /// How much training is needed for a hero of [heroClass] to reach [level],
  /// or `null` if the hero cannot train this skill.
  int? trainingNeeded(HeroClass heroClass, int level) {
    var profiency = heroClass.proficiency(this);
    if (profiency == 0.0) return null;

    return (baseTrainingNeeded(level) / profiency).ceil();
  }

  /// How much training is needed for to reach [level], ignoring class
  /// proficiency.
  int baseTrainingNeeded(int level);
}
