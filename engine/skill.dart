/// Base class for a skill. A skill is a levelable hero ability in the game.
/// The actual concrete skills are defined in content.
abstract class Skill {
  String get name;
  String getHelpText(int level);

  /// Override this to return `true` if the skill has an active use.
  bool get canUse => false;

  /// Override this to return `true` if the skill can be used but needs a
  /// target to do so.
  bool get needsTarget => false;

  num getAttackAddBonus(int level, Item weapon, Attack attack) => 0;
  num getAttackMultiplyBonus(int level, Item weapon, Attack attack) => 0;
  int modifyHealth(int level) => 0;
  int getDropChance(int level) => 0;

  /// Override this to create the [Action] that the [Hero] should perform when
  /// using this [Skill]. If the skill needs a target, one will be passed in.
  /// Otherwise, it will be `null`.
  Action getUseAction(int level, Game game, Vec target) {
    if (!canUse) throw 'This skill cannot be used.';
  }
}

/// The [Hero]'s levels in each skill.
class SkillSet {
  final Map<String, Skill> _skills;
  final Map<String, int> _levels;

  SkillSet(this._skills)
      : _levels = {};

  /// Gets the skills that the [Hero] is at least at level one at.
  Collection<Skill> get knownSkills =>
      _skills.getValues().filter((skill) => this[skill] > 0);

  /// Gets the hero's level at [skill].
  int operator[](Skill skill) {
    int level = _levels[skill.name];
    return level == null ? 0 : level;
  }

  /// Sets the hero's level at [skill].
  operator[]=(Skill skill, int level) {
    _levels[skill.name] = level;
  }

  /// Applies [callback] to every skill in the set.
  void forEach(void callback(Skill skill, int level)) {
    for (final skill in _skills.getValues()) callback(skill, this[skill]);
  }
}