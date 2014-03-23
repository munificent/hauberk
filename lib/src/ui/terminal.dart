library ui.terminal;

abstract class Terminal {
  int get width;
  int get height;

  void clear();
  void write(String text, [Color fore, Color back]);
  void writeAt(int x, int y, String text, [Color fore, Color back]);
  void drawGlyph(int x, int y, Glyph glyph);
  Terminal rect(int x, int y, int width, int height);
}

abstract class RenderableTerminal extends Terminal {
  void render();
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
  static const BLACK        = const Color('k', '#000');
  static const WHITE        = const Color('w', '#fff');

  static const LIGHT_GRAY   = const Color('le', 'rgb(192, 192, 192)');
  static const GRAY         = const Color('e', 'rgb(128, 128, 128)');
  static const DARK_GRAY    = const Color('de', 'rgb(64, 64, 64)');

  static const LIGHT_RED    = const Color('lr', 'rgb(255, 160, 160)');
  static const RED          = const Color('r', 'rgb(220, 0, 0)');
  static const DARK_RED     = const Color('dr', 'rgb(100, 0, 0)');

  static const LIGHT_ORANGE = const Color('lo', 'rgb(255, 200, 170)');
  static const ORANGE       = const Color('o', 'rgb(255, 128, 0)');
  static const DARK_ORANGE  = const Color('do', 'rgb(128, 64, 0)');

  static const LIGHT_GOLD   = const Color('ld', 'rgb(255, 230, 150)');
  static const GOLD         = const Color('d', 'rgb(255, 192, 0)');
  static const DARK_GOLD    = const Color('dd', 'rgb(128, 96, 0)');

  static const LIGHT_YELLOW = const Color('ly', 'rgb(255, 255, 150)');
  static const YELLOW       = const Color('y', 'rgb(255, 255, 0)');
  static const DARK_YELLOW  = const Color('dy', 'rgb(128, 128, 0)');

  static const LIGHT_GREEN  = const Color('lg', 'rgb(130, 255, 90)');
  static const GREEN        = const Color('g', 'rgb(0, 128, 0)');
  static const DARK_GREEN   = const Color('dg', 'rgb(0, 64, 0)');

  static const LIGHT_AQUA   = const Color('la', 'rgb(128, 255, 255)');
  static const AQUA         = const Color('a', 'rgb(0, 255, 255)');
  static const DARK_AQUA    = const Color('da', 'rgb(0, 128, 128)');

  static const LIGHT_BLUE   = const Color('lb', 'rgb(128, 160, 255)');
  static const BLUE         = const Color('b', 'rgb(0, 64, 255)');
  static const DARK_BLUE    = const Color('db', 'rgb(0, 37, 168)');

  static const LIGHT_PURPLE = const Color('lp', 'rgb(200, 140, 255)');
  static const PURPLE       = const Color('p', 'rgb(128, 0, 255)');
  static const DARK_PURPLE  = const Color('dp', 'rgb(64, 0, 128)');

  static const LIGHT_BROWN  = const Color('ln', 'rgb(190, 150, 100)');
  static const BROWN        = const Color('n', 'rgb(160, 110, 60)');
  static const DARK_BROWN   = const Color('dn', 'rgb(100, 64, 32)');

  final String cssClass;
  final String cssColor;

  const Color(this.cssClass, this.cssColor);
}

class Glyph {
  final int    char;
  final Color  fore;
  final Color  back;

  Glyph(String char, [this.fore = Color.WHITE, this.back = Color.BLACK])
      : char = char.codeUnits[0];

  Glyph.fromCharCode(this.char, [this.fore = Color.WHITE, this.back = Color.BLACK]);

  operator ==(other) {
    if (other is! Glyph) return false;
    return char == other.char &&
        fore == other.fore &&
        back == other.back;
  }
}

/// Unicode code points for various special characters that also exist on
/// [code page 437][font].
///
/// [font]: http://en.wikipedia.org/wiki/Code_page_437
// Note: If you add stuff to this, make sure to add an appropriate mapping in
// canvas_terminal.dart.
class CharCode {
  static const SPACE = 32;
  static const BULLET = 0x2022;
  static const LEFT_RIGHT_ARROW = 0x2194;
  static const UP_DOWN_ARROW = 0x2195;
  static const SOLID = 0x2588;
  static const HALF_LEFT = 0x258c;
  static const BLACK_UP_POINTING_TRIANGLE = 0x25b2;
  static const BLACK_SPADE_SUIT = 0x2660;
  static const BLACK_CLUB_SUIT = 0x2663;
  static const BOX_DRAWINGS_LIGHT_VERTICAL = 0x2502;
  static const TRIPLE_BAR = 0x2261;
}