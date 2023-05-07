import '../../../engine.dart';

import '../../action/teleport.dart';

class Flee extends Spell with ActionSkill {
  @override
  String get description => "Teleports the hero a short distance away.";
  @override
  String get name => "Flee";
  @override
  int get baseComplexity => 10;
  @override
  int get baseFocusCost => 16;
  @override
  int get range => 8;

  @override
  Action onGetAction(Game game, int level) => TeleportAction(range);
}

class Escape extends Spell with ActionSkill {
  @override
  String get description => "Teleports the hero away.";
  @override
  String get name => "Escape";
  @override
  int get baseComplexity => 15;
  @override
  int get baseFocusCost => 25;
  @override
  int get range => 16;

  @override
  Action onGetAction(Game game, int level) => TeleportAction(range);
}

class Disappear extends Spell with ActionSkill {
  @override
  String get description => "Moves the hero across the dungeon.";
  @override
  String get name => "Disappear";
  @override
  int get baseComplexity => 30;
  @override
  int get baseFocusCost => 50;
  @override
  int get range => 100;

  @override
  Action onGetAction(Game game, int level) => TeleportAction(range);
}

// TODO: These spells are all kind of similar and boring. Might be good if they
// had some differences. Maybe some could try to teleport specifically far away
// from monsters, etc.
