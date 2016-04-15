import 'package:malison/malison.dart';

import '../engine.dart';

/// Creates a new [Attack].
Attack attack(String verb, int damage, [Element element, Noun noun]) {
  return new Attack(verb, damage, element, noun);
}

Glyph black(char, [Color back = Color.black])       => new Glyph.fromDynamic(char, Color.black, back);
Glyph white(char, [Color back = Color.black])       => new Glyph.fromDynamic(char, Color.white, back);
Glyph lightGray(char, [Color back = Color.black])   => new Glyph.fromDynamic(char, Color.lightGray, back);
Glyph gray(char, [Color back = Color.black])        => new Glyph.fromDynamic(char, Color.gray, back);
Glyph darkGray(char, [Color back = Color.black])    => new Glyph.fromDynamic(char, Color.darkGray, back);
Glyph lightRed(char, [Color back = Color.black])    => new Glyph.fromDynamic(char, Color.lightRed, back);
Glyph red(char, [Color back = Color.black])         => new Glyph.fromDynamic(char, Color.red, back);
Glyph darkRed(char, [Color back = Color.black])     => new Glyph.fromDynamic(char, Color.darkRed, back);
Glyph lightOrange(char, [Color back = Color.black]) => new Glyph.fromDynamic(char, Color.lightOrange, back);
Glyph orange(char, [Color back = Color.black])      => new Glyph.fromDynamic(char, Color.orange, back);
Glyph darkOrange(char, [Color back = Color.black])  => new Glyph.fromDynamic(char, Color.darkOrange, back);
Glyph lightGold(char, [Color back = Color.black])   => new Glyph.fromDynamic(char, Color.lightGold, back);
Glyph gold(char, [Color back = Color.black])        => new Glyph.fromDynamic(char, Color.gold, back);
Glyph darkGold(char, [Color back = Color.black])    => new Glyph.fromDynamic(char, Color.darkGold, back);
Glyph lightYellow(char, [Color back = Color.black]) => new Glyph.fromDynamic(char, Color.lightYellow, back);
Glyph yellow(char, [Color back = Color.black])      => new Glyph.fromDynamic(char, Color.yellow, back);
Glyph darkYellow(char, [Color back = Color.black])  => new Glyph.fromDynamic(char, Color.darkYellow, back);
Glyph lightGreen(char, [Color back = Color.black])  => new Glyph.fromDynamic(char, Color.lightGreen, back);
Glyph green(char, [Color back = Color.black])       => new Glyph.fromDynamic(char, Color.green, back);
Glyph darkGreen(char, [Color back = Color.black])   => new Glyph.fromDynamic(char, Color.darkGreen, back);
Glyph lightAqua(char, [Color back = Color.black])   => new Glyph.fromDynamic(char, Color.lightAqua, back);
Glyph aqua(char, [Color back = Color.black])        => new Glyph.fromDynamic(char, Color.aqua, back);
Glyph darkAqua(char, [Color back = Color.black])    => new Glyph.fromDynamic(char, Color.darkAqua, back);
Glyph lightBlue(char, [Color back = Color.black])   => new Glyph.fromDynamic(char, Color.lightBlue, back);
Glyph blue(char, [Color back = Color.black])        => new Glyph.fromDynamic(char, Color.blue, back);
Glyph darkBlue(char, [Color back = Color.black])    => new Glyph.fromDynamic(char, Color.darkBlue, back);
Glyph lightPurple(char, [Color back = Color.black]) => new Glyph.fromDynamic(char, Color.lightPurple, back);
Glyph purple(char, [Color back = Color.black])      => new Glyph.fromDynamic(char, Color.purple, back);
Glyph darkPurple(char, [Color back = Color.black])  => new Glyph.fromDynamic(char, Color.darkPurple, back);
Glyph lightBrown(char, [Color back = Color.black])  => new Glyph.fromDynamic(char, Color.lightBrown, back);
Glyph brown(char, [Color back = Color.black])       => new Glyph.fromDynamic(char, Color.brown, back);
Glyph darkBrown(char, [Color back = Color.black])   => new Glyph.fromDynamic(char, Color.darkBrown, back);
