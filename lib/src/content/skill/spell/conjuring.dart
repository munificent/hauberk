import '../../../engine.dart';

import '../../action/teleport.dart';

class Flee extends Spell implements ActionSkill {
  String get description => "Teleports the hero a short distance away.";
  String get name => "Flee";
  int get baseComplexity => 10;
  int get baseFocusCost => 6;
  int get range => 8;

  Action onGetAction(Game game) => new TeleportAction(range);
}

class Escape extends Spell implements ActionSkill {
  String get description => "Teleports the hero away.";
  String get name => "Escape";
  int get baseComplexity => 15;
  int get baseFocusCost => 14;
  int get range => 16;

  Action onGetAction(Game game) => new TeleportAction(range);
}