import '../../action/detection.dart';
import 'spell.dart';

List<Spell> divinationSpells() {
  return [
    ActionSpell(
      "Sense Items",
      description: "Detect nearby items.",
      complexity: 17,
      focus: 40,
      range: 20,
      (spell, game, level) => DetectAction([DetectType.item], spell.range),
    )
  ];
}
