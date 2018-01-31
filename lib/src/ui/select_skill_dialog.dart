import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

// TODO: Would be good to show skill description and stuff here too.

class SelectSkillDialog extends Screen<Input> {
  final Game _game;
  final List<UsableSkill> _skills = [];

  bool get isTransparent => true;

  SelectSkillDialog(Game game) : _game = game {
    for (var skill in _game.hero.skills.acquired(_game.hero)) {
      if (skill is UsableSkill) _skills.add(skill);
    }
  }

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      selectCommand(keyCode - KeyCode.a);
      return true;
    }

    // TODO: Quick keys!
    return false;
  }

  void selectCommand(int index) {
    if (index >= _skills.length) return;
    if (_skills[index].unusableReason(_game) != null) return;

    ui.pop(_skills[index]);
  }

  void render(Terminal terminal) {
    // Draw a box for the contents.
    Draw.frame(terminal, 0, 0, 50, _skills.length + 3);

    terminal.writeAt(1, 0, "Perform which command?", UIHue.selection);

    for (var i = 0; i < _skills.length; i++) {
      var y = i + 2;
      var skill = _skills[i];

      var borderColor = UIHue.secondary;
      var letterColor = midnight;
      var textColor = UIHue.disabled;

      var reason = skill.unusableReason(_game);
      if (reason == null) {
        borderColor = UIHue.primary;
        letterColor = UIHue.selection;
        textColor = UIHue.selection;
      }

      terminal.writeAt(1, y, '( )   ', borderColor);
      terminal.writeAt(2, y, 'abcdefghijklmnopqrstuvwxyz'[i], letterColor);
      terminal.writeAt(5, y, skill.name, textColor);

      if (reason != null) {
        terminal.writeAt(25, y, "($reason)", textColor);
      }
    }

    terminal.writeAt(
        0,
        terminal.height - 1,
        '[A-Z] Select command, [1-9] Bind quick key, [Esc] Exit',
        UIHue.helpText);
  }
}
