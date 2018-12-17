import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

// TODO: Get working with resizable UI.
abstract class SkillDialog extends Screen<Input> {
  SkillDialog _nextScreen;

  factory SkillDialog(HeroSave hero) {
    var screens = [
      DisciplineDialog(hero),
      SpellDialog(hero),
    ];

    for (var i = 0; i < screens.length; i++) {
      screens[i]._nextScreen = screens[(i + 1) % screens.length];
    }

    return screens.first;
  }

  SkillDialog._();

  String get _name;
}

abstract class SkillTypeDialog<T extends Skill> extends SkillDialog {
  final HeroSave _hero;
  final List<T> _skills = [];

  int _selectedSkill = 0;

  SkillTypeDialog(this._hero) : super._() {
    for (var skill in _hero.skills.discovered) {
      if (skill is T) _skills.add(skill);
    }
  }

  String get _extraHelp => null;

  // TODO: Eventually should clone skill set so we can cancel changes on dialog.
  SkillSet get _skillSet => _hero.skills;

  String get _rowSeparator;

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (keyCode == KeyCode.tab) {
      ui.goTo(_nextScreen);
      return true;
    }

    return false;
  }

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

  void render(Terminal terminal) {
    terminal.clear();

    _renderSkillList(terminal);
    _renderSkill(terminal);

    var helpText = '[Esc] Exit, [Tab] View ${_nextScreen._name}';
    if (_extraHelp != null) {
      helpText += ", $_extraHelp";
    }

    terminal.writeAt(0, terminal.height - 1, helpText, UIHue.helpText);
  }

  void _renderSkillList(Terminal terminal) {
    terminal = terminal.rect(0, 0, 40, terminal.height - 1);

    Draw.frame(terminal, 0, 0, terminal.width, terminal.height);
    terminal.writeAt(1, 0, _name, UIHue.text);

    _renderSkillListHeader(terminal);
    terminal.writeAt(2, 2, _rowSeparator, steelGray);

    if (_skills.isEmpty) {
      terminal.writeAt(2, 3, "(None known.)", steelGray);
      return;
    }

    var i = 0;
    for (var skill in _skills) {
      var y = i * 2 + 3;
      terminal.writeAt(2, y + 1, _rowSeparator, midnight);

      var nameColor = UIHue.primary;
      var detailColor = UIHue.text;
      if (i == _selectedSkill) {
        nameColor = UIHue.selection;
      } else if (!_skillSet.isAcquired(skill)) {
        nameColor = UIHue.disabled;
        detailColor = UIHue.disabled;
      }

      terminal.writeAt(2, y, skill.name, nameColor);

      _renderSkillInList(terminal, y, detailColor, skill);

      i++;
    }

    terminal.drawChar(1, _selectedSkill * 2 + 3,
        CharCode.blackRightPointingPointer, UIHue.selection);
  }

  void _renderSkill(Terminal terminal) {
    terminal = terminal.rect(40, 0, terminal.width - 40, terminal.height - 1);
    Draw.frame(terminal, 0, 0, terminal.width, terminal.height);

    if (_skills.isEmpty) return;

    var skill = _skills[_selectedSkill];
    terminal.writeAt(1, 0, skill.name, UIHue.selection);

    _writeText(terminal, 1, 2, skill.description);

    _renderSkillDetails(terminal, skill);
  }

  void _writeText(Terminal terminal, int x, int y, String text) {
    for (var line in Log.wordWrap(terminal.width - 1 - x, text)) {
      terminal.writeAt(x, y++, line, UIHue.text);
    }
  }

  void _renderSkillListHeader(Terminal terminal);

  void _renderSkillInList(Terminal terminal, int y, Color color, T skill);

  void _renderSkillDetails(Terminal terminal, T skill);

  void _changeSelection(int offset) {
    if (_skills.length == 0) return;

    _selectedSkill = (_selectedSkill + offset).clamp(0, _skills.length - 1);
    dirty();
  }
}

class DisciplineDialog extends SkillTypeDialog<Discipline> {
  DisciplineDialog(HeroSave hero) : super(hero);

