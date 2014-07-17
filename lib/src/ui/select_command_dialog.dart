library hauberk.ui.select_command_dialog;

import 'package:malison/malison.dart';

import '../engine.dart';

class SelectCommandDialog extends Screen {
  final Game _game;
  final List<Command> _commands;

  SelectCommandDialog(Game game)
      : _game = game,
        _commands = game.hero.heroClass.commands;

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
        ui.pop();
        break;

      case KeyCode.A: selectCommand(0); break;
      case KeyCode.B: selectCommand(1); break;
      case KeyCode.C: selectCommand(2); break;
      case KeyCode.D: selectCommand(3); break;
      case KeyCode.E: selectCommand(4); break;
      case KeyCode.F: selectCommand(5); break;
      case KeyCode.G: selectCommand(6); break;
      case KeyCode.H: selectCommand(7); break;
      case KeyCode.I: selectCommand(8); break;
      case KeyCode.J: selectCommand(9); break;
      case KeyCode.K: selectCommand(10); break;
      case KeyCode.L: selectCommand(11); break;
      case KeyCode.M: selectCommand(12); break;
      case KeyCode.N: selectCommand(13); break;
      case KeyCode.O: selectCommand(14); break;
      case KeyCode.P: selectCommand(15); break;
      case KeyCode.Q: selectCommand(16); break;
      case KeyCode.R: selectCommand(17); break;
      case KeyCode.S: selectCommand(18); break;
      case KeyCode.T: selectCommand(19); break;
      case KeyCode.U: selectCommand(20); break;
      case KeyCode.V: selectCommand(21); break;
      case KeyCode.W: selectCommand(22); break;
      case KeyCode.X: selectCommand(23); break;
      case KeyCode.Y: selectCommand(24); break;
      case KeyCode.Z: selectCommand(25); break;
    }

    // TODO: Quick keys!

    return true;
  }

  void selectCommand(int index) {
    if (index < _commands.length) ui.pop(_commands[index]);
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, "Perform which command?");

    for (var i = 0; i < _commands.length; i++) {
      var y = i + 1;
      var command = _commands[i];

      terminal.writeAt(0, y, '( )   ', Color.GRAY);
      terminal.writeAt(1, y, 'abcdefghijklmnopqrstuvwxyz'[i], Color.YELLOW);
      terminal.writeAt(4, y, command.name);
    }

    terminal.writeAt(0, terminal.height - 1,
        '[A-Z] Select command, [1-9] Bind quick key, [Esc] Exit', Color.GRAY);
  }
}
