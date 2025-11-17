import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

abstract class Panel {
  Rect? _bounds;

  bool get isVisible => _bounds != null;

  /// The bounding box for the panel.
  ///
  /// This can only be called if the panel is visible.
  Rect get bounds => _bounds!;

  void hide() {
    _bounds = null;
  }

  void show(Rect bounds) {
    _bounds = bounds;
  }

  void render(Terminal terminal) {
    if (_bounds case var bounds?) {
      renderPanel(
        terminal.rect(bounds.x, bounds.y, bounds.width, bounds.height),
      );
    }
  }

  void renderPanel(Terminal terminal);
}
