/// Builder class for defining [Skill]s.
class SkillBuilder extends ContentBuilder {
  final Map<String, Skill> _skills;

  SkillBuilder()
  : _skills = <String, Skill>{};

  Map<String, Skill> build() {
    skill(new CombatSkill());

    return _skills;
  }

  void skill(Skill skill) {
    _skills[skill.name] = skill;
  }
}

class CombatSkill extends Skill {
  String get name => 'Combat';
  Attack modifyAttack(int level, attack) {
    // One point of damage per level.
    return attack.modifyDamage(level);
  }
}