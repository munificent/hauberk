import 'builder.dart';

void aquatic() {
  // Grass.
  category(1.0, themes: "aquatic");
  furnishing(Symmetry.rotate90, "*", """
    ≈≈
    ≈*""");

  furnishing(Symmetry.rotate90, "*", """
    ≈
    *""");

  category(0.2, themes: "aquatic");
  furnishing(Symmetry.rotate90, "*", """
    *""");

  // Piers.
  category(0.03, themes: "aquatic");
  furnishing(Symmetry.rotate90, "=", """
    '≈≈≈
    '==≈
    '≈≈≈""");

  furnishing(Symmetry.rotate90, "=", """
    '≈≈≈≈
    '===≈
    '≈≈≈≈""");

  furnishing(Symmetry.rotate90, "=", """
    '≈≈≈≈≈
    '====≈
    '≈≈≈≈≈""");

  // Stepping stones.
  category(0.2, themes: "aquatic");
  furnishing(Symmetry.rotate90, "•", """
    '•""");
  furnishing(Symmetry.rotate90, "•", """
    ''
    '•""");

  category(0.1, themes: "aquatic");
  furnishing(Symmetry.rotate90, "•", """
    o•""");
  furnishing(Symmetry.rotate90, "•", """
    ≈•
    o≈""");
}
