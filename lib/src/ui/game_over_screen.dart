import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import 'draw.dart';
import 'input.dart';

// TODO: Update to handle resizable UI.
class GameOverScreen extends Screen<Input> {
  final Log log;

  GameOverScreen(this.log);

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.cancel:
        ui.pop();
    }

    return true;
  }

  @override
  void render(Terminal terminal) {
    terminal.clear();
    terminal.writeAt(0, 0, log.messages.last.text);
    Draw.helpKeys(terminal, {'`': 'Try again'});
  }
}
