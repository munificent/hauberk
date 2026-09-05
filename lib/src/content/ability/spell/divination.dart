import '../../action/detection.dart';
import '../../skill/spell_school.dart';
import 'spell.dart';

List<Spell> divinationSpells() {
  return [
    ActionSpell(
      "Sense Items",
      SpellSchool.divination,
      description: "Detect nearby items.",
      spellLevel: 1,
      focus: 40,
      (spell, game) => DetectAction([DetectType.item], 20),
    ),
  ];
}
