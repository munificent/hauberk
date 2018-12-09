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
    _menuItems["Drop Item"] = () {
      ui.push(_WizardDropDialog(_game));
    };
    _menuItems["Spawn Monster"] = () {
      ui.push(_WizardSpawnDialog(_game));
    };
    _menuItems["Gain Level"] = _gainLevel;

    _menuItems["Toggle Show All Monsters"] = () {
      Debug.showAllMonsters = !Debug.showAllMonsters;
      _game.log.cheat("Show all monsters = ${Debug.showAllMonsters}");
      ui.pop();
    };
    _menuItems["Toggle Show Monster Alertness"] = () {
      Debug.showMonsterAlertness = !Debug.showMonsterAlertness;
      _game.log.cheat("Show monster alertness = ${Debug.showMonsterAlertness}");
      ui.pop();
    };
    _menuItems["Toggle Show Hero Volume"] = () {
      Debug.showHeroVolume = !Debug.showHeroVolume;
      _game.log.cheat("Show hero volume = ${Debug.showHeroVolume}");
      ui.pop();
    };
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

/// Base class for a dialog that searches for things by name.
abstract class SearchDialog<T> extends Screen<Input> {
  final Game _game;
  String _pattern = "";

  SearchDialog(this._game);

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
        for (var item in _matchedItems) {
          _selectItem(item);
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
        if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
          _pattern += String.fromCharCodes([keyCode]).toLowerCase();
          dirty();
          return true;
        } else if (keyCode >= KeyCode.zero && keyCode <= KeyCode.nine) {
          var n = keyCode - KeyCode.zero;
          if (n < _matchedItems.length) {
            _selectItem(_matchedItems[n]);
            ui.pop();
            return true;
          }
        }
        break;
    }

    return false;
  }

  void render(Terminal terminal) {
    // Draw a box for the contents.
    Draw.frame(terminal, 25, 0, 43, 39);
    terminal.writeAt(26, 0, _question, UIHue.selection);

    terminal.writeAt(28 + _question.length, 0, _pattern, UIHue.selection);
    terminal.writeAt(28 + _question.length + _pattern.length, 0, " ",
        UIHue.selection, UIHue.selection);

    var n = 0;
    for (var item in _matchedItems) {
      if (!_itemName(item).toLowerCase().contains(_pattern.toLowerCase())) {
        continue;
      }

      if (n < 10) {
        terminal.writeAt(26, n + 2, n.toString(), UIHue.selection);
        terminal.writeAt(27, n + 2, ")", UIHue.disabled);
      }

      terminal.drawGlyph(28, n + 2, _itemAppearance(item) as Glyph);
      terminal.writeAt(30, n + 2, _itemName(item), UIHue.primary);

      n++;
      if (n >= 36) break;
    }

    terminal.writeAt(0, terminal.height - 1,
        "[0-9] Select, [Return] Select All, [Esc] Exit", UIHue.helpText);
  }

  List<T> get _matchedItems => _allItems
      .where((item) =>
          _itemName(item).toLowerCase().contains(_pattern.toLowerCase()))
      .toList();

  String get _question;

  Iterable<T> get _allItems;

  String _itemName(T item);

  Object _itemAppearance(T item);

  void _selectItem(T item);
}

class _WizardDropDialog extends SearchDialog<ItemType> {
  _WizardDropDialog(Game game): super(game);

  String get _question => "Drop what?";

  Iterable<ItemType> get _allItems => _game.content.items;

  String _itemName(ItemType item) => item.name;

  Object _itemAppearance(ItemType item) => item.name;

  void _selectItem(ItemType itemType) {
    var item = Item(itemType, itemType.maxStack);
    _game.stage.addItem(item, _game.hero.pos);
    _game.log.cheat("Dropped {1}.", item);
  }
}

class _WizardSpawnDialog extends SearchDialog<Breed> {
  _WizardSpawnDialog(Game game): super(game);

  String get _question => "Spawn what?";

  Iterable<Breed> get _allItems => _game.content.breeds;

  String _itemName(Breed breed) => breed.name;

  Object _itemAppearance(Breed breed) => breed.appearance;

  void _selectItem(Breed breed) {
    var flow = MotilityFlow(_game.stage, _game.hero.pos, Motility.walk);
    var pos = flow.bestWhere((pos) => (pos - _game.hero.pos) > 6);
    if (pos == null) return;

    var monster = breed.spawn(_game, pos);
    _game.stage.addActor(monster);
  }
}
