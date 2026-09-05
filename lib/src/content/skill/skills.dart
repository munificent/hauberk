import '../../engine.dart';
import 'archery.dart';
import 'battle_hardening.dart';
import 'bloodlust.dart';
import 'dual_wield.dart';
import 'mastery.dart';
import 'spell_school.dart';

class Skills {
  /// All of the skills in the game.
  static final List<Skill> all = [
    // TODO: More skills:
    // - Passively increases dodge.
    // - Backstabbing: Increases damage when attacking unaware monster. Also
    //   lowers sound when attacking unaware monster.
    // - Stealth: Lowers sound produced by hero.
    // - Something that increases chance of monster drops.

    // Warrior skills.
    BattleHardening(),
    Bloodlust(),
    DualWield(),

    // Weapon masteries.
    Archery.instance,
    AxeMastery.instance,
    Bludgeoning.instance,
    KnifeFighting(),
    SpearMastery.instance,
    Swordfighting(),
    WhipMastery.instance,

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

    // Spell schools.
    SpellSchool.conjuring,
    SpellSchool.divination,
    SpellSchool.sorcery,
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
