library hauberk.ui.retro_terminal;

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

  /// The drawing scale, used to adapt to Retina displays.
  int _scale = 1;

  bool _imageLoaded = false;

  final int _fontWidth;
  final int _fontHeight;

  static final clearGlyph = new Glyph(' ');

  // TODO(bob): Make this const when we can use const expressions as keys in
  // map literals.
  static final unicodeMap = _createUnicodeMap();

  RetroTerminal(int width, int height, this.canvas, String image,
      {int w, int h})
      : glyphs = new Array2D<Glyph>(width, height, () => null),
        changedGlyphs = new Array2D<Glyph>(width, height,() => clearGlyph),
        _fontWidth = w,
        _fontHeight = h {
    context = canvas.context2D;

    // Handle high-resolution (i.e. retina) displays.
    if (html.window.devicePixelRatio > 1) {
      _scale = 2;
    }

    var canvasWidth = _fontWidth * width;
    var canvasHeight = _fontHeight * height;
    canvas.width = canvasWidth * _scale;
    canvas.height = canvasHeight * _scale;
    canvas.style.width = '${canvasWidth}px';
    canvas.style.height = '${canvasHeight}px';

    font = new html.ImageElement(src: image);
    font.onLoad.listen((_) {
      _imageLoaded = true;
      render();
    });
  }

  static Map<int, int> _createUnicodeMap() {
    var map = new Map<int, int>();
    map[CharCode.BULLET] = 7;
    map[CharCode.UP_DOWN_ARROW] = 18;
    map[CharCode.LEFT_RIGHT_ARROW] = 29;
    map[CharCode.BLACK_UP_POINTING_TRIANGLE] = 30;
    map[CharCode.BLACK_SPADE_SUIT] = 6;
    map[CharCode.BLACK_CLUB_SUIT] = 5;
    map[CharCode.SOLID] = 219;
    map[CharCode.HALF_LEFT] = 221;
    map[CharCode.BOX_DRAWINGS_LIGHT_VERTICAL] = 179;
    map[CharCode.TRIPLE_BAR] = 240;
    map[CharCode.PI] = 227;
    map[CharCode.BLACK_HEART_SUIT] = 3;
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

        var sx = (char % 32) * _fontWidth;
        var sy = (char ~/ 32) * _fontHeight;

        // Fill the background.
        context.fillStyle = glyph.back.cssColor;
        context.fillRect(
            x * _fontWidth * _scale,
            y * _fontHeight * _scale,
            _fontWidth * _scale,
            _fontHeight * _scale);

        // Don't bother drawing empty characters.
        if (char == 0 || char == CharCode.SPACE) continue;

        var color = _getColorFont(glyph.fore);
        // *2 because the font image is double-sized. That ensures it stays
        // sharp on retina displays and doesn't render scaled up.
        context.drawImageScaledFromSource(color,
            sx * 2, sy * 2, _fontWidth * 2, _fontHeight * 2,
            x * _fontWidth * _scale,
            y * _fontHeight * _scale,
            _fontWidth * _scale,
            _fontHeight * _scale);
      }
    }
  }

  Vec pixelToChar(Vec pixel) =>
      new Vec(pixel.x ~/ _fontWidth, pixel.y ~/ _fontHeight);

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
