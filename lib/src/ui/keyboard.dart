library hauberk.ui.keyboard;

import 'dart:html' as html;

/// A keyboard is the lowest-level mapping from raw keyboard input to meaningful
/// use input. It listens to the raw DOM key events and keeps track of which
/// keys are currently pressed and which are not.
class Keyboard {
  bool _shift;
  bool _control;
  bool _option;

  int _lastPressed;

  Keyboard(html.Element element) {
    element.onKeyDown.listen(keyDown);
    element.onKeyUp.listen(keyUp);
  }

  /// Gets whether or not the shift modifier key is currently pressed.
  bool get shift => _shift;

  /// Gets whether or not the control modifier key is currently pressed.
  bool get control => _control;

  /// Gets whether or not the option modifier key is currently pressed.
  bool get option => _option;

  int get lastPressed => _lastPressed;

  void keyDown(event) {
    if (event.keyCode == KeyCode.SHIFT) {
      _shift = true;
    } else if (event.keyCode == KeyCode.CONTROL) {
      _control = true;
    } else if (event.keyCode == KeyCode.OPTION) {
      _option = true;
    } {
      _lastPressed = event.keyCode;
    }

    // Don't let the browser handle the tab or backspace key.
    if (event.keyCode == KeyCode.TAB ||
        event.keyCode == KeyCode.DELETE) {
      event.preventDefault();
    }
  }

  void keyUp(event) {
    if (event.keyCode == KeyCode.SHIFT) {
      _shift = false;
    } else if (event.keyCode == KeyCode.CONTROL) {
      _control = false;
    } else if (event.keyCode == KeyCode.OPTION) {
      _option = false;
    }
  }

  void afterUpdate() {
    _lastPressed = null;
  }
}

/// Raw key codes. These code straight from the DOM events.
class KeyCode {
  static const DELETE     = 8;
  static const TAB        = 9;
  static const ENTER      = 13;
  static const SHIFT      = 16;
  static const CONTROL    = 17;
  static const OPTION     = 18;
  static const ESCAPE     = 27;
  static const SPACE      = 32;

  static const LEFT       = 37;
  static const UP         = 38;
  static const RIGHT      = 39;
  static const DOWN       = 40;

  static const ZERO       = 48;
  static const ONE        = 49;
  static const TWO        = 50;
  static const THREE      = 51;
  static const FOUR       = 52;
  static const FIVE       = 53;
  static const SIX        = 54;
  static const SEVEN      = 55;
  static const EIGHT      = 56;
  static const NINE       = 57;

  static const A          = 65;
  static const B          = 66;
  static const C          = 67;
  static const D          = 68;
  static const E          = 69;
  static const F          = 70;
  static const G          = 71;
  static const H          = 72;
  static const I          = 73;
  static const J          = 74;
  static const K          = 75;
  static const L          = 76;
  static const M          = 77;
  static const N          = 78;
  static const O          = 79;
  static const P          = 80;
  static const Q          = 81;
  static const R          = 82;
  static const S          = 83;
  static const T          = 84;
  static const U          = 85;
  static const V          = 86;
  static const W          = 87;
  static const X          = 88;
  static const Y          = 89;
  static const Z          = 90;

  static const SEMICOLON  = 186;
  static const COMMA      = 188;
  static const PERIOD     = 190;
  static const SLASH      = 191;
  static const APOSTROPHE = 222;
}
