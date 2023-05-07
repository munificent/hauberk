import '../../../engine.dart';

import '../../action/detection.dart';

class SenseItems extends Spell with ActionSkill {
  @override
  String get description => "Detect nearby items.";
  @override
  String get name => "Sense Items";
  @override
  int get baseComplexity => 17;
  @override
  int get baseFocusCost => 40;
  @override
  int get range => 20;

  @override
  Action onGetAction(Game game, int level) =>
      DetectAction([DetectType.item], range);
}
