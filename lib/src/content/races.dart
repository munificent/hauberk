import '../engine.dart';

class Races {
  /// All of the known races.
  static final List<Race> all = [
    _race(
      "Dwarf",
      strength: 1.3,
      agility: 0.6,
      vitality: 1.4,
      intellect: 0.7,
      description:
          "It takes a certain kind of person to be willing to spend their life "
          "deep under the Earth, toiling away in darkness. Dwarves aren't just "
          "willing, but delight in it. Solid, impenetrable and somewhat dim, "
          "dwarves have much in common with the mines they love.",
    ),
    _race(
      "Elf",
      strength: 0.9,
      agility: 1.1,
      vitality: 0.7,
      intellect: 1.3,
      description:
          "There are few things elves are not good at, as any elf will be "
          "quick to inform you. Clever, quick on their feet, and surprisingly "
          "strong for how they look. Which is radiantly beautiful, naturally.",
    ),
    // TODO: Make stats lower and enable them to fly?
    _race(
      "Fae",
      strength: 0.6,
      agility: 1.6,
      vitality: 0.7,
      intellect: 1.1,
      description:
          "What can be said about the fae folk that is known to be true? "
          "Dimunitive and easily harmed, they survive by cloaking themselves "
          "in fables, tricks, and subterfuge. Quick to anger and quick to "
          "forgive, the fae live each moment as if it may be their last, "
          "bright-burning flames all too aware of how easily they may be "
          "snuffed out.",
    ),
    _race(
      "Gnome",
      strength: 0.7,
      agility: 0.8,
      vitality: 1.0,
      intellect: 1.5,
      description:
          "Gnomes are gentle, quiet folk, difficult to arouse to anger (unless "
          "you interrupt one while reading). Most live a life of the mind, "
          "seeking knowledge more than adventure. But this insatiable desire "
          "for the former, on many occasions, leads them into the jaws of the "
          "latter.",
    ),
    _race(
      "Human",
      strength: 1.0,
      agility: 1.0,
      vitality: 1.0,
      intellect: 1.0,
      description:
          "Humans excel at nothing, but nor are they particularly weak in any "
          "area. Most other races consider humans sort of like mice: pesky "
          "creatures who seem do little but breed, which they do with "
          "great devotion.",
    ),
  ];

  static Race _race(
    String name, {
    required double strength,
    required double agility,
    required double vitality,
    required double intellect,
    required String description,
  }) {
    return Race(name, description, {
      Stat.strength: strength,
      Stat.agility: agility,
      Stat.vitality: vitality,
      Stat.intellect: intellect,
    });
  }
}
