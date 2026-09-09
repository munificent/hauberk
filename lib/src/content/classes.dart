import '../engine.dart';
import 'item/drops.dart';
import 'powers.dart';
import 'skill/skills.dart';

class Classes {
  // TODO: Better starting items?

  /// All of the known classes.
  static final List<HeroClass> all = [
    _class(
      "Adventurer",
      parseDrop("item"),
      "No special birthright, training, or inclination is needed to become "
          "an adventurer, simply the courage (or foolhardiness) to brave the "
          "wilds and live on one's wits. Adventurers are flexible and "
          "resourceful. They are masters of nothing, but able to learn a "
          "little of everything.",
      [
        Foolhardy(),
        // TODO: Another.
      ],
      {
        Domains.archery: 5,
        Domains.body: 5,
        Domains.spell: 5,
        Domains.weaponry: 5,
      },
    ),

    _class(
      "Barbarian",
      parseDrop("weapon"),
      "TODO",
      [
        DualWield(),
        // TODO: Another class power.
      ],
      {Domains.archery: 1, Domains.body: Skill.baseMax, Domains.weaponry: 5},
    ),

    _class(
      "Warrior",
      parseDrop("weapon"),
      "It's not that warriors are "
          "stupid. Many are, in fact, quite intelligent. It's just that they "
          "tend to apply most of that intelligence towards deciding which "
          "weapon is best suited for splitting a monster's head open.\n\n"
          "Warriors rely on the might of their bodies and the reassuring heft "
          "of their equipment. While they aren't above using a little magic "
          "here and there, they're most comfortable when those supernatural "
          "forces are safely ensconced in a piece of familiar gear.",
      const [
        // TODO: Come up with class powers.
      ],
      {
        Domains.archery: Skill.baseMax,
        Domains.body: 2,
        Domains.weaponry: Skill.baseMax,
      },
    ),

    _class(
      "Mage",
      // TODO: If we bring back spellbooks, do one here.
      parseDrop("item"),
      "Where others rightly fear the awesome power and unpredictability of "
          "magic, mages see it as a source of personal power and glory. Magic "
          "demands great sacrifices of anyone who dares to wield it directly. "
          "Mages who have devoted their lives to it have little time to master "
          "other arts and skills. But the rewards in return can be great for "
          "anyone willing to dance with the raw forces of nature (as well as "
          "some less natural forces).",
      const [
        // TODO: Come up with class powers.
      ],
      {Domains.archery: 1, Domains.spell: Skill.baseMax},
    ),

    // TODO: Rogues. Priests. Subclasses.
  ];
}

HeroClass _class(
  String name,
  Drop startingItems,
  String description,
  List<Power> powers,
  Map<Domain, int> domainCaps,
) {
  return HeroClass(name, description, domainCaps, powers, startingItems);
}
