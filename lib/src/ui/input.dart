/// Enum class defining the high-level inputs from the user.
///
/// Physical keys on the keyboard are mapped to these, which the user interface
/// then interprets.
class Input {
  /// Rests in the level, selects a menu item.
  static const ok = const Input("ok");

  // TODO: Unify cancel, forfeit, and quit?

  static const cancel = const Input("cancel");
  static const forfeit = const Input("forfeit");

  /// Exit the successfully completed level.
  static const quit = const Input("quit");

  /// Close nearby doors.
  static const closeDoor = const Input("closeDoor");

  static const drop = const Input("drop");
  static const use = const Input("use");
  static const pickUp = const Input("pickUp");
  static const toss = const Input("toss");
  static const swap = const Input("swap");

  static const selectCommand = const Input("selectCommand");
  static const heroInfo = const Input("heroInfo");
  static const editSkills = const Input("editSkills");

  /// Directional inputs.
  ///
  /// These are used both for navigating in the level and menu screens.
  static const n = const Input("n");
  static const ne = const Input("ne");
  static const e = const Input("e");
  static const se = const Input("se");
  static const s = const Input("s");
  static const sw = const Input("sw");
  static const w = const Input("w");
  static const nw = const Input("nw");

  /// Rest repeatedly.
  static const rest = const Input("rest");

  static const runN = const Input("runN");
  static const runNE = const Input("runNE");
  static const runE = const Input("runE");
  static const runSE = const Input("runSE");
  static const runS = const Input("runS");
  static const runSW = const Input("runSW");
  static const runW = const Input("runW");
  static const runNW = const Input("runNW");

  /// Fire the last selected skill.
  static const fire = const Input("fire");

  static const fireN = const Input("fireN");
  static const fireNE = const Input("fireNE");
  static const fireE = const Input("fireE");
  static const fireSE = const Input("fireSE");
  static const fireS = const Input("fireS");
  static const fireSW = const Input("fireSW");
  static const fireW = const Input("fireW");
  static const fireNW = const Input("fireNW");

  final String name;

  const Input(this.name);
}
