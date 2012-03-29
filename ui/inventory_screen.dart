
/// Modal dialog for letting the user select an item from the hero's inventory.
class InventoryDialog extends Screen {
  final Game game;

  InventoryDialog(this.game);

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
        ui.pop();
        break;

      case KeyCode.A: selectItem(0); break;
      case KeyCode.B: selectItem(1); break;
      case KeyCode.C: selectItem(2); break;
      case KeyCode.D: selectItem(3); break;
      case KeyCode.E: selectItem(4); break;
      case KeyCode.F: selectItem(5); break;
      case KeyCode.G: selectItem(6); break;
      case KeyCode.H: selectItem(7); break;
      case KeyCode.I: selectItem(8); break;
      case KeyCode.J: selectItem(9); break;
      case KeyCode.K: selectItem(10); break;
      case KeyCode.L: selectItem(11); break;
      case KeyCode.M: selectItem(12); break;
      case KeyCode.N: selectItem(13); break;
      case KeyCode.O: selectItem(14); break;
      case KeyCode.P: selectItem(15); break;
    }

    return true;
  }

  bool update() => false;

  void render(Terminal terminal) {
    terminal.writeAt(1, 1, 'Drop which item?');

    var i = 0;
    for (final item in game.hero.inventory) {
      final y = i + 3;
      terminal.writeAt(1, y, '( )', Color.GRAY);
      terminal.writeAt(2, y, 'abcdefghijklmnopqrstuvwxyz'[i], Color.YELLOW);
      terminal.drawGlyph(5, y, item.appearance);
      terminal.writeAt(7, y, item.nounText);
      i++;
    }
  }

  void selectItem(int index) {
    // TODO(bob): Just does drop. Eventually support other commands.
    if (index < game.hero.inventory.length) {
      game.hero.nextAction = new DropAction(index);
      ui.pop();
    }
  }
}
