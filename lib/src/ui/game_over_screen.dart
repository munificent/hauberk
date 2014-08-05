library hauberk.ui.game_over_screen;

import 'package:malison/malison.dart';

import 'input.dart';

class GameOverScreen extends Screen {
  GameOverScreen();

  bool handleInput(Input input) {
    switch (input) {
    case Input.CANCEL:
      ui.pop();
      break;
    }

    return true;
  }

  void render(Terminal terminal) {
    terminal.clear();

    // TODO: Show more here. Explain what happens to your character.
    terminal.writeAt(0, 0, 'You have died.');
    terminal.writeAt(0, terminal.height - 1,
        '[Esc] Return to quest menu',
        Color.GRAY);
  }
}
