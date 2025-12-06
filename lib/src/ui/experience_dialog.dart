import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

// TODO: Can probably merge this with SkillDialog to have one general place to
// develop the hero.

/// UI to see and spend experience.
class ExperienceDialog extends Screen<Input> {
  final Content _content;
  final HeroSave _hero;

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
    return _content.skills[_selectedIndex - Stat.values.length];
  }

  bool get _canRaise {
    if (_selectedStat case var stat?) {
      var cost = stat.experienceCost(_hero);
      return cost != null && _hero.experience >= cost;
    } else {
      // TODO: Implement leveling skills.
      return false;
    }
  }

  ExperienceDialog(this._content, this._hero);

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
      case KeyCode.r:
        if (_canRaise) {
          if (_selectedStat case var stat?) {
            _hero.experience -= stat.experienceCost(_hero)!;
            stat.refresh(_hero, stat.baseValue + 1);
          } else {
            // TODO: Implement raising skill levels.
          }
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
    terminal.writeAt(2, 1, "Available experience", UIHue.text);
    terminal.writeAt(
      31,
      1,
      _hero.experience.toString().padLeft(8),
      UIHue.primary,
    );

    _drawStatsList(terminal.rect(0, 3, 40, 11));
    _drawSkillsList(terminal.rect(0, 14, 40, terminal.height - 14));

    // Selected row cursor.
    terminal.drawChar(
      1,
      _selectedIndex * 2 + (_selectedIndex < Stat.values.length ? 6 : 9),
      CharCode.blackRightPointingPointer,
      UIHue.selection,
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
          _content.skills[_selectedIndex - Stat.values.length],
        );
    }

    Draw.helpKeys(terminal, {
      "↕": "Change selection",
      if (_selectedStat case var stat? when _canRaise)
        "R": "Raise ${stat.name}",
      if (_selectedSkill case var skill? when _canRaise)
        "R": "Raise ${skill.name}",
      "`": "Exit",
    }, "You can spend ${_hero.experience} experience");
  }

  void _drawStatsList(Terminal terminal) {
    Draw.frame(terminal, label: 'Stats');

    var separator = "──────────────────────── ─── ────────";

    // Current value and cost to increment?
    terminal.writeAt(27, 1, "Val     Cost", UIHue.helpText);

    var stats = [
      _hero.strength,
      _hero.agility,
      _hero.vitality,
      _hero.intellect,
    ];

    var i = 0;
    for (var stat in stats) {
      var y = i * 2 + 3;
      terminal.writeAt(
        2,
        y - 1,
        separator,
        stat == stats.first ? darkCoolGray : darkerCoolGray,
      );

      var color = UIHue.primary;
      if (i == _selectedIndex) {
        color = UIHue.selection;
      }

      terminal.writeAt(2, y, stat.name, color);
      terminal.writeAt(27, y, stat.value.toString().padLeft(3), color);
      if (stat.experienceCost(_hero) case var cost?) {
        terminal.writeAt(
          31,
          y,
          cost.toString().padLeft(8),
          cost <= _hero.experience ? color : UIHue.disabled,
        );
      } else {
        terminal.writeAt(31, y, '(at max)', UIHue.disabled);
      }

      i++;
    }
  }

  void _drawSkillsList(Terminal terminal) {
    Draw.frame(terminal, label: 'Skills');

    var separator = "──────────────────────── ─── ────────";

    // Current value and cost to increment?
    terminal.writeAt(27, 1, "Lvl     Cost", UIHue.helpText);

    var i = 0;
    for (var skill in _content.skills) {
      var y = i * 2 + 3;
      terminal.writeAt(
        2,
        y - 1,
        separator,
        i == 0 ? darkCoolGray : darkerCoolGray,
      );

      var nameColor = UIHue.primary;
      var detailColor = UIHue.text;
      if (i == _selectedIndex - Stat.values.length) {
        nameColor = UIHue.selection;
        detailColor = UIHue.selection;
      }

      terminal.writeAt(2, y, skill.name, nameColor);
      var level = _hero.skills.level(skill);
      terminal.writeAt(27, y, level.toString().padLeft(3), detailColor);
      var cost = skill.experienceCost(_hero, level + 1);
      terminal.writeAt(
        31,
        y,
        cost.toString().padLeft(8),
        cost <= _hero.experience ? detailColor : UIHue.disabled,
      );

      i++;
    }
  }

  void _drawStrengthPanel(Terminal terminal) {
    _drawStatPanel(terminal, _hero.strength, ['Max Fury', 'Toss range scale'], (
      int value,
    ) {
      var tossPercent = '${(Strength.tossRangeScaleAt(value) * 100).toInt()}%';
      // TODO: Show weapon heft and armor weight somehow.
      return [Strength.maxFuryAt(value).toString(), tossPercent];
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
      ['Max focus'],
      (int value) {
        return [Intellect.maxFocusAt(value).toString()];
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
    Draw.frame(terminal, label: stat.name, labelSelected: true);

    var currentValue = stat.value;
    // TODO: Would be good to show what is causing the modifiers.
    var modifiers = currentValue - stat.baseValue;

    var y = 2;
    terminal.writeAt(1, y, 'Base value:', UIHue.secondary);
    terminal.writeAt(15, y, stat.baseValue.toString().padLeft(3), UIHue.text);
    y++;

    if (stat == _hero.strength) {
      var weightOffset = _hero.strength.weightOffset(_hero).toInt();
      modifiers = (currentValue - stat.baseValue + weightOffset);
      terminal.writeAt(1, y, 'Weight offset:', UIHue.secondary);
      terminal.writeAt(15, y, weightOffset.toString().padLeft(3), UIHue.text);
      y++;
    }

    terminal.writeAt(1, y, 'Modifiers:', UIHue.secondary);
    terminal.writeAt(15, y, modifiers.toString().padLeft(3), UIHue.text);
    y++;

    terminal.writeAt(1, y, 'Current value:', UIHue.secondary);
    terminal.writeAt(15, y, currentValue.toString().padLeft(3), UIHue.primary);

    y = 9;
    for (var label in labels) {
      terminal.writeAt(1, y, '$label:', UIHue.secondary);
      y++;
    }

    terminal.writeAt(24, 7, 'Current', UIHue.text);
    terminal.writeAt(24, 8, '───────', UIHue.secondary);
    y = 9;
    for (var value in describe(currentValue)) {
      terminal.writeAt(24, y, value.padLeft(7));
      y++;
    }

    if (currentValue < Stat.baseMax) {
      var nextValue = currentValue + 1;
      terminal.writeAt(32, 7, '   Next', UIHue.text);
      terminal.writeAt(32, 8, '───────', UIHue.secondary);
      y = 9;
      for (var value in describe(nextValue)) {
        terminal.writeAt(32, y, value.padLeft(7));
        y++;
      }
    }
  }

  void _drawSkillPanel(Terminal terminal, Skill skill) {
    Draw.frame(terminal, label: skill.name, labelSelected: true);
    var level = _hero.skills.level(skill);

    terminal.writeAt(1, 8, "At current level $level:", UIHue.primary);
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

    if (level < skill.maxLevel) {
      terminal.writeAt(1, 16, "At next level ${level + 1}:", UIHue.primary);
      Draw.text(
        terminal,
        x: 3,
        y: 18,
        width: terminal.width - 1,
        skill.levelDescription(level + 1),
      );
    }

    terminal.writeAt(1, 30, "Level:", UIHue.secondary);
    terminal.writeAt(9, 30, level.toString().padLeft(4), UIHue.text);
    Draw.meter(terminal, 14, 30, 25, level, skill.maxLevel, red, maroon);
  }

  void _changeSelection(int offset) {
    var length = Stat.values.length + _content.skills.length;
    _selectedIndex = (_selectedIndex + offset + length) % length;
    dirty();
  }
}
