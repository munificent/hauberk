
interface Terminal {
  int get width();
  int get height();

  void write(String text, [Color color]);
  void writeAt(int x, int y, String char, [Color color]);
  Terminal rect(int x, int y, int width, int height);
}

class DomTerminal implements Terminal {
  final Element element;
  final List<Glyph> glyphs;

  final int width;
  final int height;

  DomTerminal(this.width, this.height, this.element)
    : glyphs = <Glyph>[] {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        glyphs.add(new Glyph());
      }
    }
  }

  render() {
    final buffer = new StringBuffer();

    var color = null;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final glyph = glyphs[y * width + x];

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

  void writeAt(int x, int y, String char, [Color color]) {
    if (color == null) color = Color.WHITE;

    // TODO(bob): Bounds check.
    glyphs[y * width + x].set(char, color);
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
    for (int i = 0; i < text.length; i++) {
      if (i >= width) break;
      _dom.writeAt(_x + i, _y, text[i], color);
    }
  }

  void writeAt(int x, int y, String char, [Color color]) {
    // TODO(bob): Bounds check and crop.
    _dom.writeAt(_x + x, _y + y, char, color);
  }

  Terminal rect(int x, int y, int width, int height) {
    // TODO(bob): Bounds check.
    return new PortTerminal(_x + x, _y + y, width, height, _dom);
  }
}

class Color {
  // TODO(bob): Add more colors.
  static final RED   = const Color('r');
  static final GREEN = const Color('g');
  static final BLUE  = const Color('b');
  static final WHITE = const Color('w');

  static final All = const [
    RED, GREEN, BLUE, WHITE
  ];

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
