#library('roguekit-content.dart');

#import('engine.dart');
#import('ui.dart');

#source('content/items.dart');
#source('content/monsters.dart');

// TODO(bob): Move this class to engine (and only this one).
/// Defines the actual content for the game: the breeds, items, etc. that
/// define the play experience.
class Content {
  final List<Breed> breeds;
  final List<ItemType> itemTypes;

  Content()
  : breeds = <Breed>[],
    itemTypes = <ItemType>[];
}

Content createContent() {
  final content = new Content();
  new MonsterBuilder(content).build();
  new ItemBuilder(content).build();
  return content;
}

/// Base class for a builder that provides a DSL for creating game content.
class ContentBuilder {
  final Content content;
  ContentBuilder(this.content);

  Attack attack(String verb, int damage) => new Attack(verb, damage);

  Glyph white(String char) => new Glyph(char, Color.WHITE);
  Glyph brown(String char) => new Glyph(char, Color.BROWN);
  Glyph lightBlue(String char) => new Glyph(char, Color.LIGHT_BLUE);
  Glyph lightBrown(String char) => new Glyph(char, Color.LIGHT_BROWN);
  Glyph lightGreen(String char) => new Glyph(char, Color.LIGHT_GREEN);
}
