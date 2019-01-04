import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

/// Dialog shown while a new level is being generated.
class LoadingDialog extends Screen<Input> {
  final Game _game;
  Iterator<String> _steps;
  int _frame = 0;

  bool get isTransparent => true;

  LoadingDialog(HeroSave save, Content content, int depth)
      : _game = Game(content, save.clone(), depth);

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop(false);
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.n:
        ui.pop(false);
        break;

      case KeyCode.y:
        ui.pop(true);
        break;
    }

    return true;
  }

  void update() {
    if (_steps == null) {
      _steps = _game.generate().iterator;
    }

    var stopwatch = Stopwatch()..start();

    while (stopwatch.elapsedMilliseconds < 16) {
      if (_steps.moveNext()) {
        dirty();
      } else {
        ui.pop(_game);
        return;
      }
    }

    _frame = (_frame + 1) % 10;
  }

  void render(Terminal terminal) {
    var width = 30;
    var height = 7;

    terminal = terminal.rect((terminal.width - width) ~/ 2,
        (terminal.height - height) ~/ 2, width, height);

    Draw.doubleBox(terminal, 0, 0, terminal.width, terminal.height, gold);

    terminal.writeAt(2, 2, "Entering dungeon...", UIHue.text);

    var offset = _frame ~/ 2;
    var bar = ("/    " * 6).substring(offset, offset + 26);
    terminal.writeAt(2, 4, bar, UIHue.primary);
  }
}
