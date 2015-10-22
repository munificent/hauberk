library hauberk.ui.game_over_screen;

import 'package:malison/malison.dart';

import '../engine.dart';
import 'input.dart';

class GameOverScreen extends Screen {
  final Log log;

  GameOverScreen(this.log);

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

    terminal.writeAt(0, 0, log.messages.last.text);
    terminal.writeAt(0, terminal.height - 1,
        '[Esc] Return to quest menu',
        Color.gray);
  }
}
