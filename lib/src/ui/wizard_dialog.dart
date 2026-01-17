import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../content/tiles.dart';
import '../debug.dart';
import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

typedef _WizardAction = (String, int, String, void Function());

/// Cheat menu.
class WizardDialog extends Screen<Input> {
  final List<_WizardAction> _menuItems = [];
  final Game _game;

  /// Whether this dialog is on top or there is another one above it.
  bool _isActive = true;

  @override
  bool get isTransparent => true;

  WizardDialog(this._game) {
    _menuItems.addAll([
      ("m", KeyCode.m, "Map Dungeon", _mapDungeon),
      ("i", KeyCode.i, "Illuminate Dungeon", _illuminateDungeon),
      ("d", KeyCode.d, "Drop Item", _dropItem),
      ("s", KeyCode.s, "Spawn Monster", _spawnMonster),
      ("x", KeyCode.x, "Gain Experience", _gainExperience),
      ("k", KeyCode.k, "Kill All Monsters", _killAllMonsters),
      ("c", KeyCode.c, "Clear All Floor Items", _clearFloorItems),
      ("l", KeyCode.l, "Make Stairs", _makeStairs),
      ("o", KeyCode.o, "Toggle Show All Monsters", _toggleShowAllMonsters),
      ("a", KeyCode.a, "Toggle Show Monster Alertness", _toggleAlertness),
      ("v", KeyCode.v, "Toggle Show Hero Volume", _toggleShowHeroVolume),
    ]);
  }

  @override
  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    for (var (_, key, _, action) in _menuItems) {
      if (key == keyCode) {
        action();
        dirty();
        return true;
      }
    }

    return false;

    // TODO: Invoking a wizard command should mark the hero as a cheater.
  }

  @override
  void activate(Screen<Input> popped, Object? result) {
    _isActive = true;
  }

  @override
  void render(Terminal terminal) {
    // Draw a box for the contents.
    var width = 0;
    for (var (_, _, name, _) in _menuItems) {
      width = math.max(width, name.length);
    }

    Draw.frame(
      terminal,
      width: 40,
      height: _menuItems.length + 2,
      color: _isActive ? UIHue.selection : UIHue.disabled,
      label: "Wizard Menu",
      labelSelected: _isActive,
    );

    var i = 0;
    for (var (key, _, name, _) in _menuItems) {
      terminal.writeAt(
        1,
        i + 1,
        key,
        _isActive ? UIHue.selection : UIHue.disabled,
      );
      terminal.writeAt(
        2,
        i + 1,
        ")",
        _isActive ? UIHue.secondary : UIHue.disabled,
      );
      terminal.writeAt(
        4,
        i + 1,
        name,
        _isActive ? UIHue.primary : UIHue.disabled,
      );
      i++;
    }

    if (_isActive) Draw.helpKeys(terminal, {"`": "Exit"});
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

  void _dropItem() {
    _isActive = false;
    ui.push(_WizardDropDialog(_game));
  }

  void _spawnMonster() {
    _isActive = false;
    ui.push(_WizardSpawnDialog(_game));
  }

  void _gainExperience() {
    _game.hero.experience += 10000;
    _game.hero.refreshProperties();
  }

  void _killAllMonsters() {
    for (var monster in _game.stage.actors.toList()) {
      if (monster is! Monster) continue;
      _game.stage.placeDrops(
        monster.pos,
        monster.breed.drop,
        depth: monster.breed.depth,
      );
      _game.stage.removeActor(monster);
    }
  }

  void _clearFloorItems() {
    // Collect the items to clear first then remove them. We can't remove
    // items inside [forEachItem()] because that will concurrently modify the
    // item map.
    var items = <(Vec, Item)>[];
    _game.stage.forEachItem((item, pos) {
      items.add((pos, item));
    });

    for (var (pos, item) in items) {
      _game.stage.removeItem(item, pos);
    }
  }

  void _makeStairs() {
    _game.stage[_game.hero.pos].type = Tiles.stairs;
    _game.log.debug("Put stairs here");
  }

  void _toggleShowAllMonsters() {
    Debug.showAllMonsters = !Debug.showAllMonsters;
    _game.log.debug("Show all monsters = ${Debug.showAllMonsters}");
    ui.pop();
  }

  void _toggleAlertness() {
    Debug.showMonsterAlertness = !Debug.showMonsterAlertness;
    _game.log.debug("Show monster alertness = ${Debug.showMonsterAlertness}");
    ui.pop();
  }

  void _toggleShowHeroVolume() {
    Debug.showHeroVolume = !Debug.showHeroVolume;
    _game.log.debug("Show hero volume = ${Debug.showHeroVolume}");
    ui.pop();
  }
}

