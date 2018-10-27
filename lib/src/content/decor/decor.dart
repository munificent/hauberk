import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
//import 'blast.dart';
import '../stage/painter.dart';
import 'furnishing.dart';

abstract class Decor {
  static void initialize() {
    all.defineTags("decor/built/dungeon/room");
    all.defineTags("decor/cave/glowing-moss");
    all.defineTags("decor/water");

    Furnishing.initialize();

    // TODO: Doesn't look great. Remove or redo.
//    all.addUnnamed(Blast(), 1, 0.01, "laboratory");
  }

  static Decor choose(String theme) {
    if (!all.tagExists(theme)) return null;
    // TODO: Use depth.
    return all.tryChoose(1, theme, includeParents: false);
  }

  static final ResourceSet<Decor> all = ResourceSet();

  bool canPlace(Painter painter, Vec pos);

  /// Adds this decor at [pos].
  void place(Painter painter, Vec pos);
}
