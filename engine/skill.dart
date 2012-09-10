/// Base class for a skill. A skill is a levelable hero ability in the game.
/// The actual concrete skills are defined in content.
class Skill {
  abstract String get name;
  Attack modifyAttack(int level, Attack attack) => attack;
}