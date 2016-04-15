import 'package:malison/malison.dart';

import '../engine.dart';
import 'input.dart';

class SelectCommandDialog extends Screen<Input> {
  final Game _game;
  final List<Command> _commands;

  bool get isTransparent => true;

  SelectCommandDialog(Game game)
      : _game = game,
        _commands = game.hero.heroClass.commands;

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
    if (index < _commands.length) ui.pop(_commands[index]);
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, "Perform which command?");

    for (var i = 0; i < _commands.length; i++) {
      var y = i + 1;
      var command = _commands[i];

      terminal.writeAt(0, y, '( )   ', Color.gray);
      terminal.writeAt(1, y, 'abcdefghijklmnopqrstuvwxyz'[i], Color.yellow);
      terminal.writeAt(4, y, command.name);
    }

    terminal.writeAt(0, terminal.height - 1,
        '[A-Z] Select command, [1-9] Bind quick key, [Esc] Exit', Color.gray);
  }
}
