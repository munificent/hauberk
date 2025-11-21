import 'dart:math';

import 'package:malison/malison.dart';
import '../engine.dart';
import '../hues.dart';

// TODO: Turn these into extension on Terminal?
class Draw {
  // TODO: Unify this with Popup.
  static void dialog(
    Terminal terminal,
    int width,
    int height,
    void Function(Terminal) drawContents, {
    required String label,
    Map<String, String>? helpKeys,
  }) {
    terminal.fill(0, 0, terminal.width, terminal.height, darkerCoolGray);

    var dialogTerminal = terminal.rect(
      (terminal.width - width) ~/ 2,
      (terminal.height - 2 - height) ~/ 2,
      width,
      height,
    );
    Draw.frame(dialogTerminal, label: label);

    drawContents(
      dialogTerminal.rect(
        1,
        1,
        dialogTerminal.width - 2,
        dialogTerminal.height - 2,
      ),
    );

    if (helpKeys != null) Draw.helpKeys(terminal, helpKeys);
  }

  static void box(
    Terminal terminal,
    int x,
    int y,
    int width,
    int height, [
    Color? color,
  ]) {
    _box(
      terminal,
      x,
      y,
      width,
      height,
      color,
      "┌",
      "─",
      "┐",
      "│",
      "└",
      "─",
      "┘",
    );
  }

  static void frame(
    Terminal terminal, {
    int? x,
    int? y,
    int? width,
    int? height,
    Color? color,
    String? label,
    bool labelSelected = false,
  }) {
    _box(
      terminal,
      x,
      y,
      width,
      height,
      color,
      "╒",
      "═",
      "╕",
      "│",
      "└",
      "─",
      "┘",
    );

    if (label != null) {
      terminal.writeAt(
        (x ?? 0) + 2,
        y ?? 0,
        " $label ",
        labelSelected ? UIHue.selection : UIHue.text,
      );
    }
  }

  /// Breaks a string into lines and draws them.
  static void text(
    Terminal terminal,
    String text, {
    int? x,
    int? y,
    int? width,
    Color color = UIHue.text,
  }) {
    x ??= 0;
    y ??= 0;
    width ??= terminal.width;

    for (var line in Log.wordWrap(width - x, text)) {
      terminal.writeAt(x, y = y! + 1, line, color);
    }
  }

  /// Draws a thin horizontal line starting at ([x], [y]) and going [width]
  /// characters to the right.
  static void hLine(
    Terminal terminal,
    int x,
    int y,
    int width, {
    Color? color,
  }) {
    terminal.writeAt(x, y, "─" * width, color ?? darkCoolGray);
  }

  /// Draws a frame with a little box on top for a glyph with the name next to
  /// it.
  // TODO: Make position parameters named and optional.
  static void glyphFrame(
    Terminal terminal,
    int x,
    int y,
    int width,
    int height,
    Glyph glyph,
    String label,
  ) {
    frame(terminal, x: x, y: y + 1, width: width, height: height - 1);
    terminal.writeAt(x + 1, y, "┌─┐", darkCoolGray);
    terminal.writeAt(x + 1, y + 1, "╡ ╞", darkCoolGray);
    terminal.writeAt(x + 1, y + 2, "└─┘", darkCoolGray);
    terminal.drawGlyph(x + 2, y + 1, glyph);
    terminal.writeAt(x + 4, y + 1, label, UIHue.primary);
  }

  static void doubleBox(
    Terminal terminal,
    int x,
    int y,
    int width,
    int height, [
    Color? color,
  ]) {
    _box(
      terminal,
      x,
      y,
      width,
      height,
      color,
      "╔",
      "═",
      "╗",
      "║",
      "╚",
      "═",
      "╝",
    );
  }

