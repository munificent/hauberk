import '../tiles.dart';
import 'furnishing_builder.dart';

void caveDecor() {
  category(themes: "glowing-moss", cells: {
    "*": applyOpen(Tiles.glowingMoss),
  });

  furnishing(symmetry: Symmetry.rotate90, template: """
    #
    *""");

  furnishing(symmetry: Symmetry.rotate90, template: """
    ##
    #*""");

  furnishing(template: """
    ?.?
    .*.
    ?.?""");
}