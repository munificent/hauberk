library hauberk.ui.game_over_screen;

import '../util.dart';
import 'keyboard.dart';
import 'screen.dart';
import 'terminal.dart';

class GameOverScreen extends Screen {
  GameOverScreen();

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
    case KeyCode.ESCAPE:
      ui.pop();
      break;
    }

    return true;
  }

  void render(Terminal terminal) {
    terminal.clear();

    // TODO(bob): Show more here. Explain what happens to your character.
    terminal.writeAt(0, 0, 'You have died.');
    terminal.writeAt(0, terminal.height - 1,
        '[Esc] Return to quest menu',
        Color.GRAY);
  }
}
