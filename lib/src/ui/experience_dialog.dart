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
  final HeroSave _save;

  int _selectedStatIndex = 0;

  StatBase get _selectedStat => switch (_selectedStatIndex) {
    0 => _save.strength,
    1 => _save.agility,
    2 => _save.vitality,
    3 => _save.intellect,
    _ => throw ArgumentError(),
  };

  bool get _canRaiseStat {
    var stat = _selectedStat;
    var cost = stat.experienceCost(_save);
    return stat.baseValue < Stat.baseMax && _save.experience >= cost;
  }

  ExperienceDialog(this._save);

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
        if (_canRaiseStat) {
          var stat = _selectedStat;
          _save.experience -= stat.experienceCost(_save);
          stat.refresh(_save, stat.baseValue + 1);
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
      _save.experience.toString().padLeft(8),
      UIHue.primary,
    );

    _drawStatsList(terminal.rect(0, 3, 40, 11));

    var panelTerminal = terminal.rect(
      40,
      0,
      terminal.width - 40,
      terminal.height,
    );

    switch (_selectedStatIndex) {
      case 0:
        _drawStrengthPanel(panelTerminal);
      case 1:
        _drawAgilityPanel(panelTerminal);
      case 2:
        _drawVitalityPanel(panelTerminal);
      case 3:
        _drawIntellectPanel(panelTerminal);
    }

    Draw.helpKeys(terminal, {
      "↕": "Change selection",
      if (_canRaiseStat) "R": "Raise ${_selectedStat.name}",
      "`": "Exit",
    }, "You can spend ${_save.experience} experience");
  }

  void _drawStatsList(Terminal terminal) {
    Draw.frame(terminal, label: 'Stats');

    var separator = "──────────────────────── ─── ────────";

    // Current value and cost to increment?
    terminal.writeAt(27, 1, "Cur     Cost", UIHue.helpText);

    var stats = [
      _save.strength,
      _save.agility,
      _save.vitality,
      _save.intellect,
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

      var nameColor = UIHue.primary;
      var detailColor = UIHue.text;
      if (i == _selectedStatIndex) {
        nameColor = UIHue.selection;
        detailColor = UIHue.selection;
      }

      terminal.writeAt(2, y, stat.name, nameColor);
      terminal.writeAt(27, y, stat.value.toString().padLeft(3), detailColor);
      var cost = stat.experienceCost(_save);
      terminal.writeAt(
        31,
        y,
        cost.toString().padLeft(8),
        cost <= _save.experience ? detailColor : UIHue.disabled,
      );

      i++;
    }

    terminal.drawChar(
      1,
      _selectedStatIndex * 2 + 3,
      CharCode.blackRightPointingPointer,
      UIHue.selection,
    );
  }

  void _drawStrengthPanel(Terminal terminal) {
    _drawStatPanel(terminal, _save.strength, ['Max Fury', 'Toss range scale'], (
      int value,
    ) {
      var tossPercent = '${(Strength.tossRangeScaleAt(value) * 100).toInt()}%';
      // TODO: Show weapon heft and armor weight somehow.
      return [Strength.maxFuryAt(value).toString(), tossPercent];
    });
  }

  void _drawAgilityPanel(Terminal terminal) {
    _drawStatPanel(terminal, _save.agility, ['Dodge bonus', 'Strike bonus'], (
      int value,
    ) {
      return [
        Agility.dodgeBonusAt(value).toString(),
        Agility.strikeBonusAt(value).toString(),
      ];
    });
  }

  void _drawVitalityPanel(Terminal terminal) {
    _drawStatPanel(terminal, _save.vitality, ['Max health'], (int value) {
      return [Vitality.maxHealthAt(value).toString()];
    });
  }

  void _drawIntellectPanel(Terminal terminal) {
    _drawStatPanel(
      terminal,
      _save.intellect,
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

    if (stat == _save.strength) {
      var weightOffset = _save.strength.weightOffset(_save).toInt();
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

  void _changeSelection(int offset) {
    _selectedStatIndex = (_selectedStatIndex + offset).clamp(
      0,
      Stat.all.length - 1,
    );
    dirty();
  }
}
