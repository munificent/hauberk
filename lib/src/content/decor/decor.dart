import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
//import 'blast.dart';
import '../stage/painter.dart';
import 'furnishing.dart';

abstract class Decor {
  static void initialize() {
    all.defineTags("built/keep/room");
    all.defineTags("cave/glowing-moss");
    all.defineTags("water");

    Furnishing.initialize();

    // TODO: Doesn't look great. Remove or redo.
//    all.addUnnamed(Blast(), 1, 0.01, "laboratory");
  }

  static Decor choose(int depth, String theme) {
    if (!all.tagExists(theme)) return null;
    return all.tryChoose(depth, theme);
  }

  static final ResourceSet<Decor> all = ResourceSet();

  bool canPlace(Painter painter, Vec pos);

  /// Adds this decor at [pos].
  void place(Painter painter, Vec pos);
}
