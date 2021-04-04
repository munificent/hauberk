import '../../../engine.dart';

import '../../action/detection.dart';

class SenseItems extends Spell with ActionSkill {
  String get description => "Detect nearby items.";
  String get name => "Sense Items";
  int get baseComplexity => 17;
  int get baseFocusCost => 40;
  int get range => 20;

  Action onGetAction(Game game, int level) =>
      DetectAction([DetectType.item], range);
}