/// Base class for a dialog that searches for things by name.
abstract class _SearchDialog<T> extends Screen<Input> {
  final Game _game;
  String _pattern = "";

  _SearchDialog(this._game);

  @override
  bool get isTransparent => true;

  @override
  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
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
    }

    return false;
  }

  @override
  void render(Terminal terminal) {
    var dialog = terminal.rect(40, 0, 43, 38);

    // Draw a box for the contents.
    Draw.frame(dialog, label: _question, color: UIHue.selection);

    dialog.writeAt(_question.length + 4, 0, _pattern, UIHue.selection);
    dialog.writeAt(
      _question.length + 4 + _pattern.length,
      0,
      " ",
      UIHue.selection,
      UIHue.selection,
    );

    var n = 0;
    for (var item in _matchedItems) {
      if (!_itemName(item).toLowerCase().contains(_pattern.toLowerCase())) {
        continue;
      }

      if (n < 10) {
        dialog.writeAt(1, n + 1, n.toString(), UIHue.selection);
        dialog.writeAt(2, n + 1, ")", UIHue.disabled);
      }

      var appearance = _itemAppearance(item);
      if (appearance is Glyph) {
        dialog.drawGlyph(3, n + 1, appearance);
      } else {
        dialog.writeAt(3, n + 1, "-");
      }
      dialog.writeAt(5, n + 1, _itemName(item), UIHue.primary);

      n++;
      if (n >= 36) break;
    }

    Draw.helpKeys(terminal, {
      "0-9": "Select",
      "Enter": "Select all",
      "`": "Exit",
    });
  }

  List<T> get _matchedItems => _allItems
      .where(
        (item) =>
            _itemName(item).toLowerCase().contains(_pattern.toLowerCase()),
      )
      .toList();

  String get _question;

  Iterable<T> get _allItems;

  String _itemName(T item);

  Object? _itemAppearance(T item);

  void _selectItem(T item);
}

class _WizardDropDialog extends _SearchDialog<ItemType> {
  _WizardDropDialog(super.game);

  @override
  String get _question => "Drop what?";

  @override
  Iterable<ItemType> get _allItems => _game.content.items;

  @override
  String _itemName(ItemType item) => item.name;

  @override
  Object? _itemAppearance(ItemType item) => item.appearance;

  @override
  void _selectItem(ItemType itemType) {
    if (itemType.isArtifact) {
      _game.hero.lore.createArtifact(itemType);
    }

    var item = Item(itemType, itemType.maxStack);
    _game.stage.addItem(item, _game.hero.pos);
    _game.log.debug("Dropped {1}.", item);
  }
}

class _WizardSpawnDialog extends _SearchDialog<Breed> {
  _WizardSpawnDialog(super.game);

  @override
  String get _question => "Spawn what?";

  @override
  Iterable<Breed> get _allItems => _game.content.breeds;

  @override
  String _itemName(Breed breed) => breed.name;

  @override
  Object? _itemAppearance(Breed breed) => breed.appearance;

  @override
  void _selectItem(Breed breed) {
    var flow = MotilityFlow(_game.stage, _game.hero.pos, Motility.walk);
    var pos = flow.bestWhere((pos) => (pos - _game.hero.pos) > 6);
    if (pos == null) return;

    var monster = breed.spawn(pos);
    _game.stage.addActor(monster);
  }
}
