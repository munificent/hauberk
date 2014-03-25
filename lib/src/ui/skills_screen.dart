library dngn.ui.skills_screen;

import '../engine.dart';
import 'keyboard.dart';
import 'screen.dart';
import 'terminal.dart';

class SkillsScreen extends Screen {
  final Content  content;
  final HeroSave save;
  final List<Skill> skills;
  int selectedSkill = 0;

  SkillsScreen(this.content, this.save)
      : skills = [] {
    // Sort the skills.
    // TODO(bob): Would be cooler to show them in tree form based on prereqs.
    skills.addAll(content.skills.values);
    skills.sort((a, b) => a.name.compareTo(b.name));
  }

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.O:
        _changeSelection(-1);
        break;

      case KeyCode.PERIOD:
        _changeSelection(1);
        break;

      case KeyCode.K:
        final skill = skills[selectedSkill];
        if (save.skills[skill] > 0) {
          save.skills[skill]--;
          dirty();
        }
        break;

      case KeyCode.SEMICOLON:
        if (getSkillPoints() == 0) break;
        save.skills[skills[selectedSkill]]++;
        dirty();
        break;

      case KeyCode.ESCAPE:
        ui.pop();
        break;
    }

    return true;
  }

  void render(Terminal terminal) {
    terminal.clear();

    final skillPoints = getSkillPoints();
    terminal.writeAt(0, 0, 'You have $skillPoints skill points to spend.');

    for (int i = 0; i < skills.length; i++) {
      var fore = Color.WHITE;
      var back = Color.BLACK;
      if (i == selectedSkill) {
        fore = Color.BLACK;
        back = Color.YELLOW;
      }

      final skill = skills[i];
      terminal.writeAt(0, i + 2, skill.name, fore, back);
      terminal.writeAt(30, i + 2, save.skills[skill].toString(), fore, back);
    }

    final skill = skills[selectedSkill];
    terminal.writeAt(0, 20, 'Current level:');
    terminal.writeAt(0, 21, skill.getHelpText(save.skills[skill]));
    terminal.writeAt(0, 23, 'Next level:');
    terminal.writeAt(0, 24, skill.getHelpText(save.skills[skill] + 1));

    terminal.writeAt(0, terminal.height - 1,
        '[↕] Select skill, [↔] Modify skill, [Esc] Exit', Color.GRAY);
  }

  int getSkillPoints() {
    int pointsLeft = calculateLevel(save.experienceCents) * Option.SKILLS_PER_LEVEL;
    save.skills.forEach((name, level) => pointsLeft -= level);
    return pointsLeft;
  }

  _changeSelection(int offset) {
    selectedSkill = (selectedSkill + offset) % skills.length;
    dirty();
  }
}
