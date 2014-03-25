library dngn.ui.canvas_terminal;

import 'dart:html' as html;

import '../util.dart';
import 'terminal.dart';

/// Draws to a canvas using a browser font.
class CanvasTerminal implements RenderableTerminal {
  /// The current display state. The glyphs here mirror what has been rendered.
  final Array2D<Glyph> glyphs;

  /// The glyphs that have been modified since the last call to [render].
  final Array2D<Glyph> changedGlyphs;

  final Font font;
  final html.CanvasElement canvas;
  html.CanvasRenderingContext2D context;

  int scale = 1;

  int get width => glyphs.width;
  int get height => glyphs.height;

  static final clearGlyph = new Glyph(' ');

  CanvasTerminal(int width, int height, this.canvas, this.font)
      : glyphs = new Array2D<Glyph>(width, height, () => null),
        changedGlyphs = new Array2D<Glyph>(width, height,() => clearGlyph) {
    context = canvas.context2D;

    canvas.width = font.charWidth * width;
    canvas.height = font.lineHeight * height;

    // Handle high-resolution (i.e. retina) displays.
    if (html.window.devicePixelRatio > 1) {
      scale = 2;

      canvas.style.width = '${font.charWidth * width / scale}px';
      canvas.style.height = '${font.lineHeight * height / scale}px';
    }
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
    context.font = '${font.size * scale}px ${font.family}, monospace';

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        var glyph = changedGlyphs.get(x, y);

        // Only draw glyphs that are different since the last call.
        if (glyph == null) continue;

        // Up to date now.
        glyphs.set(x, y, glyph);
        changedGlyphs.set(x, y, null);

        var char = glyph.char;

        // Fill the background.
        context.fillStyle = glyph.back.cssColor;
        context.fillRect(x * font.charWidth, y * font.lineHeight,
            font.charWidth, font.lineHeight);

        // Don't bother drawing empty characters.
        if (char == 0 || char == CharCode.SPACE) continue;

        context.fillStyle = glyph.fore.cssColor;
        context.fillText(new String.fromCharCodes([char]),
            x * font.charWidth + font.x, y * font.lineHeight + font.y);
      }
    }
  }
}

/// Describes a font used by [CanvasTerminal].
class Font {
  final String family;
  final int size;
  final int charWidth;
  final int lineHeight;
  final int x;
  final int y;

  Font(this.family, {this.size, int w, int h, this.x, this.y})
      : charWidth = w,
        lineHeight = h;
}