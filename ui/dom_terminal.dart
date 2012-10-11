/// Draws directly using the DOM by building `<span>` elements inside a `<pre>`
/// for the terminal characters. Looks nice, but is quite slow.
class DomTerminal implements RenderableTerminal {
  final Array2D<Glyph> glyphs;
  final html.Element element;

  int get width => glyphs.width;
  int get height => glyphs.height;

  DomTerminal(int width, int height, this.element)
      : glyphs = new Array2D<Glyph>(width, height,
          () => new Glyph(' ', Color.WHITE, Color.BLACK));

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
      glyphs.set(x + i, y, new Glyph.fromCharCode(text.charCodeAt(i), fore, back));
    }
  }

  void drawGlyph(int x, int y, Glyph glyph) {
    glyphs.set(x, y, glyph);
  }

  Terminal rect(int x, int y, int width, int height) {
    // TODO(bob): Bounds check.
    return new PortTerminal(x, y, width, height, this);
  }

  void render() {
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
