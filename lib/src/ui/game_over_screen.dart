import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';

class GameOverScreen extends Screen<Input> {
  final Log log;

  GameOverScreen(this.log);

  bool handleInput(Input input) {
    switch (input) {
      case Input.cancel:
        ui.pop();
        break;
    }

    return true;
  }

  void render(Terminal terminal) {
    terminal.clear();

    terminal.writeAt(0, 0, log.messages.last.text);
    terminal.writeAt(
        0, terminal.height - 1, '[Esc] Return to quest menu', UIHue.helpText);
  }
}
