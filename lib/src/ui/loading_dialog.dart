import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'game_screen.dart';
import 'input.dart';

/// Dialog shown while a new level is being generated.
class LoadingDialog extends Screen<Input> {
  final HeroSave _save;
  final Game _game;
  Iterator<String> _steps;
  int _frame = 0;

  LoadingDialog(this._save, Content content, int depth)
      : _game = Game(content, _save, depth);

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
        ui.goTo(GameScreen(_save, _game));
        return;
      }
    }

    _frame = (_frame + 1) % 10;
  }

  void render(Terminal terminal) {
    terminal.writeAt(30, 18, "Entering dungeon...", UIHue.text);

    var offset = _frame ~/ 2;
    var bar = ("/    " * 5).substring(offset, offset + 20);
    terminal.writeAt(30, 20, bar, UIHue.primary);
  }
}
