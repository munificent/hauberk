import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../debug.dart';
import '../engine.dart';
import '../hues.dart';
import 'game_screen.dart';
import 'input.dart';
import 'item_screen.dart';
import 'loading_dialog.dart';
import 'storage.dart';

class SelectDepthScreen extends Screen<Input> {
  final Content content;
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
        _changeDepth(selectedDepth - 10);
        return true;

      case Input.s:
        _changeDepth(selectedDepth + 10);
        return true;

      case Input.ok:
        ui.push(LoadingDialog(save, content, selectedDepth));
        return true;

      case Input.cancel:
        ui.pop();
        return true;
    }

    return false;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    // TODO: Shops, the crucible, and the home are disabled for now since
    // I'm in the process of removing money.
    switch (keyCode) {
//      case KeyCode.c:
//        ui.push(new ItemScreen.crucible(content, save));
//        break;
//
//      case KeyCode.h:
//        ui.push(new ItemScreen.home(content, save));
//        return true;
//
//      case KeyCode.one: return tryEnterShop(0);
//      case KeyCode.two: return tryEnterShop(1);
//      case KeyCode.three: return tryEnterShop(2);
//      case KeyCode.four: return tryEnterShop(3);
//      case KeyCode.five: return tryEnterShop(4);
//      case KeyCode.six: return tryEnterShop(5);
//      case KeyCode.seven: return tryEnterShop(6);
//      case KeyCode.eight: return tryEnterShop(7);
//      case KeyCode.nine: return tryEnterShop(8);
    }

    return false;
  }

  bool tryEnterShop(int index) {
    if (index >= content.shops.length) return false;

    ui.push(ItemScreen.shop(content, save, content.shops.elementAt(index)));
    return true;
  }

  void render(Terminal terminal) {
    terminal.writeAt(15, 14,
        'Greetings, ${save.name}, how deep shall you venture?', UIHue.text);
    terminal.writeAt(
        0,
        terminal.height - 1,
        '[L] Enter dungeon, [↕] Change depth, [↔] Change depth',
        UIHue.helpText);

    // TODO: Do something prettier.
    for (var depth = 1; depth <= Option.maxDepth; depth++) {
      var x = (depth - 1) % 10;
      var y = (depth - 1) ~/ 10;

      var color = UIHue.primary;
      if (!Debug.enabled && depth > save.maxDepth + 1) {
        color = UIHue.disabled;
      } else if (depth == selectedDepth) {
        color = UIHue.selection;
        terminal.drawChar(
            14 + x * 5, 16 + y, CharCode.blackRightPointingPointer, color);
        terminal.drawChar(
            18 + x * 5, 16 + y, CharCode.blackLeftPointingPointer, color);
      }

      terminal.writeAt(15 + x * 5, 16 + y, depth.toString().padLeft(3), color);
    }

    // TODO: Shops, the crucible, and the home are disabled for now since
    // I'm in the process of removing money.
//    var y = 17;
//    drawMenuItem(String key, String label) {
//      terminal.writeAt(30, y, key, Color.gray);
//      terminal.writeAt(31, y, ")", Color.darkGray);
//      terminal.writeAt(33, y, label);
//      y++;
//    }
//
//    drawMenuItem("h", "Enter Home");
//    drawMenuItem("c", "Use Crucible");
//    y++;
//
//    var i = 1;
//    for (var shop in content.shops) {
//      drawMenuItem(i.toString(), shop.name);
//      i++;
//    }
  }

  void activate(Screen screen, result) {
    if (screen is GameScreen && (result as bool)) {
      // Left successfully, so save.
      storage.save();
    } else if (screen is ItemScreen) {
      // Always save when leaving the item screen.
      storage.save();
    }
  }

  void _changeDepth(int level) {
    if (level < 1) return;
    if (level > Option.maxDepth) return;
    if (!Debug.enabled && level > save.maxDepth + 1) return;

    selectedDepth = level;
    dirty();
  }
}
