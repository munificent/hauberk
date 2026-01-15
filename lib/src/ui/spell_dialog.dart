import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../content.dart';
import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

// TODO: Get working with resizable UI.
/// Describe and learn spells.
class SpellDialog extends Screen<Input> {
  final Hero _hero;
  final List<({SpellSchool school, List<Spell> spells})> _schools = [];

  int _selectedSchool = 0;
  int _selectedSpellIndex = 0;

  Spell get _selectedSpell =>
      _schools[_selectedSchool].spells[_selectedSpellIndex];

  SpellDialog(Content content, this._hero) {
    // Categorize spells by their school.
    var spellsBySchool = <SpellSchool, List<Spell>>{};
    // TODO: Don't show spells the hero can never learn?
    for (var spell in content.spells) {
      spellsBySchool
          .putIfAbsent(spell.skill as SpellSchool, () => [])
          .add(spell);
    }

    spellsBySchool.forEach((school, spells) {
      _schools.add((school: school, spells: spells));
    });
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (alt) return false;

    switch (keyCode) {
      case KeyCode.tab:
        _changeSchool(shift ? -1 : 1);
        return true;

      case KeyCode.g:
        if (_hero.save.spellStatus(_selectedSpell) == SpellStatus.learnable) {
          _hero.save.learnedSpells.add(_selectedSpell);
          _hero.refreshProperties();
          dirty();
        }
        return true;

      default:
        return false;
    }
  }

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _changeSpell(-1);
        return true;
      case Input.s:
        _changeSpell(1);
        return true;

      // TODO: Use OK to confirm changes and cancel to discard them?
      case Input.cancel:
        ui.pop();
        return true;
    }

    return false;
  }

  @override
  void render(Terminal terminal) {
    terminal.clear();

    _renderSpellList(terminal.rect(0, 0, 40, terminal.height - 1));
    _renderSpell(
      terminal.rect(40, 0, terminal.width - 40, terminal.height - 1),
    );

    var message = switch (_hero.intellect.spellCount -
        _hero.save.learnedSpells.length) {
      <= 0 => "You can't learn any spells",
      1 => "You can learn 1 spell",
      var spells => "You can learn $spells spells",
    };

    Draw.helpKeys(terminal, {
      "Tab": "Next school",
      "↕": "Select spell",
      if (_hero.save.spellStatus(_selectedSpell) == SpellStatus.learnable)
        "G": "Learn spell",
      "`": "Exit",
    }, message);
  }

  void _renderSpellList(Terminal terminal) {
    const row = "───────────────────────────────── ───";

    var (:school, :spells) = _schools[_selectedSchool];
    Draw.frame(terminal, label: "${school.name} Spells");

    terminal.writeAt(36, 1, "Lvl", UIHue.helpText);
    terminal.writeAt(2, 2, row, darkCoolGray);

    var i = 0;
    for (var spell in spells) {
      var y = i * 2 + 3;
      terminal.writeAt(2, y + 1, row, darkerCoolGray);

      var (nameColor, levelColor) = switch (_hero.save.spellStatus(spell)) {
        _ when i == _selectedSpellIndex => (UIHue.selection, UIHue.selection),
        SpellStatus.known => (UIHue.primary, UIHue.text),
        SpellStatus.learnable => (UIHue.text, UIHue.text),
        SpellStatus.forgotten ||
        SpellStatus.notEnoughIntellect ||
        SpellStatus.notEnoughSchool => (UIHue.disabled, UIHue.disabled),
      };

      terminal.writeAt(2, y, spell.name, nameColor);
      terminal.writeAt(36, y, spell.spellLevel.fmt(w: 3), levelColor);

      i++;
    }

    terminal.drawChar(
      1,
      _selectedSpellIndex * 2 + 3,
      CharCode.blackRightPointingPointer,
      UIHue.selection,
    );
  }

  void _renderSpell(Terminal terminal) {
    var spell = _schools[_selectedSchool].spells[_selectedSpellIndex];
    Draw.frame(terminal, label: spell.name, labelSelected: true);

    _writeText(terminal, 1, 2, spell.description);

    var status = switch (_hero.save.spellStatus(spell)) {
      SpellStatus.known => "You know this spell.",
      SpellStatus.forgotten =>
        "You learned this spell but your intellect "
            "is currently too low to use it.",
      SpellStatus.notEnoughIntellect =>
        "You aren't smart enough to learn any more spells.",
      SpellStatus.notEnoughSchool =>
        "You aren't skilled enough in ${spell.skill.name} to learn this spell.",
      SpellStatus.learnable => "You can learn this spell.",
    };
    // TODO: Different colors.
    var y = 12;
    for (var line in Log.wordWrap(terminal.width - 2, status)) {
      terminal.writeAt(1, y++, line);
    }

    // TODO: Show spell level.
    terminal.writeAt(1, 32, "Focus cost:", UIHue.secondary);
    terminal.writeAt(
      13,
      32,
      spell.focusCost(_hero.save, 1).fmt(w: 3),
      UIHue.text,
    );
  }

  void _writeText(Terminal terminal, int x, int y, String text) {
    Draw.text(terminal, text, x: x, y: y, width: terminal.width - 1);
  }

  void _changeSchool(int offset) {
    _selectedSchool =
        (_selectedSchool + _schools.length + offset) % _schools.length;
    _selectedSpellIndex = 0;
    dirty();
  }

  void _changeSpell(int offset) {
    var spells = _schools[_selectedSchool].spells;
    _selectedSpellIndex =
        (_selectedSpellIndex + spells.length + offset) % spells.length;
    dirty();
  }
}
