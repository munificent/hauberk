import '../engine.dart';

/// Defines the "theme" tags used to unify place themes and the monsters and
/// items that are spawned on them.
class Themes {
  static void defineTags<T>(ResourceSet<T> resources, [String root]) {
    root = (root == null) ? "" : "$root/";
    resources.defineTags("${root}nature/aquatic");
    resources.defineTags("${root}passage");
    resources.defineTags("${root}room/storage/closet");
    resources.defineTags("${root}room/storage/storeroom");
    resources.defineTags("${root}room/great-hall");
    resources.defineTags("${root}room/hall");
    resources.defineTags("${root}room/food/kitchen");
    resources.defineTags("${root}room/food/larder");
    resources.defineTags("${root}room/food/pantry");
    resources.defineTags("${root}room/chamber");
    resources.defineTags("${root}room/laboratory");
  }
}
