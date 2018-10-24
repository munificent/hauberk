import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../stage/architect.dart';
import '../themes.dart';
//import 'blast.dart';
import 'furnishing.dart';

abstract class Decor {
  static void initialize() {
    Themes.defineTags(all);
    Furnishing.initialize();

    // TODO: Doesn't look great. Remove or redo.
//    all.addUnnamed(Blast(), 1, 0.01, "laboratory");
  }

  static Decor choose(String theme) {
    if (!all.tagExists(theme)) return null;
    // TODO: Use depth.
    return all.tryChoose(1, theme);
  }

  static final ResourceSet<Decor> all = ResourceSet();

  bool canPlace(DecorPainter painter, Vec pos);

  /// Adds this decor at [pos].
  void place(DecorPainter painter, Vec pos);
}
