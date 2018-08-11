import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../dungeon/dungeon.dart';
import '../themes.dart';
import 'blast.dart';
import 'furnishing.dart';

abstract class Decor {
  static void initialize() {
    Themes.defineTags(all);
    Furnishing.initialize();

    all.addUnnamed(Blast(), 1, 10.0, "laboratory");
  }

  static Decor choose(String theme) {
    if (!all.tagExists(theme)) return null;
    // TODO: Use depth.
    return all.tryChoose(1, theme);
  }

  static final ResourceSet<Decor> all = ResourceSet();

  bool canPlace(Dungeon dungeon, Vec pos);

  void place(Dungeon dungeon, Vec pos);
}
