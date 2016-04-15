import 'package:malison/malison.dart';

import 'input.dart';

/// Modal dialog for letting the user confirm an action.
class ConfirmDialog extends Screen {
  final String message;
  final result;

  bool get isTransparent => true;

  ConfirmDialog(this.message, this.result);

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop(null);
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.n:
        ui.pop(null);
        break;

      case KeyCode.y:
        ui.pop(result);
        break;
    }

    return true;
  }

  bool update() => false;

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, '$message [Y]/[N]');
  }
}
