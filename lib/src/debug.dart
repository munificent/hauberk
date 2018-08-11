import 'dart:collection';
import 'dart:math' as math;

import 'engine.dart';

/// A class for storing debugging information.
///
/// Unlike the rest of the engine, this is static state to make it easier for
/// the engine to punch debug info all the way to where the UI can get it. It
/// should not be used outside of a debugging scenario.
class Debug {
  static const enabled = false;

  /// If true, all monsters are rendered, regardless of in-game visibility.
  static bool showAllMonsters = false;

  static bool showHeroVolume = false;

  static final Map<Monster, _MonsterLog> _monsters = {};

  /// The current game screen.
  ///
  /// Typed as Object so that this library isn't coupled to the UI.
  static Object _gameScreen;
  static Object get gameScreen => _gameScreen;

  static void bindGameScreen(Object screen) {
    _gameScreen = screen;
    _monsters.clear();
  }

  /// Appends [message] to the debug log for [monster].
  static void monsterLog(Monster monster, String message) {
    if (!enabled) return;

    var monsterLog = _monsters.putIfAbsent(monster, () => _MonsterLog(monster));
    monsterLog.add(message);
  }

  /// Appends a new [value] for [stat] for [monster].
  ///
  /// The value should range from 0.0 to 1.0. If there is a descriptive [reason]
  /// for the value, that can be provided too.
  static void monsterStat(Monster monster, String stat, num value,
      [String reason]) {
    if (!enabled) return;

    var monsterLog = _monsters.putIfAbsent(monster, () => _MonsterLog(monster));
    var stats = monsterLog.stats.putIfAbsent(stat, () => Queue());
    stats.add(value);
    if (stats.length > 20) stats.removeFirst();

    monsterReason(monster, stat, reason);
  }

  /// Updates [stat]'s [reason] text without appending a new value.
  static void monsterReason(Monster monster, String stat, String reason) {
    if (!enabled) return;

    var monsterLog = _monsters.putIfAbsent(monster, () => _MonsterLog(monster));
    monsterLog.statReason[stat] = reason;
  }

  /// Gets the debug info for [monster].
  static String monsterInfo(Monster monster) {
    if (!enabled || _gameScreen == null) return null;

    var log = _monsters[monster];
    if (log == null) return null;
    return log.toString();
  }
}

class _MonsterLog {
  final Monster monster;
  final Queue<String> log = Queue<String>();

  final Map<String, Queue<num>> stats = {};
  final Map<String, String> statReason = {};

  _MonsterLog(this.monster);

  void add(String logItem) {
    log.add(logItem);
    if (log.length > 10) log.removeFirst();
  }

  String toString() {
    var buffer = StringBuffer();

    buffer.write(monster.breed.name);

    var state = "asleep";
    if (monster.isAfraid) {
      state = "afraid";
    } else if (monster.isAwake) {
      state = "awake";
    }
    buffer.writeln(" ($state)");

    var statNames = stats.keys.toList();
    statNames.sort();
    var length =
        statNames.fold<int>(0, (length, name) => math.max(length, name.length));

    var barChars = " ▁▂▃▄▅▆▇█";
    for (var name in statNames) {
      var bar = "${name.padRight(length)} ";
      var showBar = false;

      var values = stats[name];
      for (var value in values) {
        var i = (value * barChars.length).ceil().clamp(0, barChars.length - 1);
        bar += barChars[i];
        if (i > 0) showBar = true;
      }

      if (values.isNotEmpty) {
        bar += " ${values.last.toStringAsFixed(4).padLeft(6)}";
      }

      if (statReason[name] != null) {
        bar += " ${statReason[name]}";
        showBar = true;
      }

      if (showBar) buffer.writeln(bar);
    }

    buffer.writeAll(log, "\n");
    return buffer.toString();
  }
}
