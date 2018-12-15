import 'dart:math' as math;

import 'package:malison/malison.dart';

import '../debug.dart';
import '../engine.dart';
import '../hues.dart';
import 'popup.dart';

import 'input.dart';

class SelectDepthPopup extends Popup {
  final Content content;
  final HeroSave save;

  /// The selected depth.
  int _depth = 1;

  SelectDepthPopup(this.content, this.save) {
    _depth = math.min(Option.maxDepth, save.maxDepth + 1);
  }

  int get width => 42;

  int get height => 26;

  List<String> get message => const [
        "Stairs descend into darkness.",
        "How far down shall you venture?"
      ];

  Map<String, String> get helpKeys =>
      const {"OK": "Enter dungeon", "↕↔": "Change depth", "Esc": "Cancel"};

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

  void renderPopup(Terminal terminal) {
    for (var depth = 1; depth <= Option.maxDepth; depth++) {
      var x = (depth - 1) % 10;
      var y = ((depth - 1) ~/ 10) * 2;

      var color = UIHue.primary;
      if (!Debug.enabled && depth > save.maxDepth + 1) {
        color = UIHue.disabled;
      } else if (depth == _depth) {
        color = UIHue.selection;
        terminal.drawChar(
            x * 4, y + 5, CharCode.blackRightPointingPointer, color);
        terminal.drawChar(
            x * 4 + 4, y + 5, CharCode.blackLeftPointingPointer, color);
      }

      terminal.writeAt(x * 4 + 1, y + 5, depth.toString().padLeft(3), color);
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
