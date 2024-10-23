import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import 'draw.dart';
import 'input.dart';
import 'storage.dart';

class GameOverScreen extends Screen<Input> {
  final HeroSave _hero;

  GameOverScreen(Storage storage, this._hero, HeroSave previousSave) {
    // If they have permadeath on, delete the hero.
    if (_hero.permadeath) {
      storage.remove(_hero);
    } else {
      storage.replace(previousSave);
    }
    storage.save();
  }

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.cancel:
        ui.pop();
        return true;
    }

    return false;
  }

  @override
  void render(Terminal terminal) {
    // TODO: This could be a whole lot more interesting looking. Show the hero's
    // final stats, etc.
    Draw.dialog(terminal, 60, 40, label: "You have died", (terminal) {
      var y = terminal.height - 1;
      for (var i = _hero.log.messages.length - 1; i >= 0; i--) {
        // TODO: Include count, lines, color.
        var lines = Log.wordWrap(terminal.width, _hero.log.messages[i].text);
        for (var j = lines.length - 1; j >= 0; j--) {
          terminal.writeAt(0, y, lines[j]);
          y--;
          if (y < 0) break;
        }

        if (y < 0) break;
      }
    }, helpKeys: {'`': _hero.permadeath ? "Create a new hero" : "Try again"});
  }
}
