import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';

class SelectCommandDialog extends Screen<Input> {
  final Game _game;
  final List<Command> _commands = [];

  bool get isTransparent => true;

  SelectCommandDialog(Game game)
      : _game = game {
    for (var skill in _game.hero.skills.all) {
      var command = skill.command;
      if (command != null) _commands.add(command);
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
    if (index >= _commands.length) return;
    if (!_commands[index].canUse(_game)) return;

    ui.pop(_commands[index]);
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, "Perform which command?", UIHue.text);

    for (var i = 0; i < _commands.length; i++) {
      var y = i + 2;
      var command = _commands[i];

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
