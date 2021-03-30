import '../../../engine.dart';

import '../../action/detection.dart';

class SenseItems extends Spell implements ActionSkill {
  String get description => "Detect nearby items.";
  String get name => "Sense Items";
  int get baseComplexity => 17;
  int get baseFocusCost => 18;
  int get range => 20;

  Action onGetAction(Game game) => DetectAction([DetectType.item], range);
}
