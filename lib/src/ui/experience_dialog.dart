import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';
import 'widget/draw.dart';

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
      var level = _hero.skills.baseLevel(skill);
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
            var level = _hero.skills.baseLevel(skill);
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

    const leftWidth = 46;
    Draw.frame(terminal, width: leftWidth, height: 3);
    terminal.writeAt(2, 1, "Available experience:", UIHue.label);
    terminal.writeAt(25, 1, _hero.experience.fmt(w: 9), UIHue.text);

    _drawStatsList(terminal.rect(0, 3, leftWidth, 11));
    _drawSkillsList(terminal.rect(0, 14, leftWidth, terminal.height - 14));

    // Selected row cursor.
    terminal.drawChar(
      1,
      _selectedIndex * 2 + (_selectedIndex < Stat.values.length ? 6 : 9),
      CharCode.blackRightPointingPointer,
      UIHue.highlight,
    );

    var panelTerminal = terminal.rect(
      leftWidth,
      0,
      terminal.width - leftWidth,
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
    terminal.writeAt(21, 1, "Base Equip Total    Cost", UIHue.header);

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
        baseValue: stat.baseValue,
        bonus: stat.value - stat.baseValue,
        fullValue: stat.value,
        maxValue: Stat.baseMax,
        cost: stat.experienceCost(_hero.save),
        selected: i == _selectedIndex,
      );
      i++;
    }
  }

  void _drawSkillsList(Terminal terminal) {
    Draw.frame(terminal, label: 'Skills');

    terminal.writeAt(21, 1, "Base Equip Total    Cost", UIHue.header);

    var i = 0;
    for (var skill in _skills) {
      var baseLevel = _hero.skills.baseLevel(skill);
      _writeRow(
        terminal,
        i,
        skill.name,
        baseValue: baseLevel,
        bonus: _hero.skills.bonus(skill),
        fullValue: _hero.skills.level(skill),
        maxValue: _hero.save.heroClass.skillCap(skill),
        cost: skill.experienceCost(_hero.save, baseLevel + 1),
        selected: i == _selectedIndex - Stat.values.length,
      );

      i++;
    }
  }

  void _writeRow(
    Terminal terminal,
    int i,
    String name, {
    required int baseValue,
    required int bonus,
    required int fullValue,
    required int maxValue,
    required int cost,
    required bool selected,
  }) {
    // Note that [fullValue] might not be [baseValue] + [bonus] because the
    // full value is clamped to the allowed range.

    var y = i * 2 + 3;

    terminal.writeAt(
      2,
      y - 1,
      "───────────────── ───── ───── ───── ───────",
      i == 0 ? UIHue.line : UIHue.rowSeparator,
    );

    var nameColor = switch (null) {
      _ when selected => UIHue.highlight,
      _ when baseValue >= maxValue || cost > _hero.experience => UIHue.disabled,
      _ => UIHue.selectable,
    };

    var infoColor = switch (null) {
      _ when selected => UIHue.highlight,
      _ when baseValue >= maxValue || cost > _hero.experience => UIHue.disabled,
      _ => UIHue.text,
    };

    terminal.writeAt(2, y, name, nameColor);
    terminal.writeAt(20, y, baseValue.fmt(w: 5), infoColor);

    var bonusColor = switch (bonus) {
      > 0 => peaGreen,
      < 0 => red,
      _ => UIHue.absent,
    };

    terminal.writeAt(26, y, bonus.fmt(w: 5, sign: true), bonusColor);

    terminal.writeAt(32, y, fullValue.fmt(w: 5), infoColor);

    if (baseValue < maxValue) {
      terminal.writeAt(38, y, cost.fmt(w: 7), infoColor);
    } else {
      terminal.writeAt(39, y, "At max", infoColor);
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
      var weightOffset = _hero.strength.weightOffset(_hero.save);
      modifiers = (currentValue - stat.baseValue - weightOffset);
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

    var baseLevel = _hero.skills.baseLevel(skill);
    var bonus = _hero.skills.bonus(skill);
    var fullLevel = _hero.skills.level(skill);
    var maxLevel = _hero.save.heroClass.skillCap(skill);

    terminal.writeAt(1, 2, "Base level:", UIHue.label);
    terminal.writeAt(13, 2, baseLevel.fmt(w: 2), UIHue.text);
    terminal.writeAt(16, 2, "/", UIHue.subtext);
    terminal.writeAt(18, 2, maxLevel.fmt(w: 2), UIHue.text);
    Draw.meter(terminal, 22, 2, 10, baseLevel, maxLevel, red, maroon);

    terminal.writeAt(1, 3, "Equipment:", UIHue.label);
    // TODO: Show individual equipment bonuses.
    terminal.writeAt(17, 3, bonus.fmt(w: 3, sign: true), UIHue.text);

    terminal.writeAt(1, 4, "Full level:", UIHue.label);
    terminal.writeAt(13, 4, fullLevel.fmt(w: 2), UIHue.text);
    terminal.writeAt(16, 4, "/", UIHue.subtext);
    terminal.writeAt(18, 4, Skill.modifiedMax.fmt(w: 2), UIHue.text);

    void describeLevel(String name, int level, int y) {
      Draw.hLine(terminal, 1, y, terminal.width - 2);
      terminal.writeAt(2, y, " At $name level $level ", UIHue.header);
      var (description, color) = switch (level) {
        > 0 => (skill.levelDescription(level), null),
        _ => ("You haven't learned this skill.", UIHue.disabled),
      };
      Draw.text(
        terminal,
        x: 1,
        y: y + 2,
        width: terminal.width - 1,
        description,
        color: color,
      );
    }

    describeLevel("current", fullLevel, 6);

    var nextLevel = (baseLevel + 1 + bonus).clamp(0, maxLevel);
    if (nextLevel < maxLevel) {
      describeLevel("next", nextLevel, 16);
    }
  }

  void _changeSelection(int offset) {
    var length = Stat.values.length + _skills.length;
    _selectedIndex = (_selectedIndex + offset + length) % length;
    dirty();
  }
}
