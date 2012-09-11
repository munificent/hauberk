/// Builder class for defining [Skill]s.
class SkillBuilder extends ContentBuilder {
  final Map<String, Skill> _skills;

  SkillBuilder()
  : _skills = <String, Skill>{};

  Map<String, Skill> build() {
    skill(new CombatSkill());
    skill(new FakeSkill1());
    skill(new FakeSkill2());
    skill(new FakeSkill3());

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

class FakeSkill1 extends Skill {
  String get name => 'Fake One';
  Attack modifyAttack(int level, attack) {
    // One point of damage per level.
    return attack.modifyDamage(level);
  }
}

class FakeSkill2 extends Skill {
  String get name => 'Fake Two';
  Attack modifyAttack(int level, attack) {
    // One point of damage per level.
    return attack.modifyDamage(level);
  }
}

class FakeSkill3 extends Skill {
  String get name => 'Fake Three';
  Attack modifyAttack(int level, attack) {
    // One point of damage per level.
    return attack.modifyDamage(level);
  }
}