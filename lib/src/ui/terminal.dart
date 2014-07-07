library hauberk.ui.terminal;

import '../util.dart';

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

  /// Given a point in pixel coordinates, returns the coordinates of the
  /// character that contains that pixel.
  Vec pixelToChar(Vec pixel);
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
