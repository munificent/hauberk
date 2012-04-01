/// A keyboard is the lowest-level mapping from raw keyboard input to meaningful
/// use input. It listens to the raw DOM key events and keeps track of which
/// keys are currently pressed and which are not.
class Keyboard {
  final Set<int> _pressed;
  bool _shift;
  int _lastPressed;

  Keyboard(html.Element element)
  : _pressed = new Set<int>()
  {
    element.on.keyDown.add(keyDown);
    element.on.keyUp.add(keyUp);
  }

  /// Gets whether or not the shift modifier key is currently pressed.
  bool get shift() => _shift;

  /// Returns `true` if the [keyCode] is the only key currently being pressed.
  bool isOnlyPressed(int keyCode) => _pressed.length == 1 && isPressed(keyCode);

  /// Returns `true` if [keyCode] is currently being pressed.
  bool isPressed(int keyCode) => _pressed.contains(keyCode);

  /// If only one key is currently pressed, returns its key code. Otherwise
  /// returns `null`.
  int getOnlyKey() {
    if (_pressed.length != 1) return null;
    for (final key in _pressed) return key;
  }

  int get lastPressed() => _lastPressed;

  void keyDown(event) {
    if (event.keyCode == KeyCode.SHIFT) {
      _shift = true;
    } else {
      _pressed.add(event.keyCode);
      _lastPressed = event.keyCode;
    }
  }

  void keyUp(event) {
    if (event.keyCode == KeyCode.SHIFT) {
      _shift = false;
    } else {
      _pressed.remove(event.keyCode);
    }
  }

  void afterUpdate() {
    _lastPressed = null;
  }
}

/// Raw key codes. These code straight from the DOM events.
class KeyCode {
  static final SHIFT      = 16;
  static final ESCAPE     = 27;
  static final LEFT       = 37;
  static final UP         = 38;
  static final RIGHT      = 39;
  static final DOWN       = 40;
  static final A          = 65;
  static final B          = 66;
  static final C          = 67;
  static final D          = 68;
  static final E          = 69;
  static final F          = 70;
  static final G          = 71;
  static final H          = 72;
  static final I          = 73;
  static final J          = 74;
  static final K          = 75;
  static final L          = 76;
  static final M          = 77;
  static final N          = 78;
  static final O          = 79;
  static final P          = 80;
  static final Q          = 81;
  static final R          = 82;
  static final S          = 83;
  static final T          = 84;
  static final U          = 85;
  static final V          = 86;
  static final W          = 87;
  static final X          = 88;
  static final Y          = 89;
  static final Z          = 90;
  static final SEMICOLON  = 186;
  static final COMMA      = 188;
  static final PERIOD     = 190;
  static final SLASH      = 191;
  static final APOSTROPHE = 222;
}
