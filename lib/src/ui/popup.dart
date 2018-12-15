import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../hues.dart';
import 'draw.dart';

import 'input.dart';

/// Base class for a centered modal dialog.
abstract class Popup extends Screen<Input> {
  bool get isTransparent => true;

  /// The width of the content area of the popup.
  ///
  /// If not overridden, is calculated from the width of the longest line in
  /// [message].
  int get width => null;

  /// The height of the content area of the popup.
  ///
  /// If not overridden, is calculated from the number of lines in [message].
  int get height => null;

  /// Override this to return a list of lines of text that should be shown
  /// centered at the top of the popup.
  List<String> get message => null;

  Map<String, String> get helpKeys;

  void render(Terminal terminal) {
    // Draw the help.
    var helpTextLength = 0;
    helpKeys.forEach((key, text) {
      if (helpTextLength > 0) helpTextLength += 2;
      helpTextLength += key.length + text.length + 3;
    });

    var x = (terminal.width - helpTextLength) ~/ 2;
    var first = true;
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

    var messageLines = message;

    var widestLine = 0;
    var lineCount = 0;
    if (messageLines != null) {
      widestLine = messageLines.fold<int>(
          0, (width, line) => math.max(width, line.length));
      lineCount = messageLines.length;
    }

    // If the width and height aren't specified, make it big enough to contain
    // the message with a margin around it.
    var popupWidth = width ?? widestLine + 2;
    var popupHeight = height ?? lineCount + 2;

    // Horizontally centered and a third of the way from the top.
    var top = (terminal.height - popupHeight) ~/ 3;
    var left = (terminal.width - popupWidth) ~/ 2;
    Draw.doubleBox(
        terminal, left - 1, top - 1, popupWidth + 2, popupHeight + 2, gold);

    terminal = terminal.rect(left, top, popupWidth, popupHeight);
    terminal.clear();

    // Draw the message if there is one.
    if (messageLines != null) {
      var widest = messageLines.fold<int>(
          0, (width, line) => math.max(width, line.length));
      var x = (terminal.width - widest) ~/ 2;
      var y = 1;

      for (var line in messageLines) {
        terminal.writeAt(x, y, line, UIHue.text);
        y++;
      }
    }

    renderPopup(terminal);
  }

  void renderPopup(Terminal terminal) {}
}
