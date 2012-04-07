#library('roguekit-content.dart');

#import('engine.dart');
#import('ui.dart');

#source('content/items.dart');
#source('content/monsters.dart');
#source('content/territories.dart');

Content createContent() {
  final breeds = new MonsterBuilder().build();
  final items = new ItemBuilder().build();
  final territories = new TerritoryBuilder(breeds, items).build();

  return new Content(territories);
}

/// Base class for a builder that provides a DSL for creating game content.
class ContentBuilder {
  Attack attack(String verb, int damage) => new Attack(verb, damage);

  Glyph black(String char)       => new Glyph(char, Color.BLACK);
  Glyph white(String char)       => new Glyph(char, Color.WHITE);
  Glyph lightGray(String char)   => new Glyph(char, Color.LIGHT_GRAY);
  Glyph gray(String char)        => new Glyph(char, Color.GRAY);
  Glyph darkGray(String char)    => new Glyph(char, Color.DARK_GRAY);
  Glyph lightRed(String char)    => new Glyph(char, Color.LIGHT_RED);
  Glyph red(String char)         => new Glyph(char, Color.RED);
  Glyph darkRed(String char)     => new Glyph(char, Color.DARK_RED);
  Glyph lightOrange(String char) => new Glyph(char, Color.LIGHT_ORANGE);
  Glyph orange(String char)      => new Glyph(char, Color.ORANGE);
  Glyph darkOrange(String char)  => new Glyph(char, Color.DARK_ORANGE);
  Glyph lightGold(String char)   => new Glyph(char, Color.LIGHT_GOLD);
  Glyph gold(String char)        => new Glyph(char, Color.GOLD);
  Glyph darkGold(String char)    => new Glyph(char, Color.DARK_GOLD);
  Glyph lightYellow(String char) => new Glyph(char, Color.LIGHT_YELLOW);
  Glyph yellow(String char)      => new Glyph(char, Color.YELLOW);
  Glyph darkYellow(String char)  => new Glyph(char, Color.DARK_YELLOW);
  Glyph lightGreen(String char)  => new Glyph(char, Color.LIGHT_GREEN);
  Glyph green(String char)       => new Glyph(char, Color.GREEN);
  Glyph darkGreen(String char)   => new Glyph(char, Color.DARK_GREEN);
  Glyph lightAqua(String char)   => new Glyph(char, Color.LIGHT_AQUA);
  Glyph aqua(String char)        => new Glyph(char, Color.AQUA);
  Glyph darkAqua(String char)    => new Glyph(char, Color.DARK_AQUA);
  Glyph lightBlue(String char)   => new Glyph(char, Color.LIGHT_BLUE);
  Glyph blue(String char)        => new Glyph(char, Color.BLUE);
  Glyph darkBlue(String char)    => new Glyph(char, Color.DARK_BLUE);
  Glyph lightPurple(String char) => new Glyph(char, Color.LIGHT_PURPLE);
  Glyph purple(String char)      => new Glyph(char, Color.PURPLE);
  Glyph darkPurple(String char)  => new Glyph(char, Color.DARK_PURPLE);
  Glyph lightBrown(String char)  => new Glyph(char, Color.LIGHT_BROWN);
  Glyph brown(String char)       => new Glyph(char, Color.BROWN);
  Glyph darkBrown(String char)   => new Glyph(char, Color.DARK_BROWN);
}
