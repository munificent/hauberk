import '../../engine.dart';
import 'architect.dart';
import 'catacomb.dart';
import 'cavern.dart';
import 'dungeon.dart';
import 'lake.dart';
import 'river.dart';

class ArchitecturalStyle {
  static final ResourceSet<ArchitecturalStyle> _all = ResourceSet();
  static ResourceSet<ArchitecturalStyle> get all {
    if (_all.isEmpty) _initialize();
    return _all;
  }

  static void _initialize() {
    _all.defineTags("style");

    addStyle(String theme, int depth, double frequency,
        Architecture Function() _factory,
        {bool isAquatic}) {
      _all.addUnnamed(
          ArchitecturalStyle(theme, _factory, isAquatic: isAquatic),
          depth,
          frequency,
          "style");
    }

    // TODO: Define more.
    addStyle("glowing-moss", 1, 2.0, () => Catacomb());
    addStyle("glowing-moss", 1, 1.0, () => Cavern());

    addStyle("dungeon", 1, 10.0, () => Dungeon());
    // TODO: Forest style that uses cavern-like CA to open an organic-shaped
    // area and then fills it with grass and trees. (Maybe just a specific
    // painter for Cavern?

    // TODO: Different liquid types including some that are dry.
    // TODO: Shore or islands?
    addStyle("water", 1, 1.0, () => Lake(), isAquatic: true);
    addStyle("water", 1, 1.0, () => River(), isAquatic: true);
  }

  final String theme;
  final Architecture Function() _factory;
  final bool isAquatic;

  ArchitecturalStyle(this.theme, this._factory, {bool isAquatic})
      : isAquatic = isAquatic ?? false;

  Architecture create(Architect architect, Region region) {
    var architecture = _factory();
    architecture.bind(this, architect, region);
    return architecture;
  }
}
