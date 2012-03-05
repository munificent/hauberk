
// TODO(bob): Better name.
class UserInput {
  final Keyboard keyboard;

  /// The direction key the user is currently pressing.
  Direction currentDirection = null;

  /// How long the user has been pressing in the current direction.
  int holdTime = 0;

  UserInput(this.keyboard);

  Action getAction() {
    // See which direction is being pressed.
    var direction;
    switch (keyboard.getOnlyKey()) {
      case KeyCode.I:         direction = Direction.NW; break;
      case KeyCode.O:         direction = Direction.N; break;
      case KeyCode.P:         direction = Direction.NE; break;
      case KeyCode.K:         direction = Direction.W; break;
      case KeyCode.L:         direction = Direction.NONE; break;
      case KeyCode.SEMICOLON: direction = Direction.E; break;
      case KeyCode.COMMA:     direction = Direction.SW; break;
      case KeyCode.PERIOD:    direction = Direction.S; break;
      case KeyCode.SLASH:     direction = Direction.SE; break;
    }

    if (direction != currentDirection) {
      // Changing direction.
      currentDirection = direction;
      holdTime = 0;
    } else {
      // Still going in the same direction.
      holdTime++;
    }

    // TODO(bob): Kinda hackish.
    // Determine which frames should actually move the hero. The numbers here
    // gradually accelerate until eventually the hero moves at every frame.
    shouldMove() {
      if (holdTime == 0) return true;
      if (holdTime == 8) return true;
      if (holdTime == 16) return true;
      if (holdTime == 23) return true;
      if (holdTime == 30) return true;
      if (holdTime == 36) return true;
      if (holdTime == 42) return true;
      if (holdTime == 47) return true;
      if (holdTime == 52) return true;
      if (holdTime == 56) return true;
      if (holdTime == 60) return true;
      if (holdTime == 63) return true;
      if (holdTime == 66) return true;
      if (holdTime == 68) return true;
      if (holdTime >= 70) return true;

      return false;
    }

    if (currentDirection == null) return null;
    if (!shouldMove()) return null;

    switch (currentDirection) {
      case Direction.NW:   return new MoveAction(new Vec(-1, -1));
      case Direction.N:    return new MoveAction(new Vec(0, -1));
      case Direction.NE:   return new MoveAction(new Vec(1, -1));
      case Direction.W:    return new MoveAction(new Vec(-1, 0));
      case Direction.NONE: return new MoveAction(new Vec(0, 0));
      case Direction.E:    return new MoveAction(new Vec(1, 0));
      case Direction.SW:   return new MoveAction(new Vec(-1, 1));
      case Direction.S:    return new MoveAction(new Vec(0, 1));
      case Direction.SE:   return new MoveAction(new Vec(1, 1));
    }
  }
}

/// A keyboard is the lowest-level mapping from raw keyboard input to meaningful
/// use input. It listens to the raw DOM key events and keeps track of which
/// keys are currently pressed and which are not.
class Keyboard {
  final Set<int> _pressed;

  Keyboard(Element element)
  : _pressed = new Set<int>()
  {
    element.on.keyDown.add(keyDown);
    element.on.keyUp.add(keyUp);
  }

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

  void keyDown(event) => _pressed.add(event.keyCode);
  void keyUp(event) => _pressed.remove(event.keyCode);
}

/// Raw key codes. These code straight from the DOM events.
class KeyCode {
  static final SHIFT      = 16;
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
