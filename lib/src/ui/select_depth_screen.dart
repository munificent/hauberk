import 'package:malison/malison.dart';

import '../debug.dart';
import '../engine.dart';
import 'game_screen.dart';
import 'input.dart';
import 'item_screen.dart';
import 'storage.dart';

class SelectDepthScreen extends Screen<Input> {
  final Content  content;
  final HeroSave save;
  final Storage storage;
  int selectedDepth = 1;

  SelectDepthScreen(this.content, this.save, this.storage);

  bool handleInput(Input input) {
    switch (input) {
      case Input.w:
          _changeDepth(selectedDepth - 1);
          return true;

      case Input.e:
          _changeDepth(selectedDepth + 1);
          return true;

      case Input.n:
          _changeDepth(selectedDepth - 15);
          return true;

      case Input.s:
          _changeDepth(selectedDepth + 15);
          return true;

      case Input.ok:
        var game = new Game(content, save, selectedDepth);
        ui.push(new GameScreen(save, game));
        return true;

      case Input.cancel:
        ui.pop();
        return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.i:
        ui.push(new ItemScreen(content, save));
        return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, 'Greetings, ${save.name}, how deep shall you venture?');
    terminal.writeAt(0, terminal.height - 1,
        '[L] Select area, [↕] Change depth, [↔] Change depth, [I] Manage items',
        Color.gray);

    // TODO: Do something prettier.
    for (var depth = 1; depth <= Option.maxDepth; depth++) {
      var x = (depth - 1) % 15;
      var y = (depth - 1) ~/ 15;

      var fore = Color.white;
      var back = Color.black;
      if (depth == selectedDepth) {
        fore = Color.black;
        back = Color.yellow;
      }
      terminal.writeAt(5 + x * 6, 5 + y * 2,
          depth.toString().padLeft(3), fore, back);
    }
  }

  void activate(Screen screen, result) {
    if (screen is GameScreen && result) {
      // Left successfully, so save.
      storage.save();
      Debug.exitLevel();
    } else if (screen is ItemScreen) {
      // Always save when leaving the item screen.
      storage.save();
    }
  }

  void _changeDepth(int level) {
    if (level < 1) return;
    if (level > Option.maxDepth) return;

    // TODO: Limit level that can be selected based on how deep previously
    // went.

    selectedDepth = level;
    dirty();
  }
}
