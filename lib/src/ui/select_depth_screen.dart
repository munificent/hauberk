import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../debug.dart';
import '../engine.dart';
import '../hues.dart';
import 'draw.dart';

import 'input.dart';

class SelectDepthScreen extends Screen<Input> {
  final Content content;
  final HeroSave save;

  /// The selected depth.
  int _depth = 1;

  bool get isTransparent => true;

  SelectDepthScreen(this.content, this.save) {
    _depth = math.min(Option.maxDepth, save.maxDepth + 1);
  }

  bool handleInput(Input input) {
    switch (input) {
      case Input.w:
        _changeDepth(_depth - 1);
        return true;

      case Input.e:
        _changeDepth(_depth + 1);
        return true;

      case Input.n:
        _changeDepth(_depth - 10);
        return true;

      case Input.s:
        _changeDepth(_depth + 10);
        return true;

      case Input.ok:
        ui.pop(_depth);
        return true;

      case Input.cancel:
        ui.pop();
        return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, terminal.height - 1,
        '[L] Enter dungeon, [↕↔] Change depth, [Esc] Cancel', UIHue.helpText);

    terminal = terminal.rect(11, 5, 44, 28);
    terminal.clear();

    Draw.doubleBox(terminal, 0, 0, terminal.width, terminal.height, gold);

    terminal.writeAt(6, 2, "Stairs descend into darkness.", UIHue.text);
    terminal.writeAt(6, 3, "How far down shall you venture?", UIHue.text);

    for (var depth = 1; depth <= Option.maxDepth; depth++) {
      var x = (depth - 1) % 10;
      var y = ((depth - 1) ~/ 10) * 2;

      var color = UIHue.primary;
      if (!Debug.enabled && depth > save.maxDepth + 1) {
        color = UIHue.disabled;
      } else if (depth == _depth) {
        color = UIHue.selection;
        terminal.drawChar(
            x * 4 + 1, 6 + y, CharCode.blackRightPointingPointer, color);
        terminal.drawChar(
            x * 4 + 5, 6 + y, CharCode.blackLeftPointingPointer, color);
      }

      terminal.writeAt(x * 4 + 2, 6 + y, depth.toString().padLeft(3), color);
    }
  }

  void _changeDepth(int depth) {
    if (depth < 1) return;
    if (depth > Option.maxDepth) return;
    if (!Debug.enabled && depth > save.maxDepth + 1) return;

    _depth = depth;
    dirty();
  }
}
