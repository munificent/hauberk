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

  LoadingDialog(this._save, Content content, int depth)
      : _game = new Game(content, _save, depth);

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

    if (_steps.moveNext()) {
      dirty();
    } else {
      ui.goTo(new GameScreen(_save, _game));
    }
  }

  void render(Terminal terminal) {
    terminal.writeAt(20, 18, 'Generating level...', UIHue.text);

    if (_steps != null) {
      terminal.fill(20, 20, 30, 1);
      terminal.writeAt(20, 20, _steps.current, UIHue.primary);
    }
  }
}
