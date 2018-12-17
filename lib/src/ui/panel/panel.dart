import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

abstract class Panel {
  Rect bounds;

  bool get isVisible => bounds != null;

  void render(Terminal terminal) {
    if (bounds == null) return;

    renderPanel(terminal.rect(bounds.x, bounds.y, bounds.width, bounds.height));
  }

  void renderPanel(Terminal terminal);
}
