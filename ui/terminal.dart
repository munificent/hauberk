
interface Terminal {
  int get width();
  int get height();

  void clear();
  void write(String text, [Color fore, Color back]);
  void writeAt(int x, int y, String text, [Color fore, Color back]);
  void drawGlyph(int x, int y, Glyph glyph);
  Terminal rect(int x, int y, int width, int height);
}

interface RenderableTerminal extends Terminal {
  void render();
}

class BaseTerminal implements Terminal {
  final Array2D<Glyph> glyphs;

  BaseTerminal(int width, int height)
  : glyphs = new Array2D<Glyph>(width, height,
      () => new Glyph(' ', Color.WHITE, Color.BLACK));

  int get width() => glyphs.width;
  int get height() => glyphs.height;

  void clear() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        writeAt(x, y, ' ');
      }
    }
  }

  void write(String text, [Color fore, Color back]) {
    for (int x = 0; x < text.length; x++) {
      if (x >= width) break;
      writeAt(x, 0, text[x], fore, back);
    }
  }

  void writeAt(int x, int y, String text, [Color fore, Color back]) {
    if (fore == null) fore = Color.WHITE;
    if (back == null) back = Color.BLACK;

    // TODO(bob): Bounds check.
    for (int i = 0; i < text.length; i++) {
      if (x + i >= width) break;
      glyphs.set(x + i, y, new Glyph(text[i], fore, back));
    }
  }

  void drawGlyph(int x, int y, Glyph glyph) {
    glyphs.set(x, y, glyph);
  }

  Terminal rect(int x, int y, int width, int height) {
    // TODO(bob): Bounds check.
    return new PortTerminal(x, y, width, height, this);
  }
}

class DomTerminal extends BaseTerminal implements RenderableTerminal {
  final html.Element element;

  DomTerminal(int width, int height, this.element)
  : super(width, height);

  render() {
    final buffer = new StringBuffer();

    var fore = null;
    var back = null;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final glyph = glyphs.get(x, y);

        // Switch colors.
        if (glyph.fore != fore || glyph.back != back) {
          if (glyph.fore != null) buffer.add('</span>');
          fore = glyph.fore;
          back = glyph.back;
          buffer.add('<span class="${glyph.fore.cssClass} b${glyph.back.cssClass}">');
        }

        buffer.add(glyph.char);
      }
      buffer.add('\n');
    }

    element.innerHTML = buffer.toString();
  }
}

class PortTerminal implements Terminal {
  final int width;
  final int height;

  final int _x;
  final int _y;
  final Terminal _root;

  PortTerminal(this._x, this._y, this.width, this.height, this._root);

  void clear() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        writeAt(x, y, ' ');
      }
    }
  }

  void write(String text, [Color fore, Color back]) {
    _root.writeAt(_x, _y, text, fore, back);
  }

  void writeAt(int x, int y, String text, [Color fore, Color back]) {
    // TODO(bob): Bounds check and crop.
    _root.writeAt(_x + x, _y + y, text, fore, back);
  }

  void drawGlyph(int x, int y, Glyph glyph) {
    _root.drawGlyph(_x + x, _y + y, glyph);
  }

  Terminal rect(int x, int y, int width, int height) {
    // TODO(bob): Bounds check.
    return new PortTerminal(_x + x, _y + y, width, height, _root);
  }
}

class Color {
  static const BLACK        = const Color('k');
  static const WHITE        = const Color('w');

  static const LIGHT_GRAY   = const Color('le');
  static const GRAY         = const Color('e');
  static const DARK_GRAY    = const Color('de');

  static const LIGHT_RED    = const Color('lr');
  static const RED          = const Color('r');
  static const DARK_RED     = const Color('dr');

  static const LIGHT_ORANGE = const Color('lo');
  static const ORANGE       = const Color('o');
  static const DARK_ORANGE  = const Color('do');

  static const LIGHT_GOLD   = const Color('ld');
  static const GOLD         = const Color('d');
  static const DARK_GOLD    = const Color('dd');

  static const LIGHT_YELLOW = const Color('ly');
  static const YELLOW       = const Color('y');
  static const DARK_YELLOW  = const Color('dy');

  static const LIGHT_GREEN  = const Color('lg');
  static const GREEN        = const Color('g');
  static const DARK_GREEN   = const Color('dg');

  static const LIGHT_AQUA   = const Color('la');
  static const AQUA         = const Color('a');
  static const DARK_AQUA    = const Color('da');

  static const LIGHT_BLUE   = const Color('lb');
  static const BLUE         = const Color('b');
  static const DARK_BLUE    = const Color('db');

  static const LIGHT_PURPLE = const Color('lp');
  static const PURPLE       = const Color('p');
  static const DARK_PURPLE  = const Color('dp');

  static const LIGHT_BROWN  = const Color('ln');
  static const BROWN        = const Color('n');
  static const DARK_BROWN   = const Color('dn');

  final String cssClass;

  const Color(this.cssClass);
}

class Glyph {
  final String char;
  final Color  fore;
  final Color  back;

  const Glyph(this.char, [this.fore = Color.WHITE, this.back = Color.BLACK]);
}
