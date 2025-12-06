import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../content.dart';
import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

// TODO: Merge this with ExperienceDialog or maybe turn it into SpellDialog?
// TODO: Get working with resizable UI.
abstract class SkillDialog extends Screen<Input> {
  // TODO: Make this a getter instead of a field.
  late final SkillDialog _nextScreen;

  factory SkillDialog(Content content, HeroSave hero) {
    var screens = [SpellDialog(content, hero)];

    for (var i = 0; i < screens.length; i++) {
      screens[i]._nextScreen = screens[(i + 1) % screens.length];
    }

    return screens.first;
  }

  SkillDialog._();

  String get _name;
}

abstract class SkillTypeDialog<T extends Skill> extends SkillDialog {
  final Content _content;
  final HeroSave _hero;
  final List<T> _skills = [];

  int _selectedSkill = 0;

  SkillTypeDialog(this._content, this._hero) : super._() {
    for (var skill in _content.skills) {
      if (skill is T) _skills.add(skill);
    }
  }

  Map<String, String> get _extraHelp => const {};

  // TODO: Eventually should clone skill set so we can cancel changes on dialog.
  SkillSet get _skillSet => _hero.skills;

  String get _rowSeparator;

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    if (keyCode == KeyCode.tab) {
      ui.goTo(_nextScreen);
      return true;
    }

    return false;
  }

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _changeSelection(-1);
        return true;
      case Input.s:
        _changeSelection(1);
        return true;

      // TODO: Get this working with spells, tricks, etc. that need to be
      // explicitly raised.
      //      case Input.e:
      //        if (!_canRaiseSkill) return false;
      //        _raiseSkill();
      //        return true;

      // TODO: Use OK to confirm changes and cancel to discard them?
      case Input.cancel:
        // TODO: Pass back updated skills for skills that are learned on this
        // screen.
        ui.pop();
        return true;
    }

    return false;
  }

  @override
  void render(Terminal terminal) {
    terminal.clear();

    _renderSkillList(terminal);
    _renderSkill(terminal);

    Draw.helpKeys(terminal, {
      ..._extraHelp,
      "Tab": "View ${_nextScreen._name}",
      "`": "Exit",
    });
  }

  void _renderSkillList(Terminal terminal) {
    terminal = terminal.rect(0, 0, 40, terminal.height - 1);

    Draw.frame(terminal, label: _name);

    _renderSkillListHeader(terminal);
    terminal.writeAt(2, 2, _rowSeparator, darkCoolGray);

    if (_skills.isEmpty) {
      terminal.writeAt(2, 3, "(None known.)", darkCoolGray);
      return;
    }

    var i = 0;
    for (var skill in _skills) {
      var y = i * 2 + 3;
      terminal.writeAt(2, y + 1, _rowSeparator, darkerCoolGray);

      var nameColor = UIHue.primary;
      var detailColor = UIHue.text;
      if (i == _selectedSkill) {
        nameColor = UIHue.selection;
        detailColor = UIHue.selection;
      } else if (_skillSet.level(skill) == 0) {
        nameColor = UIHue.disabled;
        detailColor = UIHue.disabled;
      }

      terminal.writeAt(2, y, skill.name, nameColor);

      _renderSkillInList(terminal, y, detailColor, skill);

      i++;
    }

    terminal.drawChar(
      1,
      _selectedSkill * 2 + 3,
      CharCode.blackRightPointingPointer,
      UIHue.selection,
    );
  }

  void _renderSkill(Terminal terminal) {
    terminal = terminal.rect(40, 0, terminal.width - 40, terminal.height - 1);

    if (_skills.isEmpty) {
      Draw.frame(terminal);
    } else {
      var skill = _skills[_selectedSkill];
      Draw.frame(terminal, label: skill.name, labelSelected: true);

      _writeText(terminal, 1, 2, skill.description);

      _renderSkillDetails(terminal, skill);
    }
  }

  void _writeText(Terminal terminal, int x, int y, String text) {
    Draw.text(terminal, text, x: x, y: y, width: terminal.width - 1);
  }

  void _renderSkillListHeader(Terminal terminal);

  void _renderSkillInList(Terminal terminal, int y, Color color, T skill);

  void _renderSkillDetails(Terminal terminal, T skill);

  void _changeSelection(int offset) {
    if (_skills.isEmpty) return;

    _selectedSkill = (_selectedSkill + offset).clamp(0, _skills.length - 1);
    dirty();
  }
}

class SpellDialog extends SkillTypeDialog<Spell> {
  @override
  String get _name => "Spells";

  @override
  String get _rowSeparator => "──────────────────────────────── ────";

  SpellDialog(super.content, super.hero);

  @override
  void _renderSkillListHeader(Terminal terminal) {
    terminal.writeAt(35, 1, "Comp", UIHue.helpText);
  }

  @override
  void _renderSkillInList(Terminal terminal, int y, Color color, Spell skill) {
    terminal.writeAt(
      35,
      y,
      skill.complexity(_hero.heroClass).toString().padLeft(4),
      color,
    );
  }

  @override
  void _renderSkillDetails(Terminal terminal, Spell skill) {
    terminal.writeAt(1, 30, "Complexity:", UIHue.secondary);
    if (_hero.skills.level(skill) > 0) {
      terminal.writeAt(
        13,
        30,
        skill.complexity(_hero.heroClass).toString().padLeft(3),
        UIHue.text,
      );
    } else {
      terminal.writeAt(
        13,
        30,
        skill.complexity(_hero.heroClass).toString().padLeft(3),
        red,
      );

      var need = skill.complexity(_hero.heroClass) - _hero.intellect.value;
      terminal.writeAt(17, 30, "Need $need more intellect", UIHue.secondary);
    }

    var level = _skillSet.level(skill);
    terminal.writeAt(1, 32, "Focus cost:", UIHue.secondary);
    terminal.writeAt(
      13,
      32,
      skill.focusCost(_hero, level).toString().padLeft(3),
      UIHue.text,
    );

    if (skill.damage != 0) {
      terminal.writeAt(1, 34, "Damage:", UIHue.secondary);
      terminal.writeAt(13, 34, skill.damage.toString().padLeft(3), UIHue.text);
    }

    if (skill.range != 0) {
      terminal.writeAt(1, 36, "Range:", UIHue.secondary);
      terminal.writeAt(13, 36, skill.range.toString().padLeft(3), UIHue.text);
    }
  }
}
