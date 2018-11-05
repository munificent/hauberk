import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
//import 'blast.dart';
import '../stage/painter.dart';
import 'cave.dart';
import 'catacomb.dart';
import 'room.dart';
import 'water.dart';

// TODO: Generate magical shrine/chests that let the player choose from one
// of a few items. This should help reduce the number of useless-for-this-hero
// items that are dropped.

abstract class Decor {
  static void initialize() {
    all.defineTags("built/room/dungeon");
    all.defineTags("built/room/keep");
    all.defineTags("catacomb");
    all.defineTags("cave/glowing-moss");
    all.defineTags("water");

    caveDecor();
    catacombDecor();
    roomDecor();
    waterDecor();

    // TODO: Doesn't look great. Remove or redo.
//    all.addUnnamed(Blast(), 1, 0.01, "laboratory");
  }

  static Decor choose(int depth, String theme) {
    if (!all.tagExists(theme)) return null;
    return all.tryChoose(depth, tag: theme);
  }

  static final ResourceSet<Decor> all = ResourceSet();

  bool canPlace(Painter painter, Vec pos);

  /// Adds this decor at [pos].
  void place(Painter painter, Vec pos);
}
