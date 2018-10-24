import 'furnishing_builder.dart';
import '../tiles.dart';

void waterDecor() {
  // TODO: Get rid of this if we don't add shores.
  // Grass.
//  category(apply: "*", themes: "water");
//  furnishing(Symmetry.rotate90, """
//    ≈≈
//    ≈*""");
//
//  furnishing(Symmetry.rotate90, """
//    ≈
//    *""");
//
//  category(0.6, apply: "*", themes: "water");
//  furnishing(Symmetry.rotate90, """
//    *""");

/*
  // Piers.
  category(0.1, apply: "=", themes: "aquatic");
  furnishing(Symmetry.rotate90, """
    '≈≈≈
    '==≈
    '≈≈≈""");

  furnishing(Symmetry.rotate90, """
    '≈≈≈≈
    '===≈
    '≈≈≈≈""");

  furnishing(Symmetry.rotate90, """
    '≈≈≈≈≈
    '====≈
    '≈≈≈≈≈""");
*/

  // TODO: These don't work as well without shores.
  // Stepping stones.
  category(themes: "water", cells: {
    "*": apply(Tiles.steppingStone, over: Tiles.water),
    "o": require(Tiles.steppingStone),
  });

  furnishing(frequency: 0.6, symmetry: Symmetry.rotate90, template: """
    .*""");

  furnishing(frequency: 0.6, symmetry: Symmetry.rotate90, template: """
    ..
    .*""");

  furnishing(symmetry: Symmetry.rotate90, template: """
    o*""");
  furnishing(symmetry: Symmetry.rotate90, template: """
    ≈*
    o≈""");
}
