import '../../../engine.dart';
import '../../action/teleport.dart';
import '../../skill/spell_school.dart';
import 'spell.dart';

List<Ability> conjuringSpells() {
  // TODO: These spells are all kind of similar and boring. Might be good if
  // they had some differences. Maybe some could try to teleport specifically
  // far away from monsters, etc.
  return [
    ActionSpell(
      "Flee",
      SpellSchool.divination,
      description: "Teleports the hero a short distance away.",
      spellLevel: 1,
      focus: 16,
      (spell, game) => TeleportAction(8),
    ),
    ActionSpell(
      "Escape",
      SpellSchool.divination,
      description: "Teleports the hero away.",
      spellLevel: 2,
      focus: 25,
      (spell, game) => TeleportAction(16),
    ),
    ActionSpell(
      "Disappear",
      SpellSchool.divination,
      description: "Moves the hero across the dungeon.",
      spellLevel: 4,
      focus: 50,
      (spell, game) => TeleportAction(100),
    ),
  ];
}
