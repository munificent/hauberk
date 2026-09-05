import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../input.dart';
import '../widget/draw.dart';
import 'game_screen.dart';

/// Selects an [Ability] to perform.
class UseAbilityDialog extends Screen<Input> {
  final GameScreen _gameScreen;

  // TODO: Consider whether it's a better UX to merge these dialogs and show
  // abilities and spells together.

  /*
  /// If `true`, the dialog is for selecting a spell to cast, otherwise it's
  /// for selecting a non-spell ability.
  final bool _showSpells;
  */

  final List<Ability> _abilities;

  @override
  bool get isTransparent => true;

  UseAbilityDialog(this._gameScreen /*, {required bool showSpells}*/)
    : /*_showSpells = showSpells,*/
      _abilities = [
        /*
        if (showSpells)
          ..._gameScreen.game.hero.save.learnedSpells
        else*/
        // for (var skill in _gameScreen.game.hero.skills.acquired) ?skill.ability,
        ..._gameScreen.game.content.abilities,
      ];

  @override
  bool handleInput(Input input) {
    if (input == Input.cancel) {
      ui.pop();
      return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    if (keyCode >= KeyCode.a && keyCode <= KeyCode.z) {
      _useAbility(keyCode - KeyCode.a);
      return true;
    }

    // TODO: Quick keys.
    return false;
  }

  void _useAbility(int index) {
    if (index >= _abilities.length) return;
    if (_abilities[index].unusableReason(_gameScreen.game) != null) return;

    ui.pop(_abilities[index]);
  }

  @override
  void render(Terminal terminal) {
    Draw.helpKeys(terminal, {
      "A-Z": /*_showSpells ? "Select spell" :*/ "Select ability",
      // "1-9": "Bind quick key",
      "`": "Exit",
    });

    const width = 50;
    var height = math.max(_abilities.length + 2, 3);

    // If the item panel is visible, put it there. Otherwise, put it in the
    // stage area.
    terminal = terminal.rect(terminal.width - width, 0, width, height);
    // if (_gameScreen.itemPanel.isVisible) {
    //   terminal = terminal.rect(
    //     _gameScreen.itemPanel.bounds.left,
    //     _gameScreen.itemPanel.bounds.top,
    //     _gameScreen.itemPanel.bounds.width,
    //     _gameScreen.itemPanel.bounds.height,
    //   );
    // } else {
    //   terminal = terminal.rect(
    //     _gameScreen.stagePanel.bounds.left,
    //     _gameScreen.stagePanel.bounds.top,
    //     _gameScreen.stagePanel.bounds.width,
    //     _gameScreen.stagePanel.bounds.height,
    //   );
    // }

    // Draw a box for the contents.
    Draw.frame(
      terminal,
      height: height,
      label: /*_showSpells ? "Cast which spell?" :*/ "Use which ability?",
      selected: true,
    );

    terminal.writeAt(terminal.width - 9, 0, ' Focus ', UIHue.highlight);

    terminal = terminal.rect(1, 1, terminal.width - 2, terminal.height - 2);

    // TODO: Still needed?
    if (_abilities.isEmpty) {
      terminal.writeAt(
        0,
        0,
        /*_showSpells
            ? "(You don't know any spells)"
            :*/
        "(You don't have any abilities)",
        UIHue.disabled,
      );
      return;
    }

    // TODO: Handle this being taller than the screen.
    var hero = _gameScreen.game.hero;
    for (var y = 0; y < _abilities.length; y++) {
      var ability = _abilities[y];
      var focusCost = ability.focusCost(hero.save);

      if (ability.unusableReason(_gameScreen.game) case var reason?) {
        terminal.writeAt(
          terminal.width - reason.length - 2,
          y,
          reason,
          UIHue.disabled,
        );
        terminal.writeAt(3, y, ability.name, UIHue.disabled);
      } else if (hero.focus < focusCost) {
        terminal.writeAt(3, y, ability.name, UIHue.disabled);
        terminal.writeAt(terminal.width - 5, y, focusCost.fmt(w: 3), Color.red);
      } else {
        terminal.writeAt(0, y, " )   ", UIHue.disabled);
        terminal.writeAt(
          0,
          y,
          "abcdefghijklmnopqrstuvwxyz"[y],
          UIHue.highlight,
        );
        terminal.writeAt(3, y, ability.name, UIHue.selectable);
        terminal.writeAt(
          terminal.width - 5,
          y,
          focusCost.fmt(w: 3),
          UIHue.text,
        );
      }
    }
  }
}
