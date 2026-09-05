import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';
import 'widget/draw.dart';

// TODO: Should this be a tab on the info screen instead? Need to decide if a
// user explicitly chooses to learn abilities or they are granted automatically
// when requirements are met. If the latter, then this can probably be an info
// screen. If the former, it should probably be on the experience dialog.

/// Describe abilities.
class AbilityDialog extends Screen<Input> {
  final Game _game;
  final List<Ability> _abilities = [];

  int _selectedAbilityIndex = 0;

  Ability get _selectedAbility => _abilities[_selectedAbilityIndex];

  AbilityDialog(this._game) {
    // TODO: Do something here if the abilities need to be sorted or categorized
    // somehow.
    _abilities.addAll(_game.content.abilities);
  }

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _changeAbility(-1);
      case Input.s:
        _changeAbility(1);
      case Input.cancel:
        ui.pop();
      default:
        return false;
    }

    return true;
  }

  @override
  void render(Terminal terminal) {
    terminal.clear();

    _renderAbilityList(terminal.rect(0, 0, 40, terminal.height - 1));
    _renderAbility(
      terminal.rect(40, 0, terminal.width - 40, terminal.height - 1),
    );

    Draw.helpKeys(terminal, {"↕": "Select ability", "`": "Exit"});
  }

  void _renderAbilityList(Terminal terminal) {
    const row = "─────────────────────────────── ─────";

    Draw.frame(terminal, label: "Abilities");

    terminal.writeAt(34, 1, "Focus", UIHue.header);
    terminal.writeAt(2, 2, row, UIHue.line);

    var i = 0;
    for (var ability in _abilities) {
      var y = i * 2 + 3;
      terminal.writeAt(2, y + 1, row, UIHue.rowSeparator);

      //   var (nameColor, levelColor) = switch (_hero.save.spellStatus(spell)) {
      //     _ when i == _selectedSpellIndex => (UIHue.highlight, UIHue.highlight),
      //     SpellStatus.known => (UIHue.selectable, UIHue.text),
      //     SpellStatus.learnable => (UIHue.selectable, UIHue.text),
      //     SpellStatus.forgotten ||
      //     SpellStatus.notEnoughIntellect ||
      //     SpellStatus.notEnoughSchool => (UIHue.disabled, UIHue.disabled),
      //   };

      var nameColor = i == _selectedAbilityIndex
          ? UIHue.highlight
          : UIHue.selectable;

      var focusColor = i == _selectedAbilityIndex
          ? UIHue.highlight
          : UIHue.text;

      terminal.writeAt(2, y, ability.name, nameColor);
      terminal.writeAt(
        34,
        y,
        ability.focusCost(_game.hero.save).fmt(w: 5),
        focusColor,
      );

      i++;
    }

    terminal.drawChar(
      1,
      _selectedAbilityIndex * 2 + 3,
      CharCode.blackRightPointingPointer,
      UIHue.highlight,
    );
  }

  void _renderAbility(Terminal terminal) {
    var ability = _selectedAbility;
    Draw.frame(terminal, label: ability.name, selected: true);

    _writeText(terminal, 1, 2, ability.description);

    // var status = switch (_hero.save.spellStatus(spell)) {
    //   SpellStatus.known => "You know this spell.",
    //   SpellStatus.forgotten =>
    //     "You learned this spell but your intellect "
    //         "is currently too low to use it.",
    //   SpellStatus.notEnoughIntellect =>
    //     "You aren't smart enough to learn any more spells.",
    //   SpellStatus.notEnoughSchool =>
    //     "You aren't skilled enough in ${spell.skill.name} to learn this spell.",
    //   SpellStatus.learnable => "You can learn this spell.",
    // };
    // // TODO: Different colors.
    // var y = 12;
    // y += Draw.text(terminal, status, x: 1, y: y, width: terminal.width - 2);

    // Show the requirements.
    terminal.writeAt(1, 10, "Requirements:", UIHue.header);
    var y = 12;
    for (var requirement in ability.requirements) {
      var (bulletColor, textColor) = requirement.check(_game) == null
          ? (sherwood, peaGreen)
          : (maroon, red);

      terminal.drawChar(1, y, CharCode.bullet, bulletColor);
      for (var line in Log.wordWrap(50, requirement.description)) {
        terminal.writeAt(3, y++, line, textColor);
      }

      y++;
    }

    terminal.writeAt(1, 32, "Focus cost:", UIHue.label);
    var focusCost = ability.focusCost(_game.hero.save).fmt(w: 3);
    terminal.writeAt(13, 32, focusCost, UIHue.text);
  }

  void _writeText(Terminal terminal, int x, int y, String text) {
    Draw.text(terminal, text, x: x, y: y, width: terminal.width - 1);
  }

  void _changeAbility(int offset) {
    _selectedAbilityIndex =
        (_selectedAbilityIndex + _abilities.length + offset) %
        _abilities.length;
    dirty();
  }
}
