import '../engine.dart';

class Races {
  static final dwarf = _race("Dwarf",
      strength: 30,
      agility: 10,
      fortitude: 30,
      intellect: 15,
      will: 25,
      description:
          "It takes a certain kind of person to be willing to spend their life "
          "deep in the bowels of the Earth, toiling away in darkness. Dwarves "
          "aren't just willing, but delight in it. Solid, impenetrable and, "
          "well, not very bright... perhaps it's no surprise that dwarves love "
          "mines so much when they have so much in common.");
  static final elf = _race("Elf",
      strength: 25,
      agility: 30,
      fortitude: 20,
      intellect: 25,
      will: 15,
      description:
          "There are few things elves are not good at, as any elf will be "
          "quick to inform you. Clever, quick on their feet, and surprisingly "
          "strong for how they look. Which is radiantly beautiful, naturally.");
  static final fae = _race("Fae",
      strength: 10,
      agility: 30,
      fortitude: 15,
      intellect: 25,
      will: 20,
      description:
          "What can be said about the fae folk that is known to be true? "
          "Dimunitive and easily harmed, they survive by cloaking themselves "
          "in fables, tricks, and subterfuge. Quick to anger, and quick to "
          "forgive, the fae live each moment as if it may be their last, "
          "bright-burning flames all too aware of how easily they may be "
          "snuffed out.");
  static final gnome = _race("Gnome",
      strength: 10,
      agility: 15,
      fortitude: 20,
      intellect: 35,
      will: 20,
      description:
          "Gnomes are gentle, quiet folk, difficult to arouse to anger (unless "
          "you interrupt one while reading). Most live a life of the mind, "
          "seeking knowledge more than adventure. But this insatiable desire "
          "for the former, on many occasions, leads them into the jaws of the "
          "latter.");
  static final human = _race("Human",
      strength: 20,
      agility: 20,
      fortitude: 20,
      intellect: 20,
      will: 20,
      description:
          "Humans excel at nothing, but nor are they particularly weak in any "
          "area. Most other races considers humans sort of like mice: pesky "
          "creatures who seem do little but breed, which they do with "
          "great devotion.");

  // TODO: Other races.

  /// All of the known skills.
  static final List<Race> all = [
    dwarf,
    elf,
    fae,
    gnome,
    human,
  ];

  static Race _race(String name,
      {int strength,
      int agility,
      int fortitude,
      int intellect,
      int will,
      String description}) {
    return new Race(name, description, {
      Attribute.strength: strength,
      Attribute.agility: agility,
      Attribute.fortitude: fortitude,
      Attribute.intellect: intellect,
      Attribute.will: will,
    });
  }
}
