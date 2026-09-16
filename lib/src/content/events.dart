import '../engine.dart';

class Events {
  /// One step of an elemental bolt.
  static const bolt = EventType("bolt");

  /// One step of an icicle spell.
  static const icicle = EventType("icicle");

  /// The leading edge of a cone.
  static const cone = EventType("cone");

  /// An [Actor] was healed.
  static const heal = EventType("heal");

  /// Something in the level was detected.
  static const detect = EventType("detect");

  /// An actor was perceived.
  static const perceive = EventType("perceive");

  /// A floor tile was magically explored.
  static const map = EventType("map");

  /// An [Actor] teleported.
  static const teleport = EventType("teleport");

  /// A new [Actor] was spawned by another.
  static const spawn = EventType("spawn");

  /// [Actor] has polymorphed into another breed.
  static const polymorph = EventType("polymorph");

  /// An [Actor] howls.
  static const howl = EventType("howl");

  /// An [Actor] was blown by wind.
  static const wind = EventType("wind");

  /// A club's bash attack moves an actor.
  static const knockBack = EventType("knockBack");

  /// An axe's slash attack hits a tile.
  static const slash = EventType("slash");

  /// A spear's stab attack hits a tile.
  static const stab = EventType("stab");

  static const openBarrel = EventType("openBarrel");
}