  static void helpKeys(
    Terminal terminal,
    Map<String, String> helpKeys, [
    String? query,
  ]) {
    // Draw the help.
    var helpTextLength = 0;
    helpKeys.forEach((key, text) {
      if (helpTextLength > 0) helpTextLength += 2;
      helpTextLength += key.length + text.length + 3;
    });

    var boxWidth = helpTextLength;
    if (query != null) {
      boxWidth = max(boxWidth, query.length);
    }

    var x = (terminal.width - boxWidth) ~/ 2;

    // Show the query string, if there is one.
    if (query != null) {
      box(terminal, x - 2, terminal.height - 4, boxWidth + 4, 5, UIHue.text);
      terminal.writeAt(
        (terminal.width - query.length) ~/ 2,
        terminal.height - 3,
        query,
        UIHue.primary,
      );
    } else {
      box(terminal, x - 2, terminal.height - 2, boxWidth + 4, 3, UIHue.text);
    }

    var first = true;
    x += (boxWidth - helpTextLength) ~/ 2;
    helpKeys.forEach((key, text) {
      if (!first) {
        terminal.writeAt(x, terminal.height - 1, ", ", UIHue.secondary);
        x += 2;
      }

      terminal.writeAt(x, terminal.height - 1, "[", UIHue.secondary);
      x++;
      terminal.writeAt(x, terminal.height - 1, key, UIHue.selection);
      x += key.length;
      terminal.writeAt(x, terminal.height - 1, "] ", UIHue.secondary);
      x += 2;

      terminal.writeAt(x, terminal.height - 1, text, UIHue.helpText);
      x += text.length;

      first = false;
    });
  }

  static void _box(
    Terminal terminal,
    int? x,
    int? y,
    int? width,
    int? height,
    Color? color,
    String topLeft,
    String top,
    String topRight,
    String vertical,
    String bottomLeft,
    String bottom,
    String bottomRight,
  ) {
    x ??= 0;
    y ??= 0;
    width ??= terminal.width;
    height ??= terminal.height;

    color ??= darkCoolGray;
    var bar = vertical + " " * (width - 2) + vertical;
    for (var row = y + 1; row < y + height - 1; row++) {
      terminal.writeAt(x, row, bar, color);
    }

    var topRow = topLeft + top * (width - 2) + topRight;
    var bottomRow = bottomLeft + bottom * (width - 2) + bottomRight;
    terminal.writeAt(x, y, topRow, color);
    terminal.writeAt(x, y + height - 1, bottomRow, color);
  }

  /// Draws a progress bar to reflect [value]'s range between `0` and [max].
  /// Has a couple of special tweaks: the bar will only be empty if [value] is
  /// exactly `0`, otherwise it will at least show a sliver. Likewise, the bar
  /// will only be full if [value] is exactly [max], otherwise at least one
  /// half unit will be missing.
  static void meter(
    Terminal terminal,
    int x,
    int y,
    int width,
    int value,
    int max, [
    Color? fore,
    Color? back,
  ]) {
    assert(max != 0);

    fore ??= red;
    back ??= maroon;

    var barWidth = (width * 2 * value / max).round();

    // Edge cases, don't show an empty or full bar unless actually at the min
    // or max.
    if (barWidth == 0 && value > 0) barWidth = 1;
    if (barWidth == width * 2 && value < max) barWidth = width * 2 - 1;

    for (var i = 0; i < width; i++) {
      var char = CharCode.space;
      if (i < barWidth ~/ 2) {
        char = CharCode.fullBlock;
      } else if (i < (barWidth + 1) ~/ 2) {
        char = CharCode.leftHalfBlock;
      }
      terminal.drawChar(x + i, y, char, fore, back);
    }
  }

  /// Draws a progress bar to reflect [value]'s range between `0` and [max].
  /// Has a couple of special tweaks: the bar will only be empty if [value] is
  /// exactly `0`, otherwise it will at least show a sliver. Likewise, the bar
  /// will only be full if [value] is exactly [max], otherwise at least one
  /// half unit will be missing.
  static void thinMeter(
    Terminal terminal,
    int x,
    int y,
    int width,
    int value,
    int max, [
    Color? fore,
    Color? back,
  ]) {
    assert(max != 0);

    fore ??= red;
    back ??= maroon;

    var barWidth = (width * value / max).round();

    // Edge cases, don't show an empty or full bar unless actually at the min
    // or max.
    if (barWidth == 0 && value > 0) barWidth = 1;
    if (barWidth == width && value < max) barWidth = width - 1;

    for (var i = 0; i < width; i++) {
      var color = i < barWidth ? fore : back;
      terminal.drawChar(x + i, y, CharCode.lowerHalfBlock, color);
    }
  }
}
