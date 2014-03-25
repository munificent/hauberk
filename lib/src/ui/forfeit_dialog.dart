library dngn.ui.forfeit_dialog;

import '../engine.dart';
import 'keyboard.dart';
import 'screen.dart';
import 'terminal.dart';

/// Modal dialog for letting the user confirm forfeiting the level.
class ForfeitDialog extends Screen {
  final Game game;

  ForfeitDialog(this.game);

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
      case KeyCode.N:
        ui.pop(false);
        break;

      case KeyCode.Y:
        ui.pop(true);
        break;
    }

    return true;
  }

  bool update() => false;

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, 'Are you sure you want to forfeit the level? [Y]/[N]');
    terminal.writeAt(0, 1, 'You will lose all items and experience gained on the level.');
  }
}
