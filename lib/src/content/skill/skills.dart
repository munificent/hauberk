import '../../engine.dart';
import 'archery.dart';
import 'battle_hardening.dart';
import 'bloodlust.dart';
import 'mastery.dart';
import 'spell_school.dart';

class Domains {
  // TODO: Probably don't want a separate domain for this. Should archery even
  // be a skill?
  static const archery = Domain("Archery");
  static const body = Domain("Body");
  // TODO: Split different kinds of spells into different domains.
  static const spell = Domain("Spell");
  static const weaponry = Domain("Weaponry");
}

class Skills {
  /// All of the skills in the game.
  static final List<Skill> all = [
    // Archery.
    Archery.instance,

    // Body.
    BattleHardening(),
    Bloodlust(),

    // Spells.
    SpellSchool.conjuring,
    SpellSchool.divination,
    SpellSchool.sorcery,

    // Weaponry.
    AxeMastery.instance,
    Bludgeoning.instance,
    KnifeFighting(),
    SpearMastery.instance,
    Swordfighting(),
    WhipMastery.instance,

    // TODO: More skills:
    // - Passively increases dodge.
    // - Backstabbing: Increases damage when attacking unaware monster. Also
    //   lowers sound when attacking unaware monster.
    // - Stealth: Lowers sound produced by hero.
    // - Something that increases chance of monster drops.

    // TODO: Getting rid of these as skills at least for now.
    // Slays.
    /*
    SlayDiscipline("Animals", "animal"),
    SlayDiscipline("Bugs", "bug"),
    SlayDiscipline("Dragons", "dragon"),
    SlayDiscipline("Fae Folk", "fae"),
    SlayDiscipline("Goblins", "goblin"),
    SlayDiscipline("Humans", "human"),
    SlayDiscipline("Jellies", "jelly"),
    SlayDiscipline("Kobolds", "kobold"),
    SlayDiscipline("Plants", "plant"),
    SlayDiscipline("Saurians", "saurian"),
    SlayDiscipline("Undead", "undead"),
    */
  ];

  static final Map<String, Skill> _byName = {
    for (var skill in all) skill.name: skill,
  };

  static Skill find(String name) {
    var skill = _byName[name];
    if (skill == null) throw ArgumentError("Unknown skill '$name'.");
    return skill;
  }
}
