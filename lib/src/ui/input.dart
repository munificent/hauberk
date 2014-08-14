library hauberk.ui.input;

/// Enum class defining the high-level inputs from the user.
///
/// Physical keys on the keyboard are mapped to these, which the user interface
/// then interprets.
class Input {
  /// Rests in the level, selects a menu item.
  static const OK = const Input("OK");

  // TODO: Unify cancel, forfeit, and quit?

  static const CANCEL = const Input("CANCEL");
  static const FORFEIT = const Input("FORFEIT");

  /// Exit the successfully completed level.
  static const QUIT = const Input("QUIT");

  /// Close nearby doors.
  static const CLOSE_DOOR = const Input("CLOSE_DOOR");

  static const DROP = const Input("DROP");
  static const USE = const Input("USE");
  static const PICK_UP = const Input("PICK_UP");
  static const TOSS = const Input("TOSS");
  static const SWAP = const Input("SWAP");

  static const SELECT_COMMAND = const Input("SELECT_COMMAND");

  /// Directional inputs.
  ///
  /// These are used both for navigating in the level and menu screens.
  static const N  = const Input("N");
  static const NE  = const Input("NE");
  static const E  = const Input("E");
  static const SE  = const Input("SE");
  static const S  = const Input("S");
  static const SW  = const Input("SW");
  static const W  = const Input("W");
  static const NW  = const Input("NW");

  /// Rest repeatedly.
  static const REST = const Input("REST");

  static const RUN_N  = const Input("RUN_N");
  static const RUN_NE  = const Input("RUN_NE");
  static const RUN_E  = const Input("RUN_E");
  static const RUN_SE  = const Input("RUN_SE");
  static const RUN_S  = const Input("RUN_S");
  static const RUN_SW  = const Input("RUN_SW");
  static const RUN_W  = const Input("RUN_W");
  static const RUN_NW  = const Input("RUN_NW");

  /// Fire the last selected skill.
  static const FIRE = const Input("FIRE");

  static const FIRE_N  = const Input("FIRE_N");
  static const FIRE_NE  = const Input("FIRE_NE");
  static const FIRE_E  = const Input("FIRE_E");
  static const FIRE_SE  = const Input("FIRE_SE");
  static const FIRE_S  = const Input("FIRE_S");
  static const FIRE_SW  = const Input("FIRE_SW");
  static const FIRE_W  = const Input("FIRE_W");
  static const FIRE_NW  = const Input("FIRE_NW");

  final String name;

  const Input(this.name);
}
