import 'package:malison/malison.dart';
import '../hues.dart';

class Draw {
  static void box(Terminal terminal, int x, int y, int width, int height,
      [Color color]) {
    color ??= steelGray;
    var bar = "│" + " " * (width - 2) + "│";
    for (var row = y + 1; row < y + height - 1; row++) {
      terminal.writeAt(x, row, bar, color);
    }

    var top = "┌" + "─" * (width - 2) + "┐";
    var bottom = "└" + "─" * (width - 2) + "┘";
    terminal.writeAt(x, y, top, color);
    terminal.writeAt(x, y + height - 1, bottom, color);
  }

  static void frame(Terminal terminal, int x, int y, int width, int height,
      [Color color]) {
    color ??= steelGray;
    var bar = "│" + " " * (width - 2) + "│";
    for (var row = y + 1; row < y + height - 1; row++) {
      terminal.writeAt(x, row, bar, color);
    }

    var top = "╒" + "═" * (width - 2) + "╕";
    var bottom = "└" + "─" * (width - 2) + "┘";
    terminal.writeAt(x, y, top, color);
    terminal.writeAt(x, y + height - 1, bottom, color);
  }
}
