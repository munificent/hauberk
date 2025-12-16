import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/ui/item/item_renderer.dart';

/// Shows various numbers around spending experience.
void main() {
  var content = createContent();

  // The cost to raise stats with various race modifiers at various amounts of
  // total stat points.
  var statCount = Stat.values.length;
  var scales = [
    for (var i = 0.7; i < 1.6; i += 0.1) i.toStringAsFixed(1).padLeft(12),
  ];
  print("Stat ${scales.join()}");
  print('-----${"  ----------" * 9}');
  for (
    var statTotal = 10 * statCount;
    statTotal <= Stat.baseMax * statCount;
    statTotal += statCount
  ) {
    var line = statTotal.toString().padLeft(4);
    line += ':  ';
    for (var raceScale = 0.7; raceScale < 1.6; raceScale += 0.1) {
      line += formatNumber(
        Stat.experienceCostAt(statTotal, raceScale),
      ).padLeft(10);
      line += '  ';
    }
    print(line);
  }

  print("");
  print("");

  // The cost to raise a skill with various base experience costs.
  var bases = [for (var i = 1000; i <= 10000; i += 1000) i];
  print("Skill  ${bases.map((b) => formatNumber(b).padLeft(10)).join('  ')}");
  print("-----${"  ----------" * 10}");
  for (var level = 1; level <= Skill.maxLevel; level++) {
    var line = "${level.toString().padLeft(4)}:";

    for (var baseExperience in bases) {
      var experience = Skill.experienceCostAt(baseExperience, level);
      line += "  ${formatNumber(experience).padLeft(10)}";
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
      '${race.name.padRight(8)}  '
      '${formatNumber(statExperience).padLeft(11)}',
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
      '${heroClass.name.padRight(12)}  '
      '${formatNumber(skillExperience).padLeft(11)}  '
      '${skills.toString().padLeft(6)}  '
      '${skillLevels.toString().padLeft(6)}',
    );
  }
}
