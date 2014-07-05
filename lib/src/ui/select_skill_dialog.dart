library dngn.ui.select_skill_dialog;

import '../engine.dart';
import '../util.dart';
import 'keyboard.dart';
import 'screen.dart';
import 'terminal.dart';

class SelectSkillDialog extends Screen {
  final Game _game;
  final List<Skill> _skills;

  SelectSkillDialog(Game game)
      : _game = game,
        _skills = game.hero.heroClass.skills;

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
        ui.pop();
        break;

      case KeyCode.A: selectSkill(0); break;
      case KeyCode.B: selectSkill(1); break;
      case KeyCode.C: selectSkill(2); break;
      case KeyCode.D: selectSkill(3); break;
      case KeyCode.E: selectSkill(4); break;
      case KeyCode.F: selectSkill(5); break;
      case KeyCode.G: selectSkill(6); break;
      case KeyCode.H: selectSkill(7); break;
      case KeyCode.I: selectSkill(8); break;
      case KeyCode.J: selectSkill(9); break;
      case KeyCode.K: selectSkill(10); break;
      case KeyCode.L: selectSkill(11); break;
      case KeyCode.M: selectSkill(12); break;
      case KeyCode.N: selectSkill(13); break;
      case KeyCode.O: selectSkill(14); break;
      case KeyCode.P: selectSkill(15); break;
      case KeyCode.Q: selectSkill(16); break;
      case KeyCode.R: selectSkill(17); break;
      case KeyCode.S: selectSkill(18); break;
      case KeyCode.T: selectSkill(19); break;
      case KeyCode.U: selectSkill(20); break;
      case KeyCode.V: selectSkill(21); break;
      case KeyCode.W: selectSkill(22); break;
      case KeyCode.X: selectSkill(23); break;
      case KeyCode.Y: selectSkill(24); break;
      case KeyCode.Z: selectSkill(25); break;
    }

    // TODO: Quick keys!

    return true;
  }

  void selectSkill(int index) {
    if (index < _skills.length) ui.pop(_skills[index]);
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, "Use which skill?");

    for (var i = 0; i < _skills.length; i++) {
      var y = i + 1;
      var skill = _skills[i];

      terminal.writeAt(0, y, '( )   ', Color.GRAY);
      terminal.writeAt(1, y, 'abcdefghijklmnopqrstuvwxyz'[i], Color.YELLOW);
      terminal.writeAt(4, y, skill.name);
    }

    terminal.writeAt(0, terminal.height - 1,
        '[A-Z] Select skill, [1-9] Bind quick key, [Esc] Exit', Color.GRAY);
  }
}
