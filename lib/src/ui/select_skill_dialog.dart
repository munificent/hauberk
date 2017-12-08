import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';

// TODO: Would be good to show skill description and stuff here too.

class SelectSkillDialog extends Screen<Input> {
  final Game _game;
  final List<UsableSkill> _skills = [];

  bool get isTransparent => true;

  SelectSkillDialog(Game game) : _game = game {
    for (var skill in _game.hero.skills.all) {
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
    if (!_skills[index].canUse(_game)) return;

    ui.pop(_skills[index]);
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, "Perform which command?", UIHue.text);

    for (var i = 0; i < _skills.length; i++) {
      var y = i + 2;
      var command = _skills[i];

      var borderColor = UIHue.secondary;
      var letterColor = midnight;
      var textColor = UIHue.disabled;

      if (command.canUse(_game)) {
        borderColor = UIHue.primary;
        letterColor = UIHue.selection;
        textColor = UIHue.selection;
      }

      terminal.writeAt(0, y, '( )   ', borderColor);
      terminal.writeAt(1, y, 'abcdefghijklmnopqrstuvwxyz'[i], letterColor);
      terminal.writeAt(4, y, command.name, textColor);
    }

    terminal.writeAt(
        0,
        terminal.height - 1,
        '[A-Z] Select command, [1-9] Bind quick key, [Esc] Exit',
        UIHue.helpText);
  }
}