  String get _name => "Disciplines";

  String get _rowSeparator => "──────────────────────────── ─── ────";

  void _renderSkillListHeader(Terminal terminal) {
    terminal.writeAt(31, 1, "Lev Next", UIHue.helpText);
  }

  void _renderSkillInList(
      Terminal terminal, int y, Color color, Discipline skill) {
    var level = _skillSet.level(skill).toString().padLeft(3);
    terminal.writeAt(31, y, level, color);

    var percent = skill.percentUntilNext(_hero);
    terminal.writeAt(
        35, y, percent == null ? "  --" : "$percent%".padLeft(4), color);
  }

  void _renderSkillDetails(Terminal terminal, Discipline skill) {
    var level = _skillSet.level(skill);

    terminal.writeAt(1, 8, "At current level $level:", UIHue.primary);
    if (level > 0) {
      _writeText(terminal, 3, 10, skill.levelDescription(level));
    } else {
      terminal.writeAt(
          3, 10, "(You haven't trained this yet.)", UIHue.disabled);
    }

    if (level < skill.maxLevel) {
      terminal.writeAt(1, 16, "At next level ${level + 1}:", UIHue.primary);
      _writeText(terminal, 3, 18, skill.levelDescription(level + 1));
    }

    terminal.writeAt(1, 30, "Level:", UIHue.secondary);
    terminal.writeAt(9, 30, level.toString().padLeft(4), UIHue.text);
    Draw.meter(terminal, 14, 30, 25, level, skill.maxLevel, brickRed, maroon);

    terminal.writeAt(1, 32, "Next:", UIHue.secondary);
    var percent = skill.percentUntilNext(_hero);
    if (percent != null) {
      var points = _hero.skills.points(skill);
      var current = skill.trainingNeeded(_hero.heroClass, level);
      var next = skill.trainingNeeded(_hero.heroClass, level + 1);
      terminal.writeAt(9, 32, "$percent%".padLeft(4), UIHue.text);
      Draw.meter(terminal, 14, 32, 25, points - current, next - current,
          brickRed, maroon);
    } else {
      terminal.writeAt(14, 32, "(At max level.)", UIHue.disabled);
    }
  }
}

class SpellDialog extends SkillTypeDialog<Spell> {
  String get _name => "Spells";

  String get _rowSeparator => "──────────────────────────────── ────";

  SpellDialog(HeroSave hero) : super(hero);

  void _renderSkillListHeader(Terminal terminal) {
    terminal.writeAt(35, 1, "Comp", UIHue.helpText);
  }

  void _renderSkillInList(Terminal terminal, int y, Color color, Spell skill) {
    terminal.writeAt(
        35, y, skill.complexity(_hero.heroClass).toString().padLeft(4), color);
  }

  void _renderSkillDetails(Terminal terminal, Spell skill) {
    terminal.writeAt(1, 30, "Complexity:", UIHue.secondary);
    if (_hero.skills.isAcquired(skill)) {
      terminal.writeAt(13, 30,
          skill.complexity(_hero.heroClass).toString().padLeft(3), UIHue.text);
    } else {
      terminal.writeAt(13, 30,
          skill.complexity(_hero.heroClass).toString().padLeft(3), brickRed);

      var need = skill.complexity(_hero.heroClass) - _hero.intellect.value;
      terminal.writeAt(17, 30, "Need $need more intellect", UIHue.secondary);
    }

    terminal.writeAt(1, 32, "Focus cost:", UIHue.secondary);
    terminal.writeAt(
        13, 32, skill.focusCost(_hero).toString().padLeft(3), UIHue.text);

    if (skill.damage != null) {
      terminal.writeAt(1, 34, "Damage:", UIHue.secondary);
      terminal.writeAt(13, 34, skill.damage.toString().padLeft(3), UIHue.text);
    }

    if (skill.range != null) {
      terminal.writeAt(1, 36, "Range:", UIHue.secondary);
      terminal.writeAt(13, 36, skill.range.toString().padLeft(3), UIHue.text);
    }
  }
}
