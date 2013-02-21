part of ui;

/// Modal dialog for letting the user confirm an action.
class ConfirmDialog extends Screen {
  final String message;
  final result;

  ConfirmDialog(this.message, this.result);

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
      case KeyCode.N:
        ui.pop(null);
        break;

      case KeyCode.Y:
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
