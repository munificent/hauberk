import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';
import '../input.dart';
import 'equipment_info_dialog.dart';
import 'item_lore_info_dialog.dart';
import 'monster_lore_info_dialog.dart';

// TODO: Fix this and its subscreens to work with the resizable UI.
abstract class InfoDialog extends Screen<Input> {
  static final List<InfoDialog> _screens = [];

  final Content content;
  final HeroSave hero;

  factory InfoDialog(Content content, HeroSave hero) {
    if (_screens.isEmpty) {
      _screens.addAll([
        EquipmentStatsInfoDialog(content, hero),
        EquipmentResistancesInfoDialog(content, hero),
        MonsterLoreInfoDialog(content, hero),
        ItemLoreInfoDialog(content, hero),
        // TODO: Affixes.
      ]);
    }

    return _screens.first;
  }

  InfoDialog.base(this.content, this.hero);

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
    // Draw the tabs.
    Draw.hLine(terminal, 0, 2, terminal.width, color: UIHue.text);

    var x = 2;
    for (var screen in _screens) {
      var tabWidth = screen.name.length;

      var tabColor = UIHue.disabled;
      var textColor = UIHue.disabled;
      if (screen == this) {
        tabColor = UIHue.text;
        textColor = UIHue.selection;
        terminal.writeAt(x, 2, "┘${' ' * tabWidth}└", UIHue.text);
      } else {
        terminal.writeAt(x, 2, "─${'─' * tabWidth}─", UIHue.text);
      }

      terminal.writeAt(x, 0, "┌${'─' * tabWidth}┐", tabColor);
      terminal.writeAt(x, 1, "│", tabColor);
      terminal.writeAt(x + tabWidth + 1, 1, "│", tabColor);
      terminal.writeAt(x + 1, 1, screen.name, textColor);

      x += tabWidth + 2;
    }

    renderInfo(terminal.rect(0, 3, terminal.width, terminal.height - 3));

    var nextScreen = _screens[(_screens.indexOf(this) + 1) % _screens.length];
    Draw.helpKeys(terminal, {
      ...extraHelp,
      'Tab': 'View ${nextScreen.name}',
      '`': 'Exit',
    });
  }

  void renderInfo(Terminal terminal);
}
