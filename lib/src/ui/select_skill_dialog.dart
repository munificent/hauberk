import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'game_screen.dart';
import 'input.dart';

class SelectSkillDialog extends Screen<Input> {
  final GameScreen _gameScreen;
  final List<UsableSkill> _skills = [];

  bool get isTransparent => true;

  SelectSkillDialog(this._gameScreen) {
    for (var skill in _gameScreen.game.hero.skills.acquired) {
      if (skill is UsableSkill) _skills.add(skill);
    }
  }

  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      selectCommand(keyCode - KeyCode.a);
      return true;
    }

    // TODO: Quick keys!
    return false;
  }

  void selectCommand(int index) {
    if (index >= _skills.length) return;
    if (_skills[index].unusableReason(_gameScreen.game) != null) return;

    ui.pop(_skills[index]);
  }

  void render(Terminal terminal) {
    Draw.helpKeys(terminal, {
      "A-Z": "Select skill",
      // "1-9": "Bind quick key",
      "Esc": "Exit"
    });

    // If the item panel is visible, put it there. Otherwise, put it in the
    // stage area.
    if (_gameScreen.itemPanel.isVisible) {
      terminal = terminal.rect(
          _gameScreen.itemPanel.bounds.left,
          _gameScreen.itemPanel.bounds.top,
          _gameScreen.itemPanel.bounds.width,
          _gameScreen.itemPanel.bounds.height);
    } else {
      terminal = terminal.rect(
          _gameScreen.stagePanel.bounds.left,
          _gameScreen.stagePanel.bounds.top,
          _gameScreen.stagePanel.bounds.width,
          _gameScreen.stagePanel.bounds.height);
    }

    // Draw a box for the contents.
    var height = math.max(_skills.length + 2, 3);

    Draw.frame(terminal, 0, 0, terminal.width, height, UIHue.selection);
    terminal.writeAt(2, 0, " Use which skill? ", UIHue.selection);

    terminal = terminal.rect(1, 1, terminal.width - 2, terminal.height - 2);

    if (_skills.isEmpty) {
      terminal.writeAt(0, 0, "(You don't have any skills yet)", UIHue.disabled);
      return;
    }

    // TODO: Handle this being taller than the screen.
    for (var y = 0; y < _skills.length; y++) {
      var skill = _skills[y];

      var borderColor = UIHue.secondary;
      var letterColor = darkerCoolGray;
      var textColor = UIHue.disabled;

      var reason = skill.unusableReason(_gameScreen.game);
      if (reason == null) {
        borderColor = UIHue.primary;
        letterColor = UIHue.selection;
        textColor = UIHue.selection;
      }

      if (reason != null) {
        terminal.writeAt(
            terminal.width - reason.length - 2, y, "($reason)", textColor);
      }

      terminal.writeAt(0, y, "( )   ", borderColor);
      terminal.writeAt(1, y, "abcdefghijklmnopqrstuvwxyz"[y], letterColor);
      terminal.writeAt(4, y, skill.useName, textColor);
    }
  }
}
