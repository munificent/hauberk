library hauberk.content.builder;

import 'package:malison/malison.dart';

import '../engine.dart';

/// Creates a new [Attack].
Attack attack(String verb, int damage, [Element element = Element.NONE,
    Noun noun]) {
  return new Attack(verb, damage, element, noun);
}

Glyph black(char, [Color back = Color.BLACK])       => new Glyph.fromDynamic(char, Color.BLACK, back);
Glyph white(char, [Color back = Color.BLACK])       => new Glyph.fromDynamic(char, Color.WHITE, back);
Glyph lightGray(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.LIGHT_GRAY, back);
Glyph gray(char, [Color back = Color.BLACK])        => new Glyph.fromDynamic(char, Color.GRAY, back);
Glyph darkGray(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.DARK_GRAY, back);
Glyph lightRed(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.LIGHT_RED, back);
Glyph red(char, [Color back = Color.BLACK])         => new Glyph.fromDynamic(char, Color.RED, back);
Glyph darkRed(char, [Color back = Color.BLACK])     => new Glyph.fromDynamic(char, Color.DARK_RED, back);
Glyph lightOrange(char, [Color back = Color.BLACK]) => new Glyph.fromDynamic(char, Color.LIGHT_ORANGE, back);
Glyph orange(char, [Color back = Color.BLACK])      => new Glyph.fromDynamic(char, Color.ORANGE, back);
Glyph darkOrange(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.DARK_ORANGE, back);
Glyph lightGold(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.LIGHT_GOLD, back);
Glyph gold(char, [Color back = Color.BLACK])        => new Glyph.fromDynamic(char, Color.GOLD, back);
Glyph darkGold(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.DARK_GOLD, back);
Glyph lightYellow(char, [Color back = Color.BLACK]) => new Glyph.fromDynamic(char, Color.LIGHT_YELLOW, back);
Glyph yellow(char, [Color back = Color.BLACK])      => new Glyph.fromDynamic(char, Color.YELLOW, back);
Glyph darkYellow(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.DARK_YELLOW, back);
Glyph lightGreen(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.LIGHT_GREEN, back);
Glyph green(char, [Color back = Color.BLACK])       => new Glyph.fromDynamic(char, Color.GREEN, back);
Glyph darkGreen(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.DARK_GREEN, back);
Glyph lightAqua(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.LIGHT_AQUA, back);
Glyph aqua(char, [Color back = Color.BLACK])        => new Glyph.fromDynamic(char, Color.AQUA, back);
Glyph darkAqua(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.DARK_AQUA, back);
Glyph lightBlue(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.LIGHT_BLUE, back);
Glyph blue(char, [Color back = Color.BLACK])        => new Glyph.fromDynamic(char, Color.BLUE, back);
Glyph darkBlue(char, [Color back = Color.BLACK])    => new Glyph.fromDynamic(char, Color.DARK_BLUE, back);
Glyph lightPurple(char, [Color back = Color.BLACK]) => new Glyph.fromDynamic(char, Color.LIGHT_PURPLE, back);
Glyph purple(char, [Color back = Color.BLACK])      => new Glyph.fromDynamic(char, Color.PURPLE, back);
Glyph darkPurple(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.DARK_PURPLE, back);
Glyph lightBrown(char, [Color back = Color.BLACK])  => new Glyph.fromDynamic(char, Color.LIGHT_BROWN, back);
Glyph brown(char, [Color back = Color.BLACK])       => new Glyph.fromDynamic(char, Color.BROWN, back);
Glyph darkBrown(char, [Color back = Color.BLACK])   => new Glyph.fromDynamic(char, Color.DARK_BROWN, back);
