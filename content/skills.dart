/// Builder class for defining [Skill]s.
class SkillBuilder extends ContentBuilder {
  final Map<String, Skill> _skills;

  SkillBuilder()
  : _skills = <String, Skill>{};

  Map<String, Skill> build() {
    skill(new CombatSkill());
    skill(new StaminaSkill());

    return _skills;
  }

  void skill(Skill skill) {
    _skills[skill.name] = skill;
  }
}

class CombatSkill extends Skill {
  String get name => 'Combat';
  String getHelpText(int level) => 'Increases damage by $level.';

  Attack modifyAttack(int level, attack) {
    // One point of damage per level.
    return attack.modifyDamage(level);
  }
}

class StaminaSkill extends Skill {
  String get name => 'Stamina';
  String getHelpText(int level) => 'Increases max health by ${level * 2}.';

  int modifyHealth(int level) => level * 2;
}
