import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../debug.dart';
import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

/// Cheat menu.
class WizardDialog extends Screen<Input> {
  final Map<String, void Function()> _menuItems = {};
  final Game _game;

  bool get isTransparent => true;

  WizardDialog(this._game) {
    _menuItems["Map Dungeon"] = _mapDungeon;
    _menuItems["Illuminate Dungeon"] = _illuminateDungeon;
    _menuItems["Toggle Show All Monsters"] = _toggleShowAllMonsters;
    _menuItems["Toggle Show Monster Alertness"] = _toggleShowMonsterAlertness;
    _menuItems["Toggle Show Hero Volume"] = _toggleShowHeroVolume;
    _menuItems["Drop Item"] = _dropItem;
    _menuItems["Gain Level"] = _gainLevel;
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
    var width = _menuItems.keys
        .fold<int>(0, (width, name) => math.max(width, name.length));
    Draw.frame(terminal, 0, 0, width + 4, _menuItems.length + 3);
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
      for (var neighbor in pos.neighbors) {
        if (stage.bounds.contains(neighbor) && !stage[neighbor].blocksView) {
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
        stage[pos].addEmanation(255);
      }
    }

    stage.floorEmanationChanged();
    stage.refreshView();
  }

  void _toggleShowAllMonsters() {
    Debug.showAllMonsters = !Debug.showAllMonsters;
    _game.log.cheat("Show all monsters = ${Debug.showAllMonsters}");
    ui.pop();
  }

  void _toggleShowMonsterAlertness() {
    Debug.showMonsterAlertness = !Debug.showMonsterAlertness;
    _game.log.cheat("Show monster alertness = ${Debug.showMonsterAlertness}");
    ui.pop();
  }

  void _toggleShowHeroVolume() {
    Debug.showHeroVolume = !Debug.showHeroVolume;
    _game.log.cheat("Show hero volume = ${Debug.showHeroVolume}");
    ui.pop();
  }

  void _dropItem() {
    ui.push(WizardDropDialog(_game));
  }

  void _gainLevel() {
    if (_game.hero.level == Hero.maxLevel) {
      _game.log.cheat("Already at max level.");
    } else {
      _game.hero.experience = experienceLevelCost(_game.hero.level + 1);
      _game.hero.refreshProperties();
    }

    dirty();
  }
}

/// Cheat menu.
class WizardDropDialog extends Screen<Input> {
  final Game _game;
  String _pattern = "";

  WizardDropDialog(this._game);

  bool get isTransparent => true;

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (alt) return false;

    switch (keyCode) {
      case KeyCode.enter:
        for (var itemType in _matchedItems) {
          var item = Item(itemType, itemType.maxStack);
          _game.stage.addItem(item, _game.hero.pos);
          _game.log.cheat("Dropped {1}.", item);
        }

        ui.pop();
        return true;

      case KeyCode.delete:
        if (_pattern.isNotEmpty) {
          _pattern = _pattern.substring(0, _pattern.length - 1);
          dirty();
        }
        return true;

      case KeyCode.space:
        _pattern += " ";
        dirty();
        return true;

      default:
        if (keyCode == null) break;

        if (keyCode >= KeyCode.a && keyCode <= KeyCode.z ||
            keyCode >= KeyCode.zero && keyCode <= KeyCode.nine) {
          _pattern += String.fromCharCodes([keyCode]).toLowerCase();
          dirty();
          return true;
        }
        break;
    }

    return false;
  }

  void render(Terminal terminal) {
    // Draw a box for the contents.
    Draw.frame(terminal, 25, 0, 43, 39);
    terminal.writeAt(26, 0, "Drop what?", UIHue.selection);

    terminal.writeAt(26, 2, "Name:", UIHue.primary);
    terminal.writeAt(32, 2, _pattern, UIHue.selection);
    terminal.writeAt(
        32 + _pattern.length, 2, " ", UIHue.selection, UIHue.selection);

    var y = 4;
    for (var item in _matchedItems) {
      if (!item.name.toLowerCase().contains(_pattern.toLowerCase())) continue;

      terminal.drawGlyph(26, y, item.appearance as Glyph);
      terminal.writeAt(28, y, item.name, UIHue.primary);

      y++;
      if (y >= 38) break;
    }

    terminal.writeAt(
        0, terminal.height - 1, "[Return] Drop, [Esc] Exit", UIHue.helpText);
  }

  Iterable<ItemType> get _matchedItems => _game.content.items.where(
      (item) => item.name.toLowerCase().contains(_pattern.toLowerCase()));
}
