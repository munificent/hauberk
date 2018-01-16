import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';

/// Cheat menu.
class WizardDialog extends Screen<Input> {
  final Map<String, void Function()> _menuItems = {};
  final Game _game;

  bool get isTransparent => true;

  WizardDialog(this._game) {
    _menuItems["Map dungeon"] = _mapDungeon;
    _menuItems["Illuminate dungeon"] = _illuminateDungeon;
  }

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    var index = keyCode - KeyCode.a;
    if (index < 0 || index >= _menuItems.length) return false;

    var menuItem = _menuItems[_menuItems.keys.elementAt(index)];
    menuItem();
    dirty();

    // TODO: Invoking a wizard command should mark the hero as a cheater.

    return true;
  }

  void render(Terminal terminal) {
    // Draw a box for the contents.
    var boxHeight = _menuItems.length + 2;
    var bar = "│" + (" " * 41) + "│";
    for (var y = 1; y < boxHeight + 1; y++) {
      terminal.writeAt(0, y, bar, steelGray);
    }

    terminal.writeAt(
        0, 0, "╒═════════════════════════════════════════╕", steelGray);
    terminal.writeAt(
        0, boxHeight, "└─────────────────────────────────────────┘", steelGray);

    terminal.writeAt(1, 0, "Wizard Menu", UIHue.selection);

    var i = 0;
    for (var menuItem in _menuItems.keys) {
      terminal.writeAt(1, i + 2, " )", UIHue.secondary);
      terminal.writeAt(
          1, i + 2, "abcdefghijklmnopqrstuvwxyz"[i], UIHue.selection);
      terminal.writeAt(3, i + 2, menuItem, UIHue.primary);

      i++;
    }

    terminal.writeAt(0, terminal.height - 1, "[Esc] Exit", UIHue.helpText);
  }

  void _mapDungeon() {
    var stage = _game.stage;
    for (var pos in stage.bounds) {
      // If the tile isn't opaque, explore it.
      if (!stage[pos].blocksView) {
        stage[pos].updateExplored(force: true);
        continue;
      }

      // If it is opaque, but it's next to a non-opaque tile (i.e. it's an edge
      // wall), explore it.
      for (var dir in Direction.all) {
        if (stage.bounds.contains(pos + dir) && !stage[pos + dir].blocksView) {
          stage[pos].updateExplored(force: true);
          break;
        }
      }
    }
  }

  void _illuminateDungeon() {
    var stage = _game.stage;
    for (var pos in stage.bounds) {
      // If the tile isn't opaque, explore it.
      if (!stage[pos].blocksView) {
        stage[pos].emanation = 255;
      }
    }

    stage.floorEmanationChanged();
    stage.refreshView();
  }
}
