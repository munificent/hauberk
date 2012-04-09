
/// Modal dialog for letting the user select an item from the hero's inventory.
class InventoryDialog extends Screen {
  final Game game;
  final InventoryMode mode;

  InventoryDialog(this.game, this.mode);

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

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, mode.message);

    var i = 0;
    for (final item in game.hero.inventory) {
      final y = i + 1;

      var borderColor = Color.GRAY;
      var letterColor = Color.YELLOW;
      var textColor = Color.WHITE;
      if (!mode.canSelect(item)) {
        borderColor = Color.DARK_GRAY;
        letterColor = Color.GRAY;
        textColor = Color.GRAY;
      }

      terminal.writeAt(0, y, '( )   ', borderColor);
      terminal.writeAt(1, y, 'abcdefghijklmnopqrstuvwxyz'[i], letterColor);
      terminal.drawGlyph(4, y, item.appearance);
      terminal.writeAt(6, y, item.nounText, textColor);
      i++;
    }
  }

  void selectItem(int index) {
    // TODO(bob): Just does drop. Eventually support other commands.
    if (index >= game.hero.inventory.length) return;
    if (!mode.canSelect(game.hero.inventory[index])) return;

    game.hero.setNextAction(mode.getAction(index));
    ui.pop();
  }
}

/// Actions that the user can perform on the inventory selection screen.
class InventoryMode {
  static final DROP = const DropInventoryMode();
  static final USE  = const UseInventoryMode();

  abstract String get message();
  abstract bool canSelect(Item item);
  abstract Action getAction(int index);

  const InventoryMode();
}

class DropInventoryMode extends InventoryMode {
  String get message() => 'Drop which item?';
  const DropInventoryMode() : super();

  bool canSelect(Item item) => true;
  Action getAction(int index) => new DropAction(index);
}

class UseInventoryMode extends InventoryMode {
  String get message() => 'Use or equip which item?';
  const UseInventoryMode() : super();

  bool canSelect(Item item) => item.canUse || item.canEquip;
  Action getAction(int index) => new UseAction(index);
}
