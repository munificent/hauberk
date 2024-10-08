import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'hero_equipment_dialog.dart';
import 'hero_item_lore_dialog.dart';
import 'hero_monster_lore_dialog.dart';
import 'hero_resistances_dialog.dart';
import 'input.dart';

// TODO: Fix this and its subscreens to work with the resizable UI.
abstract class HeroInfoDialog extends Screen<Input> {
  static final List<HeroInfoDialog> _screens = [];

  final Content content;
  final HeroSave hero;

  factory HeroInfoDialog(Content content, HeroSave hero) {
    if (_screens.isEmpty) {
      _screens.addAll([
        HeroEquipmentDialog(content, hero),
        HeroResistancesDialog(content, hero),
        HeroMonsterLoreDialog(content, hero),
        HeroItemLoreDialog(content, hero)
        // TODO: Affixes.
      ]);
    }

    return _screens.first;
  }

  HeroInfoDialog.base(this.content, this.hero);

  String get name;

  Map<String, String> get extraHelp => {};

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (alt) return false;

    if (keyCode == KeyCode.tab) {
      var index = _screens.indexOf(this);

      if (shift) {
        index += _screens.length - 1;
      } else {
        index++;
      }

      var screen = _screens[index % _screens.length];
      ui.goTo(screen);
      return true;
    }

    return false;
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
  void render(Terminal terminal) {
    var nextScreen = _screens[(_screens.indexOf(this) + 1) % _screens.length];
    Draw.helpKeys(terminal, {
      ...extraHelp,
      'Tab': 'View ${nextScreen.name}',
      '`': 'Exit',
    });
  }

  void drawEquipmentTable(
      Terminal terminal, void Function(Item? item, int y) callback) {
    terminal.writeAt(2, 1, "Equipment", gold);

    var y = 3;
    for (var i = 0; i < hero.equipment.slots.length; i++) {
      var item = hero.equipment.slots[i];
      callback(item, y);

      if (item == null) {
        terminal.writeAt(
            2, y, "(${hero.equipment.slotTypes[i]})", darkCoolGray);
        y += 2;
        continue;
      }

      terminal.drawGlyph(0, y, item.appearance as Glyph);
      terminal.writeAt(2, y, item.nounText, ash);

      y += 2;
    }
  }
}
