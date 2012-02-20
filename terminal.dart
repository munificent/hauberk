
interface Terminal {
  int get width();
  int get height();

  void write(String text, [Color color]);
  void writeAt(int x, int y, String text, [Color color]);
  Terminal rect(int x, int y, int width, int height);
}

class DomTerminal implements Terminal {
  final Element element;
  final Array2D<Glyph> glyphs;

  DomTerminal(int width, int height, this.element)
    : glyphs = new Array2D<Glyph>(width, height, () => new Glyph()) {}

  int get width() => glyphs.width;
  int get height() => glyphs.height;

  render() {
    final buffer = new StringBuffer();

    var color = null;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final glyph = glyphs.get(x, y);

        // Switch colors.
        if (glyph.color != color) {
          if (color != null) buffer.add('</span>');
          color = glyph.color;
          buffer.add('<span class="${color.cssClass}">');
        }

        buffer.add(glyph.char);
      }
      buffer.add('\n');
    }

    element.innerHTML = buffer.toString();
  }

  void write(String text, [Color color]) {
    for (int x = 0; x < text.length; x++) {
      if (x >= width) break;
      writeAt(x, 0, text[x], color);
    }
  }

  void writeAt(int x, int y, String text, [Color color]) {
    if (color == null) color = Color.WHITE;

    // TODO(bob): Bounds check.
    for (int i = 0; i < text.length; i++) {
      if (x + i >= width) break;
      glyphs.get(x, y).set(text[i], color);
    }
  }

  Terminal rect(int x, int y, int width, int height) {
    // TODO(bob): Bounds check.
    return new PortTerminal(x, y, width, height, this);
  }
}

class PortTerminal implements Terminal {
  final int width;
  final int height;

  final int _x;
  final int _y;
  final DomTerminal _dom;

  PortTerminal(this._x, this._y, this.width, this.height, this._dom);

  void write(String text, [Color color]) {
    _dom.writeAt(_x, _y, text[i], color);
  }

  void writeAt(int x, int y, String text, [Color color]) {
    // TODO(bob): Bounds check and crop.
    _dom.writeAt(_x + x, _y + y, text, color);
  }

  Terminal rect(int x, int y, int width, int height) {
    // TODO(bob): Bounds check.
    return new PortTerminal(_x + x, _y + y, width, height, _dom);
  }
}

class Color {
  static final WHITE       = const Color('w');
  static final GRAY        = const Color('e');
  static final DARK_GRAY   = const Color('de');
  static final RED         = const Color('r');
  static final ORANGE      = const Color('o');
  static final YELLOW      = const Color('y');
  static final GREEN       = const Color('g');
  static final AQUA        = const Color('a');
  static final BLUE        = const Color('b');
  static final PURPLE      = const Color('p');
  static final DARK_RED    = const Color('dr');
  static final DARK_ORANGE = const Color('do');
  static final DARK_YELLOW = const Color('dy');
  static final DARK_GREEN  = const Color('dg');
  static final DARK_AQUA   = const Color('da');
  static final DARK_BLUE   = const Color('db');
  static final DARK_PURPLE = const Color('dp');

  final String cssClass;

  const Color(this.cssClass);
}

class Glyph {
  String char;
  Color  color;

  Glyph()
  : char = ' ',
    color = Color.WHITE;

  void set(String char, Color color) {
    this.char = char;
    this.color = color;
  }
}
