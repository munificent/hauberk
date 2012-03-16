#library('roguekit-content.dart');

#import('engine.dart');
#import('ui.dart');

/// Defines the actual content for the game: the breeds, items, etc. that define
/// the play experience.
class Content {
  final List<Breed> breeds;

  Content()
  : breeds = <Breed>[];

  List<Breed> create() {
    breed('mouse', white('r'),
      [
        attack('bite[s]', 2),
        attack('scratch[es]', 1)
      ],
      maxHealth: 3,
      minScent: 0.001,
      meander: 5
    );

    breed('rat', darkOrange('r'),
      [
        attack('bite[s]', 3),
        attack('scratch[es]', 2)
      ],
      maxHealth: 4,
      minScent: 0.001,
      meander: 3
    );

    return breeds;
  }

  Breed breed(String name, Glyph appearance, List<Attack> attacks,
      [int maxHealth, int minScent = 1.0, int meander]) {
    final breed = new Breed(name, Gender.NEUTER, appearance, attacks,
        maxHealth: maxHealth, minScent: minScent, meander: meander);
    breeds.add(breed);
    return breed;
  }

  Attack attack(String verb, int damage) => new Attack(verb, damage);

  Glyph white(String char) => new Glyph(char, Color.WHITE);
  Glyph darkOrange(String char) => new Glyph(char, Color.DARK_ORANGE);
}