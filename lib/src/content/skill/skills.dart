import '../../engine.dart';
import 'archery.dart';
import 'battle_hardening.dart';
import 'bloodlust.dart';
import 'mastery/axe.dart';
import 'mastery/bludgeoning.dart';
import 'mastery/dual_wield.dart';
import 'mastery/knife_fighting.dart';
import 'mastery/spear.dart';
import 'mastery/swordfighting.dart';
import 'mastery/whip.dart';
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
    Archery(),
    AxeMastery(),
    Bludgeoning(),
    KnifeFighting(),
    SpearMastery(),
    Swordfighting(),
    WhipMastery(),

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
    SpellSchool("Conjuring"),
    SpellSchool("Divination"),
    SpellSchool("Sorcery"),
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
