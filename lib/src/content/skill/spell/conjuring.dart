import '../../../engine.dart';

import '../../action/teleport.dart';

class Flee extends Spell with ActionSkill {
  String get description => "Teleports the hero a short distance away.";
  String get name => "Flee";
  int get baseComplexity => 10;
  int get baseFocusCost => 16;
  int get range => 8;

  Action onGetAction(Game game, int level) => TeleportAction(range);
}

class Escape extends Spell with ActionSkill {
  String get description => "Teleports the hero away.";
  String get name => "Escape";
  int get baseComplexity => 15;
  int get baseFocusCost => 25;
  int get range => 16;

  Action onGetAction(Game game, int level) => TeleportAction(range);
}

class Disappear extends Spell with ActionSkill {
  String get description => "Moves the hero across the dungeon.";
  String get name => "Disappear";
  int get baseComplexity => 30;
  int get baseFocusCost => 50;
  int get range => 100;

  Action onGetAction(Game game, int level) => TeleportAction(range);
}

// TODO: These spells are all kind of similar and boring. Might be good if they
// had some differences. Maybe some could try to teleport specifically far away
// from monsters, etc.
