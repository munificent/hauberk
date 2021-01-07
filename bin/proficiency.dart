import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/content.dart';

/// Shows how proficiency affects skills for the various classes.
Content content;
Game game;

void main(List<String> arguments) {
  content = createContent();

  for (var heroClass in content.classes) {
    print(heroClass.name);
    for (var skill in content.skills) {
      String line = "";
      if (skill is Discipline) {
        for (var level = 1; level <= skill.maxLevel; level++) {
          var training = skill.trainingNeeded(heroClass, level);
          line += training.toString().padLeft(6);
        }
      } else if (skill is Spell) {
        if (heroClass.proficiency(skill) != 0.0) {
          var complexity = skill.complexity(heroClass);
          line = complexity.toString();
        } else {
          line = "N/A";
        }
      }

      print("  ${skill.name.padRight(20)} $line");
    }
  }
}
