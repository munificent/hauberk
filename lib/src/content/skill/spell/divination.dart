import '../../../engine.dart';
import '../../action/detection.dart';
import 'spell.dart';

List<Spell> divinationSpells(Skill divinationSchool) {
  return [
    ActionSpell(
      divinationSchool,
      "Sense Items",
      description: "Detect nearby items.",
      spellLevel: 1,
      focus: 40,
      (spell, game, level) => DetectAction([DetectType.item], 20),
    ),
  ];
}
