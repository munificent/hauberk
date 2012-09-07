
/// Modal dialog for letting the user select an item from the hero's inventory.
class InventoryDialog extends Screen {
  final Game game;
  final InventoryMode mode;
  InventoryView view;

  InventoryDialog(this.game, this.mode)
      : view = InventoryView.INVENTORY;

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

      case KeyCode.TAB:
        view = view.next(mode.showGroundItems);
        dirty();
        break;
    }

    return true;
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, mode.message(view));

    terminal.rect(0, terminal.height - 2, terminal.width, 2).clear();
    terminal.writeAt(0, terminal.height - 1,
        '[A-P] Select item, [Tab] Switch view',
        Color.GRAY);

    drawItems(terminal, 0, 1, view.getItems(game),
        (item) => mode.canSelect(item));
  }

  void selectItem(int index) {
    if (index >= game.hero.inventory.length) return;
    if (!mode.canSelect(game.hero.inventory[index])) return;

    game.hero.setNextAction(mode.getAction(index, view));
    ui.pop();
  }
}

// TODO(bob): Move to different file?
drawItems(Terminal terminal, int x, int y, Iterable<Item> items,
    bool canSelect(Item item)) {
  var i = 0;
  for (final item in items) {
    final itemY = i + y;

    var borderColor = Color.GRAY;
    var letterColor = Color.YELLOW;
    var textColor = Color.WHITE;
    if (!canSelect(item)) {
      borderColor = Color.DARK_GRAY;
      letterColor = Color.GRAY;
      textColor = Color.GRAY;
    }

    terminal.writeAt(x, itemY, '( )   ', borderColor);
    terminal.writeAt(x + 1, itemY, 'abcdefghijklmnopqrstuvwxyz'[i], letterColor);
    terminal.drawGlyph(x + 4, itemY, item.appearance);
    terminal.writeAt(x + 6, itemY, item.nounText, textColor);
    i++;
  }
}

/// Which items are currently being shown in the inventory.
class InventoryView {
  static final INVENTORY = const InventoryView(0);
  static final EQUIPMENT = const InventoryView(1);
  static final GROUND    = const InventoryView(2);

  final int _value;

  const InventoryView(this._value);

  /// Gets the next inventory view, rotating through all three.
  InventoryView next(bool includeGround) {
    if (!includeGround) {
      if (this == InventoryView.INVENTORY) {
        return InventoryView.EQUIPMENT;
      } else {
        return InventoryView.INVENTORY;
      }
    }

    switch (this) {
      case InventoryView.INVENTORY: return InventoryView.EQUIPMENT;
      case InventoryView.EQUIPMENT: return InventoryView.GROUND;
      case InventoryView.GROUND: return InventoryView.INVENTORY;
    }

    assert(false); // Unreachable.
  }

  /// Gets the list of items for this view.
  Iterable<Item> getItems(Game game) {
    switch (this) {
      case InventoryView.INVENTORY: return game.hero.inventory;
      case InventoryView.EQUIPMENT: return game.hero.equipment;
      case InventoryView.GROUND: return game.level.itemsAt(game.hero.pos);
    }

    assert(false); // Unreachable.
  }
}

/// Actions that the user can perform on the inventory selection screen.
class InventoryMode {
  static final DROP = const DropInventoryMode();
  static final USE  = const UseInventoryMode();

  abstract String message(InventoryView view);
  bool get showGroundItems() => true;
  abstract bool canSelect(Item item);
  abstract Action getAction(int index, InventoryView view);

  const InventoryMode();
}

class DropInventoryMode extends InventoryMode {
  String message(InventoryView view) {
    switch (view) {
      case InventoryView.INVENTORY: return 'Drop which item?';
      case InventoryView.EQUIPMENT: return 'Unequip and drop which item?';
    }
  }

  bool get showGroundItems() => false;
  const DropInventoryMode() : super();

  bool canSelect(Item item) => true;
  Action getAction(int index, InventoryView view) {
    if (view == InventoryView.INVENTORY) return new DropInventoryAction(index);
    return new DropEquipmentAction(index);
  }
}

class UseInventoryMode extends InventoryMode {
  String message(InventoryView view) {
    switch (view) {
      case InventoryView.INVENTORY: return 'Use or equip which item?';
      case InventoryView.EQUIPMENT: return 'Unequip which item?';
      case InventoryView.GROUND: return 'Pick up and use which item?';
    }
  }

  const UseInventoryMode() : super();

  bool canSelect(Item item) => item.canUse || item.canEquip;
  Action getAction(int index, InventoryView view) {
    switch (view) {
      case InventoryView.INVENTORY: return new UseAction(index, false);
      case InventoryView.EQUIPMENT: return new UnequipAction(index);
      case InventoryView.GROUND: return new UseAction(index, true);
    }
  }
}
