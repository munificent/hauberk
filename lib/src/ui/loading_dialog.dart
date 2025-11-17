import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

/// Dialog shown while a new level is being generated.
class LoadingDialog extends Screen<Input> {
  final Game _game;
  final Iterator<String> _steps;
  int _frame = 0;

  @override
  bool get isTransparent => true;

  factory LoadingDialog(HeroSave save, Content content, int depth) {
    var game = Game(content, depth, save.clone());
    return LoadingDialog._(game, game.generate().iterator);
  }

  LoadingDialog._(this._game, this._steps);

  @override
  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop(false);
      return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.n:
        ui.pop(false);

      case KeyCode.y:
        ui.pop(true);
    }

    return true;
  }

  @override
  void update() {
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

  @override
  void render(Terminal terminal) {
    var width = 30;
    var height = 7;

    terminal = terminal.rect(
      (terminal.width - width) ~/ 2,
      (terminal.height - height) ~/ 2,
      width,
      height,
    );

    Draw.doubleBox(terminal, 0, 0, terminal.width, terminal.height, gold);

    terminal.writeAt(2, 2, "Entering dungeon...", UIHue.text);

    var offset = _frame ~/ 2;
    var bar = ("/    " * 6).substring(offset, offset + 26);
    terminal.writeAt(2, 4, bar, UIHue.primary);
  }
}
