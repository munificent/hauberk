import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';

/// Shows various numbers around spending experience.
void main() {
  var content = createContent();

  // The cost to raise stats with various race modifiers at various amounts of
  // total stat points.
  var statCount = Stat.values.length;
  var scales = [for (var i = 0.7; i < 1.6; i += 0.1) i.fmt(w: 12, d: 1)];
  print("Stat ${scales.join()}");
  print('-----${"  ----------" * 9}');
  for (
    var statTotal = 12 * statCount;
    statTotal <= Stat.baseMax * statCount;
    statTotal++
  ) {
    var line = statTotal.fmt(w: 4);
    line += ':  ';
    for (var raceScale = 0.7; raceScale < 1.6; raceScale += 0.1) {
      line += Stat.experienceCostAt(statTotal, raceScale).fmt(w: 10);
      line += '  ';
    }
    print(line);
  }

  print("");
  print("");

  // The cost to raise a skill with various base experience costs.
  var bases = [400, 600, 800, 1000, 1500, 2000, 3000, 5000];
  print("Skill  ${bases.map((b) => b.fmt(w: 10)).join('  ')}");
  print("-----${"  ----------" * 10}");
  for (var level = 1; level <= Skill.maxLevel; level++) {
    var line = "${level.fmt(w: 4)}:";

    for (var baseExperience in bases) {
      var experience = Skill.experienceCostAt(baseExperience, level);
      line += "  ${experience.fmt(w: 10)}";
    }
    print(line);
  }

  print("");
  print("");

  // Race affects stat gain experience cost, so show the totals for every race.
  print("Race          Stat XP");
  print("--------  -----------");
  for (var race in content.races) {
    var hero = content.createHero(
      "Fred",
      race: race,
      heroClass: content.classes.first,
    );

    var stats = [hero.strength, hero.agility, hero.vitality, hero.intellect];
    var statExperience = 0;
    for (var stat in stats) {
      while (stat.value < Stat.baseMax) {
        statExperience += stat.experienceCost(hero);
        stat.refresh(hero, stat.value + 1);
      }
    }

    print(
      '${race.name.fmt(w: 8)}  '
      '${statExperience.fmt(w: 11)}',
    );
  }

  print("");
  print("");

  // Class affects which skills can be learned and their maximum levels, so
  // show the total for each class.
  print("Class            Skill XP  Skills  Levels");
  print("------------  -----------  ------  ------");
  for (var heroClass in content.classes) {
    var hero = content.createHero(
      "Fred",
      race: content.races.first,
      heroClass: heroClass,
    );

    var skillExperience = 0;
    var skills = 0;
    var skillLevels = 0;
    for (var skill in content.skills) {
      var maxLevel = hero.heroClass.skillCap(skill);
      if (maxLevel > 0) {
        skills++;
        for (var level = 1; level <= maxLevel; level++) {
          skillExperience += skill.experienceCost(hero, level);
          hero.skills.setLevel(skill, level);
        }

        skillLevels += maxLevel;
      }
    }

    print(
      '${heroClass.name.fmt(w: 12)}  '
      '${skillExperience.fmt(w: 11)}  '
      '${skills.fmt(w: 6)}  '
      '${skillLevels.fmt(w: 6)}',
    );
  }
}
