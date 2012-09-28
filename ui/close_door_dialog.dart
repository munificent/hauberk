
/// Modal dialog for letting the user select an adjacent open door to close it.
class CloseDoorDialog extends Screen {
  final Game game;

  CloseDoorDialog(this.game);

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
        ui.pop();
        break;

      case KeyCode.I:         tryClose(Direction.NW); break;
      case KeyCode.O:         tryClose(Direction.N); break;
      case KeyCode.P:         tryClose(Direction.NE); break;
      case KeyCode.K:         tryClose(Direction.W); break;
      case KeyCode.SEMICOLON: tryClose(Direction.E); break;
      case KeyCode.COMMA:     tryClose(Direction.SW); break;
      case KeyCode.PERIOD:    tryClose(Direction.S); break;
      case KeyCode.SLASH:     tryClose(Direction.SE); break;
    }

    return true;
  }

  bool update() => false;

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, 'Close which door?');
  }

  void tryClose(Direction direction) {
    final pos = game.hero.pos + direction;
    if (game.stage[pos].type.closesTo != null) {
      game.hero.setNextAction(new CloseDoorAction(pos));
      ui.pop();
    } else {
      game.log.add('There is not an open door there.');
      dirty();
    }
  }
}
