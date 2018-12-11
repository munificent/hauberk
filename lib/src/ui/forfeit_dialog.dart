import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import 'input.dart';

// TODO: Unify with ConfirmDialog.
/// Modal dialog for letting the user confirm forfeiting the level.
class ForfeitDialog extends Screen<Input> {
  final bool _isTown;

  bool get isTransparent => true;

  ForfeitDialog({bool isTown}) : _isTown = isTown ?? false;

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

  bool update() => false;

  void render(Terminal terminal) {
    if (_isTown) {
      terminal.writeAt(0, 0, "Return to main menu? [Y]/[N]");
    } else {
      terminal.writeAt(
          0, 0, "Are you sure you want to forfeit the level? [Y]/[N]");
      terminal.writeAt(
          0, 1, "You will lose all items and experience gained on the level.");
    }
  }
}
