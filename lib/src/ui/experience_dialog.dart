import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';
import 'widget/draw.dart';

// TODO: Can probably merge this with SkillDialog to have one general place to
// develop the hero.

/// UI to see and spend experience.
class ExperienceDialog extends Screen<Input> {
  final Hero _hero;
  final List<Skill> _skills;

  int _selectedIndex = 0;

  StatBase? get _selectedStat => switch (_selectedIndex) {
    0 => _hero.strength,
    1 => _hero.agility,
    2 => _hero.vitality,
    3 => _hero.intellect,
    _ => null,
  };

  Skill? get _selectedSkill {
    // On stats.
    if (_selectedIndex < Stat.values.length) return null;
    return _skills[_selectedIndex - Stat.values.length];
  }

  bool get _canRaise {
    if (_selectedStat case var stat?) {
      if (stat.baseValue == Stat.baseMax) return false;
      var cost = stat.experienceCost(_hero.save);
      return _hero.experience >= cost;
    } else if (_selectedSkill case var skill?) {
      var level = _hero.skills.level(skill);
      if (level == _hero.save.heroClass.skillCap(skill)) return false;
      var cost = skill.experienceCost(_hero.save, level + 1);
      return _hero.experience >= cost;
    } else {
      return false;
    }
  }

  ExperienceDialog(Content content, this._hero)
    : _skills = [
        for (var skill in content.skills)
          if (_hero.save.heroClass.skillCap(skill) > 0) skill,
      ];

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _changeSelection(-1);
        return true;
      case Input.s:
        _changeSelection(1);
        return true;

