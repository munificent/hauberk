library ui.retro_terminal;

import 'dart:html' as html;

import '../util.dart';
import 'terminal.dart';

/// Draws to a canvas using the old school DOS [code page 437][font] font. It's
/// got some basic optimization to minimize the amount of drawing it has to do.
///
/// [font]: http://en.wikipedia.org/wiki/Code_page_437
class RetroTerminal implements RenderableTerminal {
  /// The current display state. The glyphs here mirror what has been rendered.
  final Array2D<Glyph> glyphs;

  /// The glyphs that have been modified since the last call to [render].
  final Array2D<Glyph> changedGlyphs;

  final html.CanvasElement canvas;
  html.CanvasRenderingContext2D context;
  html.ImageElement font;

  int get width => glyphs.width;
  int get height => glyphs.height;

  /// A cache of the tinted font images. Each key is a CSS class name, and the
  /// image will be the font in that color.
  final Map<String, html.CanvasElement> _fontColorCache = {};

  bool _imageLoaded = false;

  static const FONT_WIDTH = 9;
  static const FONT_HEIGHT = 16;

  static final clearGlyph = new Glyph(' ');

  // TODO(bob): Make this const when we can use const expressions as keys in
  // map literals.
  static final unicodeMap = createUnicodeMap();

  RetroTerminal(int width, int height, this.canvas)
      : glyphs = new Array2D<Glyph>(width, height, () => null),
        changedGlyphs = new Array2D<Glyph>(width, height,() => clearGlyph) {
    context = canvas.context2D;
    canvas.width = FONT_WIDTH * width;
    canvas.height = FONT_HEIGHT * height;

    font = new html.ImageElement(src: 'font.png');
    font.onLoad.listen((_) {
      _imageLoaded = true;
      render();
    });
  }

  static Map<int, int> createUnicodeMap() {
    var map = new Map<int, int>();
    map[CharCode.BULLET] = 7;
    map[CharCode.LEFT_RIGHT_ARROW] = 29;
    map[CharCode.UP_DOWN_ARROW] = 18;
    map[CharCode.SOLID] = 219;
    map[CharCode.HALF_LEFT] = 221;
    return map;
  }

  void clear() {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        drawGlyph(x, y, clearGlyph);
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
      // TODO(bob): Is codeUnits[] the right thing here? Is it fast?
      drawGlyph(x + i, y, new Glyph.fromCharCode(text.codeUnits[i], fore, back));
    }
  }

  void drawGlyph(int x, int y, Glyph glyph) {
    if (glyphs.get(x, y) != glyph) {
      changedGlyphs.set(x, y, glyph);
    } else {
      changedGlyphs.set(x, y, null);
    }
  }

  Terminal rect(int x, int y, int width, int height) {
    // TODO(bob): Bounds check.
    return new PortTerminal(x, y, width, height, this);
  }

  void render() {
    if (!_imageLoaded) return;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        var glyph = changedGlyphs.get(x, y);

        // Only draw glyphs that are different since the last call.
        if (glyph == null) continue;

        // Up to date now.
        glyphs.set(x, y, glyph);
        changedGlyphs.set(x, y, null);

        var char = glyph.char;

        // See if it's a Unicode character that needs to be remapped.
        var fromUnicode = unicodeMap[char];
        if (fromUnicode != null) char = fromUnicode;

        var sx = (char % 32) * FONT_WIDTH;
        var sy = (char ~/ 32) * FONT_HEIGHT;

        // Fill the background.
        context.fillStyle = glyph.back.cssColor;
        context.fillRect(x * FONT_WIDTH, y * FONT_HEIGHT,
            FONT_WIDTH, FONT_HEIGHT);

        // Don't bother drawing empty characters.
        if (char == 0 || char == CharCode.SPACE) continue;

        var color = _getColorFont(glyph.fore);
        context.drawImageScaledFromSource(color,
            sx, sy, FONT_WIDTH, FONT_HEIGHT,
            x * FONT_WIDTH, y * FONT_HEIGHT, FONT_WIDTH, FONT_HEIGHT);
      }
    }
  }

  html.CanvasElement _getColorFont(Color color) {
    var cached = _fontColorCache[color.cssClass];
    if (cached != null) return cached;

    // Create a font using the given color.
    var tint = new html.CanvasElement(width: font.width, height: font.height);
    var context = tint.context2D;

    // Draw the font.
    context.drawImage(font, 0, 0);

    // Tint it by filling in the existing alpha with the color.
    context.globalCompositeOperation = 'source-atop';
    context.fillStyle = color.cssColor;
    context.fillRect(0, 0, font.width, font.height);

    _fontColorCache[color.cssClass] = tint;
    return tint;
  }
}
