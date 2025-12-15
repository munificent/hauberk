import '../../engine.dart';
import '../action/teleport.dart';
import '../spells.dart';

List<Spell> conjuringSpells(Skill conjuringSkill) {
  // TODO: These spells are all kind of similar and boring. Might be good if
  // they had some differences. Maybe some could try to teleport specifically
  // far away from monsters, etc.
  return [
    ActionSpell(
      conjuringSkill,
      "Flee",
      description: "Teleports the hero a short distance away.",
      spellLevel: 1,
      focus: 16,
      (spell, game, level) => TeleportAction(8),
    ),
    ActionSpell(
      conjuringSkill,
      "Escape",
      description: "Teleports the hero away.",
      spellLevel: 2,
      focus: 25,
      (spell, game, level) => TeleportAction(16),
    ),
    ActionSpell(
      conjuringSkill,
      "Disappear",
      description: "Moves the hero across the dungeon.",
      spellLevel: 4,
      focus: 50,
      (spell, game, level) => TeleportAction(100),
    ),
  ];
}