      // TODO: Use OK to confirm changes and cancel to discard them?
      case Input.cancel:
        // TODO: Save changes if in town.
        ui.pop();
        return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.g:
        if (_canRaise) {
          if (_selectedStat case var stat?) {
            _hero.experience -= stat.experienceCost(_hero.save);
            stat.refresh(_hero.save, stat.baseValue + 1);
          } else if (_selectedSkill case var skill?) {
            var level = _hero.skills.level(skill);
            _hero.experience -= skill.experienceCost(_hero.save, level + 1);
            _hero.skills.setLevel(skill, level + 1);
          }
          _hero.refreshProperties();
          dirty();
        }
        return true;
    }

    return false;
  }

  @override
  void render(Terminal terminal) {
    terminal.clear();

    Draw.frame(terminal, width: 40, height: 3);
    terminal.writeAt(2, 1, "Available experience:", UIHue.label);
    terminal.writeAt(31, 1, _hero.experience.fmt(w: 8), UIHue.text);

    _drawStatsList(terminal.rect(0, 3, 40, 11));
    _drawSkillsList(terminal.rect(0, 14, 40, terminal.height - 14));

    // Selected row cursor.
    terminal.drawChar(
      1,
      _selectedIndex * 2 + (_selectedIndex < Stat.values.length ? 6 : 9),
      CharCode.blackRightPointingPointer,
      UIHue.highlight,
    );

    var panelTerminal = terminal.rect(
      40,
      0,
      terminal.width - 40,
      terminal.height,
    );

    switch (_selectedIndex) {
      case 0:
        _drawStrengthPanel(panelTerminal);
      case 1:
        _drawAgilityPanel(panelTerminal);
      case 2:
        _drawVitalityPanel(panelTerminal);
      case 3:
        _drawIntellectPanel(panelTerminal);
      default:
        _drawSkillPanel(
          panelTerminal,
          _skills[_selectedIndex - Stat.values.length],
        );
    }

    Draw.helpKeys(terminal, {
      "↕": "Change selection",
      if (_canRaise) "G": "Gain ${_selectedStat != null ? "stat" : "skill"}",
      "`": "Exit",
    }, "You can spend ${_hero.experience.fmt()} experience");
  }

  void _drawStatsList(Terminal terminal) {
    Draw.frame(terminal, label: 'Stats');

    // Current value and cost to increment?
    terminal.writeAt(27, 1, "Val     Cost", UIHue.header);

    var stats = [
      _hero.strength,
      _hero.agility,
      _hero.vitality,
      _hero.intellect,
    ];

    var i = 0;
    for (var stat in stats) {
      _writeRow(
        terminal,
        i,
        stat.name,
        level: stat.value,
        maxLevel: Stat.baseMax,
        cost: stat.experienceCost(_hero.save),
        selected: i == _selectedIndex,
      );
      i++;
    }
  }

  void _drawSkillsList(Terminal terminal) {
    Draw.frame(terminal, label: 'Skills');

    // Current value and cost to increment?
    terminal.writeAt(27, 1, "Lvl     Cost", UIHue.header);

    var i = 0;
    for (var skill in _skills) {
      var level = _hero.skills.level(skill);
      _writeRow(
        terminal,
        i,
        skill.name,
        level: level,
        maxLevel: _hero.save.heroClass.skillCap(skill),
        cost: skill.experienceCost(_hero.save, level + 1),
        selected: i == _selectedIndex - Stat.values.length,
      );

      i++;
    }
  }

  void _writeRow(
    Terminal terminal,
    int i,
    String name, {
    required int level,
    required int maxLevel,
    required int cost,
    required bool selected,
  }) {
    var y = i * 2 + 3;

    terminal.writeAt(
      2,
      y - 1,
      "──────────────────────── ─── ────────",
      i == 0 ? UIHue.line : UIHue.rowSeparator,
    );

    var nameColor = switch (null) {
      _ when selected => UIHue.highlight,
      _ when level >= maxLevel || cost > _hero.experience => UIHue.disabled,
      _ => UIHue.selectable,
    };

    var infoColor = switch (null) {
      _ when selected => UIHue.highlight,
      _ when level >= maxLevel || cost > _hero.experience => UIHue.disabled,
      _ => UIHue.text,
    };

    terminal.writeAt(2, y, name, nameColor);
    terminal.writeAt(27, y, level.fmt(w: 3), infoColor);
    if (level < maxLevel) {
      terminal.writeAt(31, y, cost.fmt(w: 8), infoColor);
    } else {
      terminal.writeAt(31, y, " (Maxed)", infoColor);
    }
  }

  void _drawStrengthPanel(Terminal terminal) {
    _drawStatPanel(terminal, _hero.strength, ['Max Fury', 'Toss range scale'], (
      int value,
    ) {
      // TODO: Show weapon heft and armor weight somehow.
      return [
        Strength.maxFuryAt(value).toString(),
        Strength.tossRangeScaleAt(value).fmtPercent(),
      ];
    });
  }

  void _drawAgilityPanel(Terminal terminal) {
    _drawStatPanel(terminal, _hero.agility, ['Dodge bonus', 'Strike bonus'], (
      int value,
    ) {
      return [
        Agility.dodgeBonusAt(value).toString(),
        Agility.strikeBonusAt(value).toString(),
      ];
    });
  }

  void _drawVitalityPanel(Terminal terminal) {
    _drawStatPanel(terminal, _hero.vitality, ['Max health'], (int value) {
      return [Vitality.maxHealthAt(value).toString()];
    });
  }

  void _drawIntellectPanel(Terminal terminal) {
    _drawStatPanel(
      terminal,
      _hero.intellect,
      ['Max focus', 'Spells'],
      (int value) {
        return [
          Intellect.maxFocusAt(value).toString(),
          Intellect.spellCountAt(value).toString(),
        ];
      },
      // TODO: Show spell focus scale somehow.
    );
  }

  void _drawStatPanel(
    Terminal terminal,
    StatBase stat,
    List<String> labels,
    List<String> Function(int value) describe,
  ) {
    Draw.frame(terminal, label: stat.name);

    var currentValue = stat.value;
    // TODO: Would be good to show what is causing the modifiers.
    var modifiers = currentValue - stat.baseValue;

    var y = 2;
    terminal.writeAt(1, y, 'Base value:', UIHue.label);
    terminal.writeAt(15, y, stat.baseValue.fmt(w: 3), UIHue.text);
    y++;

    if (stat == _hero.strength) {
      var weightOffset = _hero.strength.weightOffset(_hero.save).toInt();
      modifiers = (currentValue - stat.baseValue + weightOffset);
      terminal.writeAt(1, y, 'Weight offset:', UIHue.label);
      terminal.writeAt(15, y, weightOffset.fmt(w: 3), UIHue.text);
      y++;
    }

    terminal.writeAt(1, y, 'Modifiers:', UIHue.label);
    terminal.writeAt(15, y, modifiers.fmt(w: 3), UIHue.text);
    y++;

    terminal.writeAt(1, y, 'Current value:', UIHue.label);
    terminal.writeAt(15, y, currentValue.fmt(w: 3), UIHue.text);

    y = 9;
    for (var label in labels) {
      terminal.writeAt(1, y, '$label:', UIHue.label);
      y++;
    }

    terminal.writeAt(24, 7, 'Current', UIHue.header);
    terminal.writeAt(24, 8, '───────', UIHue.line);
    y = 9;
    for (var value in describe(currentValue)) {
      terminal.writeAt(24, y, value.padLeft(7), UIHue.text);
      y++;
    }

    if (currentValue < Stat.baseMax) {
      var nextValue = currentValue + 1;
      terminal.writeAt(32, 7, '   Next', UIHue.header);
      terminal.writeAt(32, 8, '───────', UIHue.line);
      y = 9;
      for (var value in describe(nextValue)) {
        terminal.writeAt(32, y, value.padLeft(7), UIHue.text);
        y++;
      }
    }
  }

  void _drawSkillPanel(Terminal terminal, Skill skill) {
    Draw.frame(terminal, label: skill.name);
    var level = _hero.skills.level(skill);

    terminal.writeAt(1, 8, "At current level $level:", UIHue.label);
    if (level > 0) {
      Draw.text(
        terminal,
        x: 3,
        y: 10,
        width: terminal.width - 1,
        skill.levelDescription(level),
      );
    } else {
      terminal.writeAt(
        3,
        10,
        "(You haven't trained this yet.)",
        UIHue.disabled,
      );
    }

    var maxLevel = _hero.save.heroClass.skillCap(skill);
    if (level < maxLevel) {
      terminal.writeAt(1, 16, "At next level ${level + 1}:", UIHue.label);
      Draw.text(
        terminal,
        x: 3,
        y: 18,
        width: terminal.width - 1,
        skill.levelDescription(level + 1),
      );
    }

    if (maxLevel != 0) {
      terminal.writeAt(1, 30, "Level:", UIHue.label);
      terminal.writeAt(9, 30, level.fmt(w: 4), UIHue.text);
      Draw.meter(terminal, 14, 30, 25, level, maxLevel, red, maroon);
    }
  }

  void _changeSelection(int offset) {
    var length = Stat.values.length + _skills.length;
    _selectedIndex = (_selectedIndex + offset + length) % length;
    dirty();
  }
}
