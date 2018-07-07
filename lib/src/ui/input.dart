/// Enum class defining the high-level inputs from the user.
///
/// Physical keys on the keyboard are mapped to these, which the user interface
/// then interprets.
class Input {
  /// Rests in the level, selects a menu item.
  static const ok = Input("ok");

  // TODO: Unify cancel, forfeit, and quit?

  static const cancel = Input("cancel");
  static const forfeit = Input("forfeit");

  /// Exit the successfully completed level.
  static const quit = Input("quit");

  /// Open nearby doors, chests, etc.
  static const open = Input("open");

  /// Close nearby doors.
  static const close = Input("close");

  static const drop = Input("drop");
  static const use = Input("use");
  static const pickUp = Input("pickUp");
  static const toss = Input("toss");
  static const swap = Input("swap");
  static const unequip = Input("unequip");

  static const heroInfo = Input("heroInfo");
  static const selectSkill = Input("selectSkill");
  static const editSkills = Input("editSkills");

  /// Directional inputs.
  ///
  /// These are used both for navigating in the level and menu screens.
  static const n = Input("n");
  static const ne = Input("ne");
  static const e = Input("e");
  static const se = Input("se");
  static const s = Input("s");
  static const sw = Input("sw");
  static const w = Input("w");
  static const nw = Input("nw");

  /// Rest repeatedly.
  static const rest = Input("rest");

  static const runN = Input("runN");
  static const runNE = Input("runNE");
  static const runE = Input("runE");
  static const runSE = Input("runSE");
  static const runS = Input("runS");
  static const runSW = Input("runSW");
  static const runW = Input("runW");
  static const runNW = Input("runNW");

  /// Fire the last selected skill.
  static const fire = Input("fire");

  static const fireN = Input("fireN");
  static const fireNE = Input("fireNE");
  static const fireE = Input("fireE");
  static const fireSE = Input("fireSE");
  static const fireS = Input("fireS");
  static const fireSW = Input("fireSW");
  static const fireW = Input("fireW");
  static const fireNW = Input("fireNW");

  /// Open the wizard cheat menu.
  static const wizard = Input("wizard");

  final String name;

  const Input(this.name);
}
